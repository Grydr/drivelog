import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';
import '../services/trip_notification_service.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();
  final TripNotificationService _tripNotificationService =
      TripNotificationService.instance;

  final List<Trip> _recentTrips = [];
  bool _isLoading = false;
  String? _error;
  bool _isTripActive = false;
  double _currentSpeedKmh = 0;
  double _distanceKm = 0;
  double _topSpeedKmh = 0;
  int _elapsedSeconds = 0;
  DateTime? _tripStartedAt;
  Timer? _tripTimer;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  List<Trip> get recentTrips => _recentTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTripActive => _isTripActive;
  double get currentSpeedKmh => _currentSpeedKmh;
  double get distanceKm => _distanceKm;
  double get topSpeedKmh => _topSpeedKmh;
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
    final locationReady = await _ensureLocationReady();
    if (!locationReady) {
      return;
    }

    _isTripActive = true;
    _tripStartedAt = DateTime.now();
    _currentSpeedKmh = 0;
    _distanceKm = 0;
    _topSpeedKmh = 0;
    _elapsedSeconds = 0;
    _lastPosition = null;
    _tripNotificationService.setStopTripHandler(() => stopTrip(userId));
    notifyListeners();

    await _tripNotificationService.showActiveTripNotification(
      currentSpeedKmh: _currentSpeedKmh,
      durationLabel: elapsedLabel,
    );

    _positionSubscription?.cancel();
    final locationSettings = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        activityType: ActivityType.fitness,
      ),
      _ => AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      ),
    };
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          _handlePositionUpdate,
          onError: (Object e) {
            _error = e.toString();
            notifyListeners();
          },
        );

    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds += 1;
      unawaited(
        _tripNotificationService.showActiveTripNotification(
          currentSpeedKmh: _currentSpeedKmh,
          durationLabel: elapsedLabel,
        ),
      );
      notifyListeners();
    });
  }

  Future<Trip?> stopTrip(String userId) async {
    if (!_isTripActive) {
      return null;
    }

    _tripTimer?.cancel();
    _tripTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTripActive = false;
    _tripNotificationService.setStopTripHandler(null);

    final trip = Trip(
      id: '',
      userId: userId,
      date: _tripStartedAt ?? DateTime.now(),
      speedKmh: _currentSpeedKmh,
      avgSpeedKmh: _elapsedSeconds == 0
          ? 0
          : (_distanceKm / (_elapsedSeconds / 3600)),
      topSpeedKmh: _topSpeedKmh,
      distanceKm: _distanceKm,
      durationMinutes: _elapsedSeconds == 0 ? 0 : (_elapsedSeconds / 60).ceil(),
      tripNumber: 0, // Will be calculated by TripService.createTrip()
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tripId = await _tripService.createTrip(trip);
      _resetTripState();
      await _tripNotificationService.cancelActiveTripNotification();
      _isLoading = false;
      notifyListeners();
      return Trip(
        id: tripId,
        userId: trip.userId,
        date: trip.date,
        speedKmh: trip.speedKmh,
        avgSpeedKmh: trip.avgSpeedKmh,
        topSpeedKmh: trip.topSpeedKmh,
        distanceKm: trip.distanceKm,
        durationMinutes: trip.durationMinutes,
        tripNumber: 0, // Placeholder; fetch from Firestore for accurate number
        createdAt: trip.createdAt,
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      await _tripNotificationService.cancelActiveTripNotification();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error =
          'Location services are disabled. Please enable GPS to start a trip.';
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _error = 'Location permission is required to track trips.';
      notifyListeners();
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _error =
          'Location permission is permanently denied. Enable it in system settings.';
      notifyListeners();
      return false;
    }

    return true;
  }

  void _handlePositionUpdate(Position position) {
    if (!_isTripActive) {
      return;
    }

    debugPrint("Speed: ${position.speed}");
    debugPrint("Pos: ${position.toString()}");

    double distanceMeters = 0;
    if (_lastPosition != null) {
      distanceMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distanceMeters.isFinite && distanceMeters > 1) {
        _distanceKm += distanceMeters / 1000;
      }
    }

    const minSpeedMs = 0.28;
    final currentSpeed = position.speed.isFinite && position.speed > minSpeedMs
        ? position.speed * 3.6
        : 0.0;

    _lastPosition = position;
    _currentSpeedKmh = currentSpeed;
    if (_currentSpeedKmh > _topSpeedKmh) {
      _topSpeedKmh = _currentSpeedKmh;
    }

    notifyListeners();
  }

  void _resetTripState() {
    _currentSpeedKmh = 0;
    _distanceKm = 0;
    _topSpeedKmh = 0;
    _elapsedSeconds = 0;
    _tripStartedAt = null;
    _lastPosition = null;
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

  Future<List<dynamic>> get7DayStats(String userId) async {
    try {
      return await _tripService.get7DayStats(userId);
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
    _positionSubscription?.cancel();
    _tripNotificationService.cancelActiveTripNotification();
    super.dispose();
  }
}
