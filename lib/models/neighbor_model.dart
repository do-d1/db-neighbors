// ═══════════════════════════════════════════════════════════
// models/neighbor_model.dart
// ═══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

class NeighborConnection {
  final String id;
  final List<String> participants;
  final String sharedWall;
  final Map<String, double> lastDbReadings;
  final DateTime lastActivity;
  final String status;

  const NeighborConnection({
    required this.id,
    required this.participants,
    required this.sharedWall,
    required this.lastDbReadings,
    required this.lastActivity,
    required this.status,
  });

  String get sharedWallLabel => sharedWall;

  factory NeighborConnection.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawReadings = data['lastDbReadings'] as Map? ?? {};
    final readings = rawReadings.map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()));

    return NeighborConnection(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      sharedWall: data['sharedWall'] ?? '',
      lastDbReadings: readings,
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }
}
