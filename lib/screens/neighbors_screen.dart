import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/neighbor_model.dart';
import 'connect_neighbor_screen.dart';
import 'chat_screen.dart';

class NeighborsScreen extends StatelessWidget {
  const NeighborsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('השכנים שלי'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'הוסף שכן',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ConnectNeighborScreen())),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('connections')
            .where('participants', arrayContains: uid)
            .orderBy('lastActivity', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _EmptyNeighbors(
              onAdd: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ConnectNeighborScreen())),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final connection = NeighborConnection.fromDoc(docs[i]);
              final neighborId = connection.participants
                  .firstWhere((p) => p != uid, orElse: () => '');

              return _NeighborCard(
                connection: connection,
                neighborId: neighborId,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      connectionId: connection.id,
                      neighborId: neighborId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Empty state ────────────────────────────────────────────────────────────

class _EmptyNeighbors extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyNeighbors({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('עדיין אין שכנים מחוברים',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('חבר שכנים שיש לכם קיר, רצפה או תקרה משותפת',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('הוסף שכן ראשון'),
          ),
        ],
      ),
    );
  }
}

// ─── Neighbor card ───────────────────────────────────────────────────────────

class _NeighborCard extends StatelessWidget {
  final NeighborConnection connection;
  final String neighborId;
  final VoidCallback onTap;

  const _NeighborCard({
    required this.connection,
    required this.neighborId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(neighborId)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['displayName'] ?? 'שכן';
        final apartment = data?['apartment'] ?? '';
        final currentDb = connection.lastDbReadings[neighborId] ?? 0.0;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.apartment_outlined,
                                size: 13, color: cs.outline),
                            const SizedBox(width: 4),
                            Text(
                              '${connection.sharedWallLabel} · $apartment',
                              style: TextStyle(fontSize: 12, color: cs.outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Live dB badge
                  _DbBadge(db: currentDb),

                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: cs.outline),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DbBadge extends StatelessWidget {
  final double db;

  const _DbBadge({required this.db});

  Color get _color {
    if (db < 45) return const Color(0xFF4ADE80);
    if (db < 65) return const Color(0xFFFACC15);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        db > 0 ? '${db.toStringAsFixed(0)} dB' : '— dB',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
