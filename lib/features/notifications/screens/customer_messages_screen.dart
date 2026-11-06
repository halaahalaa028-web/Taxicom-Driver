import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/notification_item_widget.dart';

class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).messagesAndNotifications,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'عام'), // General Tab
            Tab(text: 'شخصي'), // Personal Tab
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CustomerGeneralNotificationsTab(),
          _CustomerPersonalNotificationsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// واجهة تبويب الإشعارات العامة
// ─────────────────────────────────────────────────────────────────
class _CustomerGeneralNotificationsTab extends StatefulWidget {
  const _CustomerGeneralNotificationsTab();

  @override
  State<_CustomerGeneralNotificationsTab> createState() =>
      _CustomerGeneralNotificationsTabState();
}

class _CustomerGeneralNotificationsTabState
    extends State<_CustomerGeneralNotificationsTab> {
  final NotificationService _service = NotificationService.instance;
  final String _customerId = FirebaseAuth.instance.currentUser?.uid ?? '';

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

    if (_notifications.isNotEmpty) {
      final ids = _notifications.map((n) => n.id).toList();
      await _service.markAllAsRead(_customerId, ids);

      if (mounted) {
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            if (!_notifications[i].isReadBy(_customerId)) {
              _notifications[i] = _notifications[i].copyWith(
                readBy: [..._notifications[i].readBy, _customerId],
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

    if (newItems > 0) {
      final newIds = _notifications.skip(before).map((n) => n.id).toList();
      await _service.markAllAsRead(_customerId, newIds);

      if (mounted) {
        setState(() {
          for (int i = before; i < _notifications.length; i++) {
            if (!_notifications[i].isReadBy(_customerId)) {
              _notifications[i] = _notifications[i].copyWith(
                readBy: [..._notifications[i].readBy, _customerId],
              );
            }
          }
        });
      }
    }
  }

  Future<void> _fetchPage() async {
    try {
      final snapshot = await _service.fetchCustomerNotificationsSnapshot(
        _customerId,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final notification = _notifications[index];
        return NotificationItemWidget(
          notification: notification,
          currentUserId: _customerId,
          onTap: () {
            _service.markAsRead(_customerId, notification.id);
            if (!notification.isReadBy(_customerId)) {
              setState(() {
                _notifications[index] = notification.copyWith(
                  readBy: [...notification.readBy, _customerId],
                );
              });
            }
            _showNotificationDetails(context, _notifications[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noMessages,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// واجهة تبويب الإشعارات الشخصية
// ─────────────────────────────────────────────────────────────────
class _CustomerPersonalNotificationsTab extends StatefulWidget {
  const _CustomerPersonalNotificationsTab();

  @override
  State<_CustomerPersonalNotificationsTab> createState() =>
      _CustomerPersonalNotificationsTabState();
}

class _CustomerPersonalNotificationsTabState
    extends State<_CustomerPersonalNotificationsTab> {
  final NotificationService _service = NotificationService.instance;
  final String _customerId = FirebaseAuth.instance.currentUser?.uid ?? '';

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

    if (_notifications.isNotEmpty) {
      final ids = _notifications.map((n) => n.id).toList();
      await _service.markAllAsRead(_customerId, ids);

      if (mounted) {
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            if (!_notifications[i].isReadBy(_customerId)) {
              _notifications[i] = _notifications[i].copyWith(
                readBy: [..._notifications[i].readBy, _customerId],
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

    if (newItems > 0) {
      final newIds = _notifications.skip(before).map((n) => n.id).toList();
      await _service.markAllAsRead(_customerId, newIds);

      if (mounted) {
        setState(() {
          for (int i = before; i < _notifications.length; i++) {
            if (!_notifications[i].isReadBy(_customerId)) {
              _notifications[i] = _notifications[i].copyWith(
                readBy: [..._notifications[i].readBy, _customerId],
              );
            }
          }
        });
      }
    }
  }

  Future<void> _fetchPage() async {
    try {
      final snapshot = await _service.fetchPersonalNotificationsSnapshot(
        _customerId,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final notification = _notifications[index];
        return NotificationItemWidget(
          notification: notification,
          currentUserId: _customerId,
          onTap: () {
            _service.markAsRead(_customerId, notification.id);
            if (!notification.isReadBy(_customerId)) {
              setState(() {
                _notifications[index] = notification.copyWith(
                  readBy: [...notification.readBy, _customerId],
                );
              });
            }
            _showNotificationDetails(context, _notifications[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noMessages,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ── نافذة تفاصيل الإشعار ──────────────────────────────────────

void _showNotificationDetails(
    BuildContext context, NotificationModel notification) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type ?? 'system'),
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        intl.DateFormat('yyyy/MM/dd hh:mm a', 'en')
                            .format(notification.timestamp),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          notification.body,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SafeArea(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).close,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

IconData _getNotificationIcon(String type) {
  switch (type) {
    case 'discount':
      return Icons.local_offer_rounded;
    case 'update':
      return Icons.system_update_rounded;
    case 'driver_approved':
      return Icons.check_circle_rounded;
    case 'driver_rejected':
      return Icons.cancel_rounded;
    case 'subscription_activated':
      return Icons.workspace_premium_rounded;
    case 'subscription_expiry':
      return Icons.warning_rounded;
    case 'system':
    default:
      return Icons.info_rounded;
  }
}
