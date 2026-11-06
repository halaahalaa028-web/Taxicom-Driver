/// تبويب الإشعارات العامة للسائق
///
/// يعرض الإشعارات العامة لجميع السائقين مع دعم التحميل المتدرج (Pagination)
/// وتحديث حالة القراءة وعرض تفاصيل كل إشعار
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'notification_details_sheet.dart';
import 'notification_item_widget.dart';

class GeneralNotificationsTab extends StatefulWidget {
  final String driverId;

  const GeneralNotificationsTab({
    super.key,
    required this.driverId,
  });

  @override
  State<GeneralNotificationsTab> createState() => _GeneralNotificationsTabState();
}

class _GeneralNotificationsTabState extends State<GeneralNotificationsTab> {
  final NotificationService _service = NotificationService.instance;
  final List<NotificationModel> _notifications = [];
  final ScrollController _scrollController = ScrollController();

  DocumentSnapshot? _lastDoc;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _notifications.clear();
      _lastDoc = null;
      _hasMore = true;
    });

    await _fetchPage();

    if (_notifications.isNotEmpty && widget.driverId.isNotEmpty) {
      final ids = _notifications.map((n) => n.id).toList();
      await _service.markAllAsRead(widget.driverId, ids);

      if (mounted) {
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            if (!_notifications[i].isReadBy(widget.driverId)) {
              _notifications[i] = _notifications[i].copyWith(
                readBy: [..._notifications[i].readBy, widget.driverId],
              );
            }
          }
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final before = _notifications.length;
    await _fetchPage();
    final newItems = _notifications.length - before;

    if (newItems > 0 && widget.driverId.isNotEmpty) {
      final newIds = _notifications.skip(before).map((n) => n.id).toList();
      await _service.markAllAsRead(widget.driverId, newIds);

      if (mounted) {
        setState(() {
          for (int i = before; i < _notifications.length; i++) {
            if (!_notifications[i].isReadBy(widget.driverId)) {
              _notifications[i] = _notifications[i].copyWith(
                readBy: [..._notifications[i].readBy, widget.driverId],
              );
            }
          }
        });
      }
    }
  }

  Future<void> _fetchPage() async {
    try {
      final snapshot = await _service.fetchDriverNotificationsSnapshot(
        widget.driverId,
        lastDoc: _lastDoc,
      );

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMore = false;
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
        return;
      }

      final newItems = snapshot.docs
          .map((doc) => NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (mounted) {
        setState(() {
          _lastDoc = snapshot.docs.last;
          _notifications.addAll(newItems);
          _hasMore = snapshot.docs.length == 10;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            );
          }

          final notification = _notifications[index];
          return NotificationItemWidget(
            notification: notification,
            currentUserId: widget.driverId,
            onTap: () {
              if (widget.driverId.isNotEmpty) {
                _service.markAsRead(widget.driverId, notification.id);
                if (!notification.isReadBy(widget.driverId)) {
                  setState(() {
                    _notifications[index] = notification.copyWith(
                      readBy: [...notification.readBy, widget.driverId],
                    );
                  });
                }
              }
              NotificationDetailsSheet.show(
                context,
                _notifications[index],
                widget.driverId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noMessages,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
