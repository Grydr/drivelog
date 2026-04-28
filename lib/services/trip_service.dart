import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new trip
  Future<String> createTrip(Trip trip) async {
    try {
      final docRef = await _firestore.collection('trips').add(trip.toMap());
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
          'maxSpeed': 0.0,
        };
      }

      double totalDistance = 0;
      int totalDuration = 0;
      double maxSpeed = 0;

      for (var doc in snapshot.docs) {
        final trip = Trip.fromFirestore(doc);
        totalDistance += trip.distanceKm;
        totalDuration += trip.durationMinutes;
        if (trip.maxSpeedKmh > maxSpeed) {
          maxSpeed = trip.maxSpeedKmh;
        }
      }

      return {
        'totalDistance': totalDistance,
        'totalTrips': snapshot.docs.length,
        'totalDuration': totalDuration,
        'averageSpeed': totalDistance / (totalDuration / 60),
        'maxSpeed': maxSpeed,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      rethrow;
    }
  }
}
