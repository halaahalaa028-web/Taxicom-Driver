/// شاشة المحادثة المؤقتة للرحلة
/// 
/// تتيح التواصل بين السائق والزبون مع دعم الترجمة التلقائية الفورية
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/translation_service.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

/// شاشة المحادثة
class TripChatScreen extends StatefulWidget {
  final String tripId;
  final String otherPartyName;
  final String? otherPartyPhotoUrl;
  final String currentUserName;

  const TripChatScreen({
    super.key,
    required this.tripId,
    required this.otherPartyName,
    this.otherPartyPhotoUrl,
    required this.currentUserName,
  });

  @override
  State<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends State<TripChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _currentUserId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (_currentUserId != null) {
      _chatService.markAsRead(
        tripId: widget.tripId,
        currentUserId: _currentUserId!,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// إرسال رسالة جديدة
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentUserId == null || _isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      await _chatService.sendMessage(
        tripId: widget.tripId,
        senderId: _currentUserId!,
        senderName: widget.currentUserName,
        message: message,
      );
      
      _messageController.clear();
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الرسالة: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherPartyName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'محادثة الرحلة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // زر تبديل الترجمة التلقائية
          ValueListenableBuilder<bool>(
            valueListenable: TranslationService.instance.isAutoTranslateEnabled,
            builder: (context, isEnabled, _) {
              return IconButton(
                tooltip: isEnabled ? 'الترجمة التلقائية مفعلة' : 'الترجمة التلقائية متوقفة',
                icon: Icon(
                  isEnabled ? Icons.g_translate_rounded : Icons.translate_rounded,
                  color: isEnabled ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () {
                  TranslationService.instance.toggleAutoTranslate();
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // قائمة الرسائل
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.watchMessages(widget.tripId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }
                
                if (_currentUserId != null) {
                  _chatService.markAsRead(
                    tripId: widget.tripId,
                    currentUserId: _currentUserId!,
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    return ChatBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),
          
          // شريط إدخال الرسائل
          ChatInputBar(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: widget.otherPartyPhotoUrl != null && widget.otherPartyPhotoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                widget.otherPartyPhotoUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            )
          : const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 24,
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد رسائل بعد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ المحادثة الآن!',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
