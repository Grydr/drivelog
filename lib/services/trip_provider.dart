import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();
  final Random _random = Random();

  final List<Trip> _recentTrips = [];
  bool _isLoading = false;
  String? _error;
  bool _isTripActive = false;
  double _currentSpeedKmh = 0;
  double _distanceKm = 0;
  double _maxSpeedKmh = 0;
  int _elapsedSeconds = 0;
  int _hardBrakes = 0;
  DateTime? _tripStartedAt;
  Timer? _tripTimer;

  List<Trip> get recentTrips => _recentTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTripActive => _isTripActive;
  double get currentSpeedKmh => _currentSpeedKmh;
  double get distanceKm => _distanceKm;
  double get maxSpeedKmh => _maxSpeedKmh;
  int get elapsedSeconds => _elapsedSeconds;

  String get elapsedLabel {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Stream<List<Trip>> getUserTripsStream(String userId) {
    return _tripService.getUserTrips(userId);
  }

  Stream<List<Trip>> getRecentTripsStream(String userId, {int limit = 10}) {
    return _tripService.getRecentTrips(userId, limit: limit);
  }

  Future<void> startTrip(String userId) async {
    if (_isTripActive) {
      return;
    }

    if (userId.isEmpty) {
      _error = 'You need to be signed in to start a trip.';
      notifyListeners();
      return;
    }

    _error = null;
    _isTripActive = true;
    _tripStartedAt = DateTime.now();
    _currentSpeedKmh = 0;
    _distanceKm = 0;
    _maxSpeedKmh = 0;
    _elapsedSeconds = 0;
    _hardBrakes = 0;
    notifyListeners();

    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _advanceTripState();
      notifyListeners();
    });
  }

  Future<Trip?> stopTrip(String userId) async {
    if (!_isTripActive) {
      return null;
    }

    _tripTimer?.cancel();
    _tripTimer = null;
    _isTripActive = false;

    final trip = Trip(
      id: '',
      userId: userId,
      date: _tripStartedAt ?? DateTime.now(),
      distanceKm: _distanceKm,
      durationMinutes: _elapsedSeconds == 0 ? 0 : (_elapsedSeconds / 60).ceil(),
      maxSpeedKmh: _maxSpeedKmh,
      avgSpeedKmh: _elapsedSeconds == 0 ? 0 : (_distanceKm / (_elapsedSeconds / 3600)),
      hardBrakes: _hardBrakes,
      driveScore: _buildDriveScore(),
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tripId = await _tripService.createTrip(trip);
      _resetTripState();
      _isLoading = false;
      notifyListeners();
      return Trip(
        id: tripId,
        userId: trip.userId,
        date: trip.date,
        distanceKm: trip.distanceKm,
        durationMinutes: trip.durationMinutes,
        maxSpeedKmh: trip.maxSpeedKmh,
        avgSpeedKmh: trip.avgSpeedKmh,
        hardBrakes: trip.hardBrakes,
        driveScore: trip.driveScore,
        createdAt: trip.createdAt,
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void _advanceTripState() {
    if (!_isTripActive) {
      return;
    }

    _elapsedSeconds += 1;

    final delta = (_random.nextDouble() * 18) - 8;
    final previousSpeed = _currentSpeedKmh;
    _currentSpeedKmh = (_currentSpeedKmh + delta).clamp(0, 130).toDouble();

    if (previousSpeed - _currentSpeedKmh >= 18) {
      _hardBrakes += 1;
    }

    _distanceKm += _currentSpeedKmh / 3600;
    if (_currentSpeedKmh > _maxSpeedKmh) {
      _maxSpeedKmh = _currentSpeedKmh;
    }
  }

  String _buildDriveScore() {
    if (_hardBrakes <= 1 && _maxSpeedKmh < 95) {
      return 'A';
    }
    if (_hardBrakes <= 3 && _maxSpeedKmh < 110) {
      return 'B';
    }
    return 'C';
  }

  void _resetTripState() {
    _currentSpeedKmh = 0;
    _distanceKm = 0;
    _maxSpeedKmh = 0;
    _elapsedSeconds = 0;
    _hardBrakes = 0;
    _tripStartedAt = null;
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

  @override
  void dispose() {
    _tripTimer?.cancel();
    super.dispose();
  }
}
