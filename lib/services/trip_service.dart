import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/daily_stats.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new trip
  Future<String> createTrip(Trip trip) async {
    try {
      // Get count of existing trips for this user to calculate trip number
      final snapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: trip.userId)
          .count()
          .get();

      final tripNumber = snapshot.count! + 1;

      // Create a new Trip with the calculated tripNumber
      final tripWithNumber = Trip(
        id: trip.id,
        userId: trip.userId,
        date: trip.date,
        speedKmh: trip.speedKmh,
        avgSpeedKmh: trip.avgSpeedKmh,
        topSpeedKmh: trip.topSpeedKmh,
        distanceKm: trip.distanceKm,
        durationMinutes: trip.durationMinutes,
        tripNumber: tripNumber,
        createdAt: trip.createdAt,
      );

      final docRef = await _firestore.collection('trips').add(tripWithNumber.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating trip: $e');
      rethrow;
    }
  }

  // Get all trips for a user
  Stream<List<Trip>> getUserTrips(String userId) {
    try {
      return _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error getting user trips: $e');
      rethrow;
    }
  }

  // Get recent trips (limited)
  Stream<List<Trip>> getRecentTrips(String userId, {int limit = 10}) {
    try {
      return _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error getting recent trips: $e');
      rethrow;
    }
  }

  // Get a single trip
  Future<Trip?> getTrip(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      if (doc.exists) {
        return Trip.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting trip: $e');
      rethrow;
    }
  }

  // Update a trip
  Future<void> updateTrip(String tripId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('trips').doc(tripId).update(data);
    } catch (e) {
      print('Error updating trip: $e');
      rethrow;
    }
  }

  // Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).delete();
    } catch (e) {
      print('Error deleting trip: $e');
      rethrow;
    }
  }

  // Get statistics for a user
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalDistance': 0.0,
          'totalTrips': 0,
          'totalDuration': 0,
          'averageSpeed': 0.0,
          'topSpeed': 0.0,
        };
      }

      double totalDistance = 0;
      int totalDuration = 0;
      double topSpeed = 0;

      for (var doc in snapshot.docs) {
        final trip = Trip.fromFirestore(doc);
        totalDistance += trip.distanceKm;
        totalDuration += trip.durationMinutes;
        if (trip.topSpeedKmh > topSpeed) {
          topSpeed = trip.topSpeedKmh;
        }
      }

      return {
        'totalDistance': totalDistance,
        'totalTrips': snapshot.docs.length,
        'totalDuration': totalDuration,
        'averageSpeed': totalDuration == 0 ? 0.0 : totalDistance / (totalDuration / 60),
        'topSpeed': topSpeed,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      rethrow;
    }
  }

  // Get 7-day statistics grouped by date
  Future<List<DailyStats>> get7DayStats(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('date', descending: true)
          .get();

      // Group trips by date
      final Map<String, List<Trip>> tripsByDate = {};
      for (var doc in snapshot.docs) {
        final trip = Trip.fromFirestore(doc);
        final dateKey =
            '${trip.date.year}-${trip.date.month.toString().padLeft(2, '0')}-${trip.date.day.toString().padLeft(2, '0')}';
        if (!tripsByDate.containsKey(dateKey)) {
          tripsByDate[dateKey] = [];
        }
        tripsByDate[dateKey]!.add(trip);
      }

      // Generate stats for each day in the 7-day range
      final List<DailyStats> dailyStatsList = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        if (tripsByDate.containsKey(dateKey)) {
          final trips = tripsByDate[dateKey]!;
          double totalDistance = 0;
          int totalDuration = 0;
          double topSpeed = 0;
          double totalAvgSpeed = 0;

          for (final trip in trips) {
            totalDistance += trip.distanceKm;
            totalDuration += trip.durationMinutes;
            totalAvgSpeed += trip.avgSpeedKmh;
            if (trip.topSpeedKmh > topSpeed) {
              topSpeed = trip.topSpeedKmh;
            }
          }

          dailyStatsList.add(
            DailyStats(
              date: date,
              avgSpeed:
                  trips.isEmpty ? 0 : totalAvgSpeed / trips.length,
              topSpeed: topSpeed,
              distance: totalDistance,
              duration: totalDuration,
              tripCount: trips.length,
            ),
          );
        } else {
          dailyStatsList.add(
            DailyStats(
              date: date,
              avgSpeed: 0,
              topSpeed: 0,
              distance: 0,
              duration: 0,
              tripCount: 0,
            ),
          );
        }
      }

      return dailyStatsList;
    } catch (e) {
      print('Error getting 7-day stats: $e');
      rethrow;
    }
  }
}
