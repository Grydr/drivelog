import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();

  List<Trip> _recentTrips = [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get recentTrips => _recentTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Trip>> getUserTripsStream(String userId) {
    return _tripService.getUserTrips(userId);
  }

  Stream<List<Trip>> getRecentTripsStream(String userId, {int limit = 10}) {
    return _tripService.getRecentTrips(userId, limit: limit);
  }

  Future<void> createTrip(Trip trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.createTrip(trip);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Trip?> getTrip(String tripId) async {
    try {
      return await _tripService.getTrip(tripId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTrip(String tripId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.updateTrip(tripId, data);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTrip(String tripId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.deleteTrip(tripId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      return await _tripService.getUserStats(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
