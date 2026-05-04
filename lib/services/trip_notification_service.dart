import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TripNotificationService {
  TripNotificationService._();

  static final TripNotificationService instance = TripNotificationService._();

  static const int _notificationId = 1001;
  static const String _channelId = 'active_trip_channel';
  static const String _channelName = 'Active trip';
  static const String _channelDescription = 'Shows the current active trip status';
  static const String _stopActionId = 'stop_trip';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void> Function()? _onStopTripRequested;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  void setStopTripHandler(Future<void> Function()? handler) {
    _onStopTripRequested = handler;
  }

  Future<void> showActiveTripNotification({
    required double currentSpeedKmh,
    required String durationLabel,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _stopActionId,
          'Stop trip',
          cancelNotification: false,
          showsUserInterface: true,
        ),
      ],
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      _notificationId,
      'Trip in progress',
      'Speed ${currentSpeedKmh.toStringAsFixed(0)} km/h • Duration $durationLabel',
      notificationDetails,
      payload: 'active_trip',
    );
  }

  Future<void> cancelActiveTripNotification() async {
    await _plugin.cancel(_notificationId);
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    if (response.actionId == _stopActionId) {
      await _onStopTripRequested?.call();
    }
  }
}