/// شاشة رحلاتي السابقة لتطبيق السائق
/// 
/// تعرض سجل جميع رحلات السائق بتصميم موحد مع تبويبات الفلترة والتصفح وتقليل استهلاك القراءات
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/trip_request_model.dart';
import '../services/trip_request_service.dart';
import '../widgets/trip_filter_tabs.dart';
import '../widgets/trip_history_card.dart';
import '../widgets/trips_empty_state.dart';

/// شاشة رحلاتي السابقة
class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final TripRequestService _tripService = TripRequestService.instance;
  final ScrollController _scrollController = ScrollController();

  List<TripRequestModel> _trips = [];
  TripFilter _selectedFilter = TripFilter.all;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  // إحصائيات الأعداد عبر Server-side Count Queries
  int _allCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;

  // متغيرات التصفح (Pagination - 10 رحلات لكل دفعة)
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  static const int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasMore &&
        !_isLoadingMore &&
        !_isLoading &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTrips();
    }
  }

  Future<void> _loadInitialData() async {
    _loadCounts();
    _loadTrips();
  }

  /// جلب أعداد الرحلات باستخدام Firestore Count Queries (بدون قراءة المستندات)
  Future<void> _loadCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final counts = await _tripService.getDriverTripsCounts(user.uid);
    if (mounted) {
      setState(() {
        _allCount = counts['all'] ?? 0;
        _completedCount = counts['completed'] ?? 0;
        _cancelledCount = counts['cancelled'] ?? 0;
      });
    }
  }

  /// جلب وثائق الرحلات من الخادم بحسب التبويب النشط
  Future<List<DocumentSnapshot>> _fetchHistoryDocs({
    DocumentSnapshot? startAfter,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    String? statusFilter;
    if (_selectedFilter == TripFilter.completed) {
      statusFilter = 'completed';
    } else if (_selectedFilter == TripFilter.cancelled) {
      statusFilter = 'cancelled';
    }

    return _tripService.getDriverTripsHistory(
      driverId: user.uid,
      statusFilter: statusFilter,
      limit: _limit,
      startAfter: startAfter,
    );
  }

  /// تحميل أول 10 رحلات للفلتر المحدد
  Future<void> _loadTrips() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _trips = [];
        _lastDocument = null;
        _hasMore = true;
      });

      final docs = await _fetchHistoryDocs();

      if (mounted) {
        setState(() {
          _trips = docs
              .map((doc) => TripRequestModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();
          _lastDocument = docs.isNotEmpty ? docs.last : null;
          _hasMore = docs.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// تحميل الـ 10 رحلات التالية عند التمرير (Pagination)
  Future<void> _loadMoreTrips() async {
    if (_lastDocument == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final docs = await _fetchHistoryDocs(startAfter: _lastDocument);

      if (mounted) {
        setState(() {
          _trips.addAll(docs.map((doc) => TripRequestModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              )));
          _lastDocument = docs.isNotEmpty ? docs.last : null;
          _hasMore = docs.length == _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).loadMoreError}: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.myTrips,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border.withValues(alpha: 0.6),
            height: 1,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return TripsEmptyState(
        onAction: _loadInitialData,
        actionLabel: AppLocalizations.of(context).retry,
      );
    }

    return Column(
      children: [
        TripFilterTabs(
          selectedFilter: _selectedFilter,
          onFilterSelected: (filter) {
            if (_selectedFilter != filter) {
              setState(() => _selectedFilter = filter);
              _loadTrips();
            }
          },
          allCount: _allCount,
          completedCount: _completedCount,
          cancelledCount: _cancelledCount,
        ),
        Expanded(
          child: _trips.isEmpty
              ? TripsEmptyState(
                  filter: _selectedFilter,
                  onAction: _loadInitialData,
                  actionLabel: AppLocalizations.of(context).retry,
                )
              : RefreshIndicator(
                  onRefresh: _loadInitialData,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _trips.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _trips.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      }
                      return TripHistoryCard(
                        trip: _trips[index],
                        isDriver: true,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
