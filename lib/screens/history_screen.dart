import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/auth_provider.dart';
import '../services/trip_provider.dart';
import '../models/trip.dart';
import '../widgets/trip_card.dart';
import 'trip_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _historyUserId;
  Stream<List<Trip>>? _historyTripsStream;

  void _syncHistoryTripsStream(String userId, TripProvider tripProvider) {
    if (_historyUserId == userId) {
      return;
    }

    _historyUserId = userId;
    _historyTripsStream = userId.isEmpty
        ? null
        : tripProvider.getUserTripsStream(userId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = context.read<AuthProvider>();
    final tripProvider = context.read<TripProvider>();
    final userId = authProvider.currentUser?.uid ?? '';
    _syncHistoryTripsStream(userId, tripProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: StreamBuilder<List<Trip>>(
        stream: _historyTripsStream,
        builder: (context, snapshot) {
          if (userId.isEmpty) {
            return const Center(
              child: Text(
                'Please log in to view your history',
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
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return const Center(
              child: Text(
                'No trips yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            itemCount: trips.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return TripCard(
                tripNumber: trip.tripNumber,
                subtitle:
                    '${trip.date.month}/${trip.date.day} · ${trip.distanceKm.toStringAsFixed(1)} km · ${trip.durationMinutes} min',
                averageSpeed: 'Avg ${trip.avgSpeedKmh.toStringAsFixed(0)} km/h',
                topSpeed: trip.topSpeedKmh,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripDetailScreen(tripId: trip.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
