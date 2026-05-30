// ═══════════════════════════════════════════════════════
// screens/history_screen.dart
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('היסטוריית מדידות')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('measurements')
            .where('userId', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('אין מדידות עדיין'));
          }

          // Build chart data
          final spots = docs.reversed.toList().asMap().entries.map((e) {
            final data = e.value.data() as Map<String, dynamic>;
            return FlSpot(e.key.toDouble(), (data['db'] as num).toDouble());
          }).toList();

          return Column(
            children: [
              // 24h chart
              SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LineChart(LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  )),
                ),
              ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final ts = (data['timestamp'] as Timestamp?)?.toDate();
                    final db = (data['db'] as num?)?.toDouble() ?? 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: db > 65
                            ? Colors.red.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                        child: Text('${db.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: db > 65 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      title: Text(data['room'] ?? 'לא ידוע'),
                      subtitle: Text(ts?.toString().substring(0, 16) ?? ''),
                      trailing: Text('${db.toStringAsFixed(1)} dB'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════
// screens/settings_screen.dart
// ═══════════════════════════════════════════════════════

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
      body: ListView(
        children: [
          // Profile
          ListTile(
            leading: CircleAvatar(
              child: Text(user?.displayName?[0] ?? '?'),
            ),
            title: Text(user?.displayName ?? 'משתמש'),
            subtitle: Text(user?.email ?? ''),
          ),
          const Divider(),

          // Thresholds
          const ListTile(
            leading: Icon(Icons.warning_outlined),
            title: Text('סף התראת רעש'),
            subtitle: Text('ברירת מחדל: 65 dB'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('התראות push'),
            trailing: Switch(value: true, onChanged: null),
          ),
          const ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('מצב כהה'),
            trailing: Switch(value: false, onChanged: null),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('יציאה', style: TextStyle(color: Colors.red)),
            onTap: () => AuthService().signOut(),
          ),
        ],
      ),
    );
  }
}
