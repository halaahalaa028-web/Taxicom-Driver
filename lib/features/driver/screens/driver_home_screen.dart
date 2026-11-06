import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../home/widgets/menu_bottom_sheet.dart';
import '../../chat/screens/trip_chat_screen.dart';
import '../controllers/driver_home_controller.dart';
import '../widgets/driver_top_header.dart';
import '../widgets/driver_address_bar.dart';
import '../widgets/driver_requests_panel.dart';
import '../widgets/driver_active_trip_panel.dart';

/// شاشة السائق الرئيسية
///
/// شاشة خاصة بالسائقين تعرض الخريطة وطلبات الرحلات الواردة والرحلة النشطة
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with WidgetsBindingObserver {
  late final DriverHomeController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DriverHomeController();
    _controller.initialize(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _controller.onAppLifecycleResumed(context);
    }
  }

  void _openChat() {
    final trip = _controller.activeTrip;
    if (trip == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripChatScreen(
          tripId: trip.id,
          otherPartyName: trip.passengerName,
          currentUserName: trip.driverName ?? 'السائق',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final markers = _controller.activeTrip != null
            ? _controller.activeTripMarkers.union(_controller.driverMarker)
            : _controller.passengerMarkers.union(_controller.driverMarker);

        return PopScope(
          canPop: true,
          child: Scaffold(
            drawer: const MenuDrawer(),
            extendBodyBehindAppBar: true,
            appBar: null,
            body: SafeArea(
              child: Stack(
                children: [
                  // الخريطة (كامل الشاشة)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: _controller.setMapController,
                          initialCameraPosition: CameraPosition(
                            target: _controller.currentLocation,
                            zoom: AppConstants.defaultZoom,
                          ),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.30,
                          ),
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          markers: markers,
                          polylines: _controller.activeTripPolylines,
                        ),

                        // مؤشر التحميل الأولي للموقع
                        if (_controller.isLoadingLocation)
                          Container(
                            color: Colors.white.withValues(alpha: 0.7),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                        // شريط العنوان العلوي
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: DriverTopHeader(),
                        ),
                      ],
                    ),
                  ),

                  // شريط موقع السائق ومؤشر الـ GPS
                  Positioned(
                    top: 70,
                    left: 16,
                    right: 16,
                    child: DriverAddressBar(
                      currentAddress: _controller.currentAddress,
                      isLoadingAddress: _controller.isLoadingAddress,
                      locationFailed: _controller.locationFailed,
                      onRecenter: _controller.goToCurrentLocation,
                      onOpenLocationSettings: _controller.openLocationSettings,
                    ),
                  ),

                  // اللوحة السفلية القابلة للسحب
                  DraggableScrollableSheet(
                    initialChildSize: 0.85,
                    minChildSize: 0.4,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: _controller.activeTrip != null
                            ? DriverActiveTripPanel(
                                scrollController: scrollController,
                                trip: _controller.activeTrip!,
                                isPassengerPickedUp: _controller.isPassengerPickedUp,
                                isProcessingTripAction: _controller.isProcessingTripAction,
                                getEstimatedTimeToPassenger: _controller.getEstimatedTimeToPassenger,
                                getDistanceToPassenger: _controller.getDistanceToActiveTarget,
                                onOpenChat: _openChat,
                                onCallPassenger: _controller.callPassenger,
                                onOpenNavigationApp: () => _controller.openNavigationApp(context),
                                onArrivedAtPassenger: () => _controller.arrivedAtPassenger(context),
                                onPassengerBoarded: () => _controller.passengerBoarded(context),
                                onCompleteTrip: () => _controller.completeTrip(context),
                                onCancelTrip: () => _controller.cancelTripByDriver(context),
                              )
                            : DriverRequestsPanel(
                                scrollController: scrollController,
                                isStatusInitialized: _controller.isStatusInitialized,
                                isAvailable: _controller.isAvailable,
                                isTogglingAvailability: _controller.isTogglingAvailability,
                                todayTrips: _controller.todayTrips,
                                todayEarnings: _controller.todayEarnings,
                                incomingRequests: _controller.incomingRequests,
                                onRefresh: () async {
                                  if (!context.mounted) return;
                                  await _controller.loadTodayStats(context);
                                  if (!context.mounted) return;
                                  await _controller.checkForActiveTrip(context);
                                },
                                onToggleAvailability: () => _controller.toggleAvailability(context),
                                getDistanceToPassenger: _controller.getDistanceToPassenger,
                                getEstimatedTimeToPassenger: _controller.getEstimatedTimeToPassenger,
                                onDismissRequest: _controller.dismissRequest,
                                onAcceptRequest: (req) => _controller.acceptRequest(context, req),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
