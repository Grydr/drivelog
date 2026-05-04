import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/trip_provider.dart';
import '../models/trip.dart';
import 'package:intl/intl.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Future<Trip?> _tripFuture;

  @override
  void initState() {
    super.initState();
    _tripFuture = context.read<TripProvider>().getTrip(widget.tripId);
  }

  @override
  void didUpdateWidget(covariant TripDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId != widget.tripId) {
      _tripFuture = context.read<TripProvider>().getTrip(widget.tripId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trip detail',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: FutureBuilder<Trip?>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text(
                'Error loading trip details',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final trip = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Hero card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2460),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE, dd MMM yyyy · hh:mm a').format(trip.date),
                        style: const TextStyle(
                          color: Color(0xFF6688CC),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            trip.distanceKm.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 38,
                              fontWeight: FontWeight.w500,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'km',
                            style: TextStyle(
                              color: Color(0xFF6688CC),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Avg ${trip.avgSpeedKmh.toStringAsFixed(0)} km/h · ${trip.durationMinutes} min',
                        style: const TextStyle(
                          color: Color(0xFF8899CC),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildStatBox(
                      'average speed (km/h)',
                      trip.avgSpeedKmh.toStringAsFixed(0),
                      isAccent: true,
                      accentColor: AppColors.primary,
                    ),
                    _buildStatBox(
                      'top speed (km/h)',
                      trip.topSpeedKmh.toStringAsFixed(0),
                      isAccent: true,
                      accentColor: AppColors.scoreA,
                    ),
                    _buildStatBox(
                      'distance (km)',
                      trip.distanceKm.toStringAsFixed(1),
                    ),
                    _buildStatBox(
                      'duration (min)',
                      '${trip.durationMinutes}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Share button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Share trip
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share functionality coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Share this trip',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value, {
    bool isAccent = false,
    Color accentColor = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: isAccent ? accentColor : AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
