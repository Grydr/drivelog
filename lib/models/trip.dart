import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String userId;
  final DateTime date;
  final double distanceKm;
  final int durationMinutes;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final int hardBrakes;
  final String driveScore; // A, B, C, etc.
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.userId,
    required this.date,
    required this.distanceKm,
    required this.durationMinutes,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.hardBrakes,
    required this.driveScore,
    required this.createdAt,
  });

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: data['durationMinutes'] ?? 0,
      maxSpeedKmh: (data['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      avgSpeedKmh: (data['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      hardBrakes: data['hardBrakes'] ?? 0,
      driveScore: data['driveScore'] ?? 'N/A',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'maxSpeedKmh': maxSpeedKmh,
      'avgSpeedKmh': avgSpeedKmh,
      'hardBrakes': hardBrakes,
      'driveScore': driveScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
