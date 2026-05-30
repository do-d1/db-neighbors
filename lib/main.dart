import 'package:flutter/material.dart';

void main() => runApp(const DbNeighborsApp());

class DbNeighborsApp extends StatelessWidget {
  const DbNeighborsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dB Neighbors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      home: const MeasureScreen(),
    );
  }
}

class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});
  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  double _db = 0;
  bool _measuring = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _measuring = false;
    super.dispose();
  }

  void _toggleMeasure() {
    setState(() => _measuring = !_measuring);
    if (_measuring) _simulateMeasure();
  }

  void _simulateMeasure() async {
    while (_measuring && mounted) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) break;
      setState(() {
        _db = 25 + (DateTime.now().millisecond % 55).toDouble() +
            (DateTime.now().second % 20).toDouble();
      });
    }
  }

  Color get _dbColor {
    if (_db < 45) return const Color(0xFF22C55E);
    if (_db < 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _dbLabel {
    if (_db < 45) return 'שקט';
    if (_db < 65) return 'רגיל';
    return 'רועש';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dB Neighbors'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _tab,
        children: [_buildMeasure(), _buildNeighbors(), _buildHistory()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'מדידה'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'שכנים'),
          NavigationDestination(icon: Icon(Icons.history), label: 'היסטוריה'),
        ],
      ),
    );
  }

  Widget _buildMeasure() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (_measuring)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    width: 160 + _pulse.value * 20,
                    height: 160 + _pulse.value * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dbColor.withOpacity(0.15 * (1 - _pulse.value)),
                    ),
                  ),
                ),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _dbColor.withOpacity(0.1),
                  border: Border.all(color: _dbColor, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _measuring ? _db.toStringAsFixed(0) : '--',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: _dbColor,
                      ),
                    ),
                    Text('dB',
                        style: TextStyle(
                            fontSize: 16,
                            color: _dbColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _dbColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_measuring ? _dbLabel : 'לחץ למדידה',
                style: TextStyle(color: _dbColor, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: _toggleMeasure,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_measuring ? Colors.red : const Color(0xFF6366F1)).withOpacity(0.12),
                border: Border.all(
                  color: _measuring ? Colors.red : const Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              child: Icon(
                _measuring ? Icons.stop_rounded : Icons.mic_rounded,
                size: 32,
                color: _measuring ? Colors.red : const Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_measuring) _buildMiniCards(),
        ],
      ),
    );
  }

  Widget _buildMiniCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MiniCard(label: 'BPM', value: '${72 + (_db / 5).round()}', color: Colors.pink),
        const SizedBox(width: 12),
        _MiniCard(label: 'דיבור', value: '4.2 hps', color: Colors.teal),
      ],
    );
  }

  Widget _buildNeighbors() {
    final neighbors = [
      _Neighbor('משפחת כהן', 'תקרה', 61),
      _Neighbor('אלי לוי', 'קיר ימין', 34),
      _Neighbor('שרה מזרחי', 'רצפה מתחת', 58),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final n in neighbors)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                child: Text(n.name[0],
                    style: const TextStyle(
                        color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
              ),
              title: Text(n.name),
              subtitle: Text(n.pos),
              trailing: _DbBadge(n.db),
              onTap: () {},
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('הוסף שכן'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 72, color: Color(0xFF6366F1)),
          SizedBox(height: 16),
          Text('היסטוריית מדידות', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('תיעוד רמות רעש לאורך זמן',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _Neighbor {
  final String name, pos;
  final int db;
  const _Neighbor(this.name, this.pos, this.db);
}

class _DbBadge extends StatelessWidget {
  final int db;
  const _DbBadge(this.db);

  Color get color {
    if (db < 45) return const Color(0xFF22C55E);
    if (db < 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$db dB',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
