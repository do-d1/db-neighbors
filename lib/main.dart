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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  double _db = 0;
  bool _measuring = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dB Neighbors'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _MeasureTab(db: _db, measuring: _measuring, onToggle: _toggleMeasure),
          const _NeighborsTab(),
          const _HistoryTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'מדידה'),
          NavigationDestination(icon: Icon(Icons.people), label: 'שכנים'),
          NavigationDestination(icon: Icon(Icons.history), label: 'היסטוריה'),
        ],
      ),
    );
  }

  void _toggleMeasure() {
    setState(() {
      _measuring = !_measuring;
      if (_measuring) {
        Future.periodic(const Duration(milliseconds: 200), (t) {
          if (!_measuring) return;
          setState(() {
            _db = 30 + (t % 40) * 1.0 + (t % 7) * 2.0;
          });
        });
      }
    });
  }
}

class _MeasureTab extends StatelessWidget {
  final double db;
  final bool measuring;
  final VoidCallback onToggle;
  const _MeasureTab({required this.db, required this.measuring, required this.onToggle});

  Color get _color {
    if (db < 45) return Colors.green;
    if (db < 65) return Colors.amber;
    return Colors.red;
  }

  String get _label {
    if (db < 45) return 'שקט';
    if (db < 65) return 'רגיל';
    return 'רועש';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${db.toStringAsFixed(0)} dB',
            style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: _color),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_label, style: TextStyle(color: _color, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: measuring ? Colors.red.withOpacity(0.15) : Colors.indigo.withOpacity(0.15),
                border: Border.all(color: measuring ? Colors.red : Colors.indigo, width: 2),
              ),
              child: Icon(
                measuring ? Icons.stop : Icons.mic,
                size: 36,
                color: measuring ? Colors.red : Colors.indigo,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(measuring ? 'מודד... לחץ לעצירה' : 'לחץ למדידה',
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _NeighborsTab extends StatelessWidget {
  const _NeighborsTab();

  @override
  Widget build(BuildContext context) {
    final neighbors = [
      {'name': 'משפחת כהן', 'pos': 'תקרה', 'db': 61},
      {'name': 'אלי לוי', 'pos': 'קיר ימין', 'db': 34},
      {'name': 'שרה מזרחי', 'pos': 'רצפה', 'db': 58},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: neighbors.map((n) {
        final db = n['db'] as int;
        final color = db < 45 ? Colors.green : (db < 65 ? Colors.amber : Colors.red);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withOpacity(0.15),
              child: Text((n['name'] as String)[0],
                  style: const TextStyle(color: Colors.indigo)),
            ),
            title: Text(n['name'] as String),
            subtitle: Text(n['pos'] as String),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$db dB',
                  style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('היסטוריית מדידות', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}
