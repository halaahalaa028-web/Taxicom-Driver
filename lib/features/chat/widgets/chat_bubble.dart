/// ويدجت فقاعة الرسالة مع دعم الترجمة التلقائية
/// 
/// يعرض الرسالة الأصلية والترجمة التلقائية لسائق التاكسي
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/translation_service.dart';
import '../models/chat_message_model.dart';

/// ويدجت فقاعة الرسالة
class ChatBubble extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  TranslationResult? _translation;
  bool _isLoadingTranslation = false;
  bool _showOriginal = false;

  @override
  void initState() {
    super.initState();
    _checkAndTranslate();
  }

  @override
  void didUpdateWidget(covariant ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.message != widget.message.message) {
      _checkAndTranslate();
    }
  }

  /// فحص وترجمة الرسالة إن كانت من الطرف الآخر (الراكب)
  Future<void> _checkAndTranslate() async {
    if (widget.isMe) return;

    final targetLang = LanguageService.instance.currentLanguage.code;
    setState(() => _isLoadingTranslation = true);

    final result = await TranslationService.instance.translate(
      text: widget.message.message,
      targetLanguage: targetLang,
    );

    if (mounted) {
      setState(() {
        _translation = result;
        _isLoadingTranslation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final hasTranslation = _translation != null && _translation!.isDifferent;
    final isAutoTranslateOn = TranslationService.instance.isAutoTranslateEnabled.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // النص المعروض (المترجم أو الأصلي)
                  Text(
                    (!isMe && isAutoTranslateOn && hasTranslation && !_showOriginal)
                        ? _translation!.translatedText
                        : widget.message.message,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),

                  // شريط الترجمة التلقائية
                  if (!isMe && isAutoTranslateOn && hasTranslation) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _showOriginal = !_showOriginal),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.translate_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showOriginal
                                  ? 'عرض المترجم'
                                  : 'مترجم تلقائياً (${_translation!.detectedSourceLanguage.toUpperCase()}) • عرض الأصلي',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (_isLoadingTranslation && !isMe && isAutoTranslateOn) ...[
                    const SizedBox(height: 4),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textSecondary),
                    ),
                  ],

                  const SizedBox(height: 4),
                  // الوقت وحالة القراءة
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(widget.message.createdAt),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: isMe 
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          widget.message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.success,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
