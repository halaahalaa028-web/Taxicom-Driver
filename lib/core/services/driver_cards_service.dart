import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../../features/wallet/data/models/saved_card_model.dart';
import 'stripe_payment_service.dart';

/// خدمة إدارة البطاقات البنكية المحفوظة للسائق (Driver Cards Service)
/// تتعامل مع المسار: users/{driverId}/saved_cards
class DriverCardsService {
  static final DriverCardsService instance = DriverCardsService._();
  DriverCardsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cardsCollection(String driverId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(driverId)
        .collection(AppConstants.savedCardsCollection);
  }

  /// الاستماع الحي لقائمة بطاقات السائق المحفوظة
  Stream<List<SavedCardModel>> watchSavedCards(String driverId) {
    if (driverId.isEmpty) return Stream.value([]);

    return _cardsCollection(driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SavedCardModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// جلب البطاقات المحفوظة دفعة واحدة
  Future<List<SavedCardModel>> getSavedCards(String driverId) async {
    if (driverId.isEmpty) return [];
    try {
      final snap = await _cardsCollection(driverId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((doc) => SavedCardModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ [DriverCardsService] getSavedCards error: $e');
      return [];
    }
  }

  /// إضافة بطاقة بنكية جديدة مع تعيين الافتراضية ذرياً
  Future<bool> addSavedCard({
    required String driverId,
    required SavedCardModel card,
  }) async {
    if (driverId.isEmpty) return false;

    try {
      final col = _cardsCollection(driverId);
      final existingCards = await col.get();
      final isFirstCard = existingCards.docs.isEmpty;
      final shouldBeDefault = card.isDefault || isFirstCard;

      final batch = _firestore.batch();

      if (shouldBeDefault && existingCards.docs.isNotEmpty) {
        for (final doc in existingCards.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }

      final newDoc = card.id.isNotEmpty ? col.doc(card.id) : col.doc();
      final cardWithId = card.copyWith(
        id: newDoc.id,
        userId: driverId,
        isDefault: shouldBeDefault,
      );

      batch.set(newDoc, cardWithId.toMap());
      await batch.commit();

      debugPrint('✅ [DriverCardsService] Card saved: ${card.brand} - ${card.last4} (Default: $shouldBeDefault)');
      return true;
    } catch (e) {
      debugPrint('❌ [DriverCardsService] addSavedCard error: $e');
      return false;
    }
  }

  /// حذف بطاقة وفصلها من Stripe وترقية البطاقة البديلة كافتراضية تلقائياً
  Future<bool> deleteSavedCard({
    required String driverId,
    required String cardId,
  }) async {
    if (driverId.isEmpty || cardId.isEmpty) return false;

    try {
      final col = _cardsCollection(driverId);
      final cardDocRef = col.doc(cardId);
      final cardSnap = await cardDocRef.get();

      if (!cardSnap.exists || cardSnap.data() == null) {
        debugPrint('⚠️ [DriverCardsService] Card not found for deletion: $cardId');
        return false;
      }

      final cardData = cardSnap.data()!;
      final deletedCard = SavedCardModel.fromMap(cardData, cardSnap.id);
      final wasDefault = deletedCard.isDefault;
      final paymentMethodId = deletedCard.paymentMethodId;

      // 1. فصل وسيلة الدفع من حساب العميل في Stripe سحابياً
      if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
        try {
          await StripePaymentService.instance.detachPaymentMethodFromCustomer(
            paymentMethodId: paymentMethodId,
            driverId: driverId,
          );
        } catch (e) {
          debugPrint('⚠️ [DriverCardsService] Error calling detachPaymentMethod: $e');
        }
      }

      // 2. حذف البطاقة من Firestore وترقية أول بطاقة متبقية إن كانت المحذوفة هي الافتراضية
      final batch = _firestore.batch();
      batch.delete(cardDocRef);

      if (wasDefault) {
        final allCardsSnap = await col.get();
        final remainingDocs = allCardsSnap.docs.where((d) => d.id != cardId).toList();
        if (remainingDocs.isNotEmpty) {
          final nextDefaultDoc = remainingDocs.first;
          batch.update(nextDefaultDoc.reference, {'isDefault': true});
          debugPrint('🔄 [DriverCardsService] Promoted next card to default: ${nextDefaultDoc.id}');
        }
      }

      await batch.commit();
      debugPrint('✅ [DriverCardsService] Card deleted and detached from Stripe: $cardId');
      return true;
    } catch (e) {
      debugPrint('❌ [DriverCardsService] deleteSavedCard error: $e');
      return false;
    }
  }

  /// تعيين بطاقة كافتراضية وإلغاء الافتراضية عن بقية البطاقات
  Future<void> setDefaultCard({
    required String driverId,
    required String cardId,
  }) async {
    if (driverId.isEmpty || cardId.isEmpty) return;

    try {
      final col = _cardsCollection(driverId);
      final batch = _firestore.batch();
      final query = await col.get();

      for (final doc in query.docs) {
        batch.update(doc.reference, {'isDefault': doc.id == cardId});
      }
      await batch.commit();
      debugPrint('✅ [DriverCardsService] Default card updated: $cardId');
    } catch (e) {
      debugPrint('❌ [DriverCardsService] setDefaultCard error: $e');
    }
  }
}
