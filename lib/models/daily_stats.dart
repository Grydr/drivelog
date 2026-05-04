class DailyStats {
  final DateTime date;
  final double avgSpeed;
  final double topSpeed;
  final double distance;
  final int duration;
  final int tripCount;

  DailyStats({
    required this.date,
    required this.avgSpeed,
    required this.topSpeed,
    required this.distance,
    required this.duration,
    required this.tripCount,
  });
}
