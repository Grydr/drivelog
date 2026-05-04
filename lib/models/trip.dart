import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String userId;
  final DateTime date;
  final double speedKmh;
  final double avgSpeedKmh;
  final double topSpeedKmh;
  final double distanceKm;
  final int durationMinutes;
  final int tripNumber;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.userId,
    required this.date,
    required this.speedKmh,
    required this.avgSpeedKmh,
    required this.topSpeedKmh,
    required this.distanceKm,
    required this.durationMinutes,
    required this.tripNumber,
    required this.createdAt,
  });

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      speedKmh: (data['speedKmh'] as num?)?.toDouble() ?? 0.0,
      avgSpeedKmh: (data['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      topSpeedKmh: (data['topSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: data['durationMinutes'] ?? 0,
      tripNumber: data['tripNumber'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'speedKmh': speedKmh,
      'avgSpeedKmh': avgSpeedKmh,
      'topSpeedKmh': topSpeedKmh,
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'tripNumber': tripNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
