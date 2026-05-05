import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/auth_provider.dart';
import '../services/trip_provider.dart';
import '../models/trip.dart';
import '../widgets/live_card.dart';
import '../widgets/trip_card.dart';
import 'trip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _recentTripsUserId;
  Stream<List<Trip>>? _recentTripsStream;

  Future<void> _handleStartTrip(
    TripProvider tripProvider,
    String userId,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      await tripProvider.startTrip(userId);
      if (tripProvider.error != null) {
        messenger.showSnackBar(SnackBar(content: Text(tripProvider.error!)));
        tripProvider.clearError();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleStopTrip(
    TripProvider tripProvider,
    String userId,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      await tripProvider.stopTrip(userId);
      if (tripProvider.error != null) {
        messenger.showSnackBar(SnackBar(content: Text(tripProvider.error!)));
        tripProvider.clearError();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _syncRecentTripsStream(String userId, TripProvider tripProvider) {
    if (_recentTripsUserId == userId) {
      return;
    }

    _recentTripsUserId = userId;
    _recentTripsStream = userId.isEmpty
        ? null
        : tripProvider.getRecentTripsStream(userId, limit: 5);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = context.read<AuthProvider>();
    final tripProvider = context.read<TripProvider>();
    final userId = authProvider.currentUser?.uid ?? '';
    _syncRecentTripsStream(userId, tripProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();
    final userId = authProvider.currentUser?.uid ?? '';
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'DriveLog',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                authProvider.currentAppUser?.initials ?? 'U',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live tracking card
            LiveCard(
              currentSpeed: tripProvider.currentSpeedKmh,
              distance: tripProvider.distanceKm,
              duration: tripProvider.elapsedSeconds,
              maxSpeed: tripProvider.topSpeedKmh,
            ),
            // Start/Stop toggle button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Padding(
                padding: EdgeInsetsGeometry.all(8.0),
                child: ElevatedButton(
                  onPressed: tripProvider.isTripActive
                      ? () => _handleStopTrip(tripProvider, userId, messenger)
                      : () => _handleStartTrip(tripProvider, userId, messenger),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tripProvider.isTripActive
                        ? AppColors.scoreA
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: Size.fromHeight(49),
                  ),
                  child: Text(
                    tripProvider.isTripActive ? 'Stop trip' : 'Start trip',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Recent trips header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent trips',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to all trips
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Recent trips list
            StreamBuilder<List<Trip>>(
              stream: _recentTripsStream,
              builder: (context, snapshot) {
                if (userId.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Please log in to see your recent trips.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading trips: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final trips = snapshot.data ?? [];

                if (trips.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No trips yet. Start your first trip!',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return Column(
                  children: List.generate(trips.length, (index) {
                    final trip = trips[index];
                    return TripCard(
                      tripNumber: trip.tripNumber,
                      subtitle:
                          '${trip.date.month}/${trip.date.day} · ${trip.distanceKm.toStringAsFixed(1)} km · ${trip.durationMinutes} min',
                      averageSpeed:
                          'Avg ${trip.avgSpeedKmh.toStringAsFixed(0)} km/h',
                      topSpeed: trip.topSpeedKmh,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TripDetailScreen(tripId: trip.id),
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
