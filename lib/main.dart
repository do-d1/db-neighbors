import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

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
      home: const MainShell(),
    );
  }
}

// ═══════════════════════════════════════════════
// MAIN SHELL
// ═══════════════════════════════════════════════

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          MeasureScreen(),
          FloorPlanScreen(),
          NeighborsScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.graphic_eq_outlined),
              selectedIcon: Icon(Icons.graphic_eq),
              label: 'מדידה'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'מפת דירה'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'שכנים'),
          NavigationDestination(
              icon: Icon(Icons.history),
              label: 'היסטוריה'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// MEASURE SCREEN — dB + BPM + WPM
// ═══════════════════════════════════════════════

class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});
  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen>
    with SingleTickerProviderStateMixin {
  
  // State
  bool _measuring = false;
  int _mode = 0; // 0=dB  1=BPM  2=WPM
  Timer? _timer;
  final _rand = Random();

  // Values
  double _db = 0;
  double _bpm = 0;
  double _wpm = 0;
  double _sps = 0; // syllables per second

  // History for mini chart
  final List<double> _dbHistory = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleMeasure() {
    setState(() => _measuring = !_measuring);
    if (_measuring) {
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
        setState(() {
          _db = (45 + sin(t * 0.7) * 15 + _rand.nextDouble() * 8).clamp(20, 100);
          _bpm = (92 + sin(t * 0.3) * 20 + _rand.nextDouble() * 4).clamp(40, 180);
          _sps = (4.2 + sin(t * 0.5) * 1.5 + _rand.nextDouble() * 0.3).clamp(0, 10);
          _wpm = _sps * 60 / 1.5;
          _dbHistory.add(_db);
          if (_dbHistory.length > 40) _dbHistory.removeAt(0);
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  // Colors
  Color _dbColor(double v) {
    if (v < 45) return const Color(0xFF22C55E);
    if (v < 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _dbLabel(double v) {
    if (v < 30) return 'שקט מאוד';
    if (v < 45) return 'שקט';
    if (v < 60) return 'רגיל';
    if (v < 75) return 'רועש';
    return 'רועש מאוד';
  }

  Color _bpmColor(double v) {
    if (v < 70) return const Color(0xFF60A5FA);
    if (v < 100) return const Color(0xFF22C55E);
    if (v < 140) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _bpmLabel(double v) {
    if (v < 70) return 'איטי';
    if (v < 100) return 'מתון';
    if (v < 140) return 'בינוני';
    return 'מהיר';
  }

  Color _wpmColor(double v) {
    if (v < 100) return const Color(0xFF60A5FA);
    if (v < 150) return const Color(0xFF22C55E);
    if (v < 200) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _wpmLabel(double v) {
    if (v < 100) return 'איטי מאוד';
    if (v < 130) return 'איטי';
    if (v < 160) return 'נורמלי';
    if (v < 200) return 'מהיר';
    return 'מהיר מאוד';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dB Neighbors'),
        centerTitle: false,
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Mode selector
              _ModeSelector(
                selected: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 20),

              // Main gauge
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _mode == 0
                    ? _DbGauge(key: const ValueKey(0), db: _db, measuring: _measuring, color: _dbColor(_db), label: _dbLabel(_db))
                    : _mode == 1
                        ? _BpmGauge(key: const ValueKey(1), bpm: _bpm, measuring: _measuring, color: _bpmColor(_bpm), label: _bpmLabel(_bpm))
                        : _WpmGauge(key: const ValueKey(2), wpm: _wpm, sps: _sps, measuring: _measuring, color: _wpmColor(_wpm), label: _wpmLabel(_wpm)),
              ),

              const SizedBox(height: 24),

              // Record button
              _RecordButton(measuring: _measuring, onTap: _toggleMeasure),

              const SizedBox(height: 24),

              // Mini chart
              if (_measuring && _dbHistory.length > 2)
                _MiniChart(values: _dbHistory, color: _dbColor(_db)),

              const SizedBox(height: 16),

              // Summary cards — always show all 3
              if (_measuring)
                Row(children: [
                  _SummaryCard(
                    label: 'רעש',
                    value: '${_db.toStringAsFixed(0)}',
                    unit: 'dB',
                    color: _dbColor(_db),
                    active: _mode == 0,
                    onTap: () => setState(() => _mode = 0),
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'קצב',
                    value: '${_bpm.toStringAsFixed(0)}',
                    unit: 'BPM',
                    color: _bpmColor(_bpm),
                    active: _mode == 1,
                    onTap: () => setState(() => _mode = 1),
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    label: 'דיבור',
                    value: '${_wpm.toStringAsFixed(0)}',
                    unit: 'WPM',
                    color: _wpmColor(_wpm),
                    active: _mode == 2,
                    onTap: () => setState(() => _mode = 2),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mode Selector ────────────────────────────

class _ModeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _ModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const modes = [
      (icon: Icons.volume_up_outlined, label: 'רמת רעש'),
      (icon: Icons.music_note_outlined, label: 'BPM מוזיקה'),
      (icon: Icons.record_voice_over_outlined, label: 'מהירות דיבור'),
    ];
    return Row(
      children: List.generate(modes.length, (i) {
        final active = selected == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(left: i > 0 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF6366F1).withOpacity(0.15)
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? const Color(0xFF6366F1) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(children: [
                Icon(modes[i].icon,
                    size: 22,
                    color: active
                        ? const Color(0xFF6366F1)
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 4),
                Text(modes[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? const Color(0xFF6366F1)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
              ]),
            ),
          ),
        );
      }),
    );
  }
}

// ─── dB Gauge ────────────────────────────────

class _DbGauge extends StatelessWidget {
  final double db;
  final bool measuring;
  final Color color;
  final String label;
  const _DbGauge({super.key, required this.db, required this.measuring, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: 200, height: 200,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size(200, 200),
              painter: _ArcPainter(value: 0, max: 100, color: Colors.grey.withOpacity(0.15), width: 16)),
          CustomPaint(size: const Size(200, 200),
              painter: _ArcPainter(value: db, max: 100, color: color, width: 16)),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(measuring ? db.toStringAsFixed(0) : '--',
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: color)),
            Text('dB', style: TextStyle(fontSize: 14, color: color.withOpacity(0.7))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(measuring ? label : 'לחץ מדידה',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _ScaleDot(color: const Color(0xFF22C55E), label: 'שקט\n<45'),
        const SizedBox(width: 20),
        _ScaleDot(color: const Color(0xFFF59E0B), label: 'רגיל\n45-65'),
        const SizedBox(width: 20),
        _ScaleDot(color: const Color(0xFFEF4444), label: 'רועש\n>65'),
      ]),
    ]);
  }
}

// ─── BPM Gauge ────────────────────────────────

class _BpmGauge extends StatefulWidget {
  final double bpm;
  final bool measuring;
  final Color color;
  final String label;
  const _BpmGauge({super.key, required this.bpm, required this.measuring, required this.color, required this.label});
  @override
  State<_BpmGauge> createState() => _BpmGaugeState();
}

class _BpmGaugeState extends State<_BpmGauge> with SingleTickerProviderStateMixin {
  late AnimationController _heart;

  @override
  void initState() {
    super.initState();
    _heart = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scheduleBeat();
  }

  void _scheduleBeat() async {
    while (mounted) {
      final interval = widget.bpm > 0
          ? Duration(milliseconds: (60000 / widget.bpm).round())
          : const Duration(seconds: 1);
      await Future.delayed(interval);
      if (!mounted) break;
      _heart.forward(from: 0);
    }
  }

  @override
  void dispose() { _heart.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const zones = [
      (label: 'איטי', min: 40.0, max: 70.0, color: Color(0xFF60A5FA)),
      (label: 'מתון', min: 70.0, max: 100.0, color: Color(0xFF22C55E)),
      (label: 'בינוני', min: 100.0, max: 140.0, color: Color(0xFFF59E0B)),
      (label: 'מהיר', min: 140.0, max: 180.0, color: Color(0xFFEF4444)),
    ];

    return Column(children: [
      ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.25).animate(
            CurvedAnimation(parent: _heart, curve: Curves.easeOut)),
        child: Icon(Icons.favorite_rounded, size: 80, color: widget.color),
      ),
      const SizedBox(height: 16),
      Text(widget.measuring ? widget.bpm.toStringAsFixed(0) : '--',
          style: TextStyle(fontSize: 68, fontWeight: FontWeight.bold, color: widget.color)),
      Text('BPM', style: TextStyle(fontSize: 16, color: widget.color.withOpacity(0.7))),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(widget.measuring ? widget.label : 'לחץ מדידה',
            style: TextStyle(fontSize: 13, color: widget.color, fontWeight: FontWeight.w500)),
      ),
      const SizedBox(height: 20),
      // Zone bar
      Row(children: zones.map((z) {
        final active = widget.bpm >= z.min && widget.bpm < z.max;
        return Expanded(child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? z.color : z.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(z.label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : z.color)),
        ));
      }).toList()),
      const SizedBox(height: 8),
      Text('מזהה קצב מוזיקה, צעדים וסביבה',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    ]);
  }
}

// ─── WPM Gauge ────────────────────────────────

class _WpmGauge extends StatelessWidget {
  final double wpm;
  final double sps;
  final bool measuring;
  final Color color;
  final String label;
  const _WpmGauge({super.key, required this.wpm, required this.sps, required this.measuring, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = (sps / 8.0).clamp(0.0, 1.0);

    return Column(children: [
      // Speedometer arc
      SizedBox(
        width: 220, height: 130,
        child: Stack(alignment: Alignment.bottomCenter, children: [
          CustomPaint(size: const Size(220, 130),
              painter: _SemiArcPainter(value: 0, color: Colors.grey.withOpacity(0.15), width: 14)),
          CustomPaint(size: const Size(220, 130),
              painter: _SemiArcPainter(value: normalized, color: color, width: 14)),
          Positioned(
            bottom: 10,
            child: Column(children: [
              Text(measuring ? sps.toStringAsFixed(1) : '--',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
              Text('הברות/שנייה', style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // WPM row
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _StatBox(label: 'מילים לדקה', value: measuring ? wpm.toStringAsFixed(0) : '--', unit: 'WPM', color: color),
        const SizedBox(width: 12),
        _StatBox(label: 'קצב דיבור', value: measuring ? label : '--', unit: '', color: color),
      ]),
      const SizedBox(height: 16),

      // Reference table
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text('עזר השוואה', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 8),
          for (final r in [
            ('עברית ממוצעת', '120–150 wpm'),
            ('אנגלית ממוצעת', '130–160 wpm'),
            ('מגיש טלוויזיה', '160–200 wpm'),
            ('ראפ מהיר', '250–400 wpm'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(r.$1, style: const TextStyle(fontSize: 11)),
                Text(r.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

// ─── Record Button ────────────────────────────

class _RecordButton extends StatelessWidget {
  final bool measuring;
  final VoidCallback onTap;
  const _RecordButton({required this.measuring, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = measuring ? Colors.red : const Color(0xFF6366F1);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(
          measuring ? Icons.stop_rounded : Icons.mic_rounded,
          size: 34, color: color,
        ),
      ),
    );
  }
}

// ─── Mini Chart ───────────────────────────────

class _MiniChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _MiniChart({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CustomPaint(
        size: const Size(double.infinity, 48),
        painter: _ChartPainter(values: values, color: color),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _ChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final max = values.reduce((a, b) => a > b ? a : b).clamp(1.0, 100.0);
    final paint = Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final fill = Paint()..color = color.withOpacity(0.1)..style = PaintingStyle.fill;
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - (values[i] / max) * size.height;
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); }
      else { path.lineTo(x, y); fillPath.lineTo(x, y); }
    }
    fillPath.lineTo(size.width, size.height); fillPath.close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.values != values;
}

// ─── Summary Card ─────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _SummaryCard({required this.label, required this.value, required this.unit, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(active ? 0.15 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : color.withOpacity(0.2), width: active ? 1.5 : 0.5),
          ),
          child: Column(children: [
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(unit, style: TextStyle(fontSize: 10, color: color.withOpacity(0.6))),
          ]),
        ),
      ),
    );
  }
}

// ─── Stat Box ─────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        if (unit.isNotEmpty)
          Text(unit, style: TextStyle(fontSize: 10, color: color.withOpacity(0.6))),
      ]),
    );
  }
}

// ─── Scale Dot ────────────────────────────────

class _ScaleDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ScaleDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10)),
    ]);
  }
}

// ─── Arc Painters ─────────────────────────────

class _ArcPainter extends CustomPainter {
  final double value, max, width;
  final Color color;
  const _ArcPainter({required this.value, required this.max, required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = (size.width - width) / 2;
    final sweep = pi * 1.5 * (value / max).clamp(0, 1);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
      pi * 0.75, sweep, false,
      Paint()..color = color..strokeWidth = width..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value || old.color != color;
}

class _SemiArcPainter extends CustomPainter {
  final double value, width;
  final Color color;
  const _SemiArcPainter({required this.value, required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height;
    final r = size.width / 2 - width;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
      pi, pi * value.clamp(0, 1), false,
      Paint()..color = color..strokeWidth = width..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SemiArcPainter old) => old.value != value || old.color != color;
}

// ═══════════════════════════════════════════════
// FLOOR PLAN SCREEN
// ═══════════════════════════════════════════════

class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key});
  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  String? _selectedMethod;
  String? _uploadedPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מפת הדירה'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Upload / Scan options
          const Text('בחר שיטת מיפוי',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _MapMethodCard(
                icon: Icons.upload_file_outlined,
                title: 'העלה תשריט',
                subtitle: 'PDF / תמונה\nAI מזהה חדרים',
                color: const Color(0xFF6366F1),
                selected: _selectedMethod == 'upload',
                onTap: () => setState(() => _selectedMethod = 'upload'),
              ),
              _MapMethodCard(
                icon: Icons.camera_alt_outlined,
                title: 'צלם חדרים',
                subtitle: 'AI מזהה רהיטים\nומפה אוטומטית',
                color: const Color(0xFF22C55E),
                selected: _selectedMethod == 'photo',
                onTap: () => setState(() => _selectedMethod = 'photo'),
              ),
              _MapMethodCard(
                icon: Icons.threed_rotation_outlined,
                title: 'LiDAR מובנה',
                subtitle: 'iPhone 12 Pro+\nסריקה תלת-מימד',
                color: const Color(0xFF0EA5E9),
                selected: _selectedMethod == 'lidar_ios',
                onTap: () => setState(() => _selectedMethod = 'lidar_ios'),
              ),
              _MapMethodCard(
                icon: Icons.sensors_outlined,
                title: 'LiDAR חיצוני',
                subtitle: 'USB-C / Bluetooth\nAndroid + iOS',
                color: const Color(0xFFF59E0B),
                selected: _selectedMethod == 'lidar_ext',
                onTap: () => setState(() => _selectedMethod = 'lidar_ext'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Details panel per method
          if (_selectedMethod != null) _MethodDetail(method: _selectedMethod!),

          const SizedBox(height: 20),

          // Demo floor plan
          const Text('תצוגה מקדימה',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const _DemoFloorPlan(),
        ]),
      ),
    );
  }
}

class _MapMethodCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _MapMethodCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 24, color: selected ? color : Colors.grey),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? color : null)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.4)),
        ]),
      ),
    );
  }
}

class _MethodDetail extends StatelessWidget {
  final String method;
  const _MethodDetail({required this.method});

  @override
  Widget build(BuildContext context) {
    final details = {
      'upload': (
        color: const Color(0xFF6366F1),
        icon: Icons.upload_file_outlined,
        title: 'העלאת תשריט',
        body: 'תמכן PDF או צלם את תוכנית הדירה שלך.\nClaude Vision מזהה חדרים, קירות ומידות אוטומטית.',
        action: 'בחר קובץ',
      ),
      'photo': (
        color: const Color(0xFF22C55E),
        icon: Icons.camera_alt_outlined,
        title: 'צילום חדרים',
        body: 'צלם 3-4 תמונות מכל פינה בחדר.\nAI מזהה: ספה, מיטה, שטיח, שולחן\nוממקם אוטומטית על המפה.',
        action: 'פתח מצלמה',
      ),
      'lidar_ios': (
        color: const Color(0xFF0EA5E9),
        icon: Icons.threed_rotation_outlined,
        title: 'LiDAR מובנה — iPhone',
        body: 'זמין ב-iPhone 12 Pro ומעלה.\nסורק את החדר בלייזר — דיוק ±1 ס"מ.\nמפה תלת-מימדית מלאה תוך 30 שניות.',
        action: 'התחל סריקה',
      ),
      'lidar_ext': (
        color: const Color(0xFFF59E0B),
        icon: Icons.sensors_outlined,
        title: 'LiDAR חיצוני',
        body: 'תומך ב:\n• Structure Sensor (USB-C) \$400\n• Intel RealSense D435 (USB-C) \$200\n• Matterport Pro3 (WiFi)\n\nמחובר ל-Android ו-iOS.',
        action: 'חפש התקנים',
      ),
    };

    final d = details[method]!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: d.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: d.color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(d.icon, color: d.color, size: 20),
          const SizedBox(width: 8),
          Text(d.title, style: TextStyle(fontWeight: FontWeight.w600, color: d.color)),
        ]),
        const SizedBox(height: 8),
        Text(d.body, style: const TextStyle(fontSize: 12, height: 1.6)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: d.color),
            child: Text(d.action),
          ),
        ),
      ]),
    );
  }
}

class _DemoFloorPlan extends StatefulWidget {
  const _DemoFloorPlan();
  @override
  State<_DemoFloorPlan> createState() => _DemoFloorPlanState();
}

class _DemoFloorPlanState extends State<_DemoFloorPlan> {
  String? _selected;

  final _rooms = [
    _Room('סלון', 0.04, 0.05, 0.38, 0.55, 42.0),
    _Room('שינה', 0.45, 0.05, 0.30, 0.55, 38.0),
    _Room('ילדים', 0.78, 0.05, 0.20, 0.55, 61.0),
    _Room('מטבח', 0.04, 0.63, 0.30, 0.33, 55.0),
    _Room('שירותים', 0.37, 0.63, 0.20, 0.33, 28.0),
    _Room('כניסה', 0.60, 0.63, 0.38, 0.33, 35.0),
  ];

  Color _roomColor(double db) {
    if (db < 45) return const Color(0xFF22C55E);
    if (db < 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: _rooms.map((r) {
                final color = _roomColor(r.db);
                final sel = _selected == r.name;
                return Positioned(
                  left: r.x * w, top: r.y * h,
                  width: r.w * w, height: r.h * h,
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = sel ? null : r.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(sel ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color, width: sel ? 2 : 1),
                      ),
                      child: Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(r.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                          Text('${r.db.toInt()} dB', style: TextStyle(fontSize: 9, color: color)),
                        ],
                      )),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
      if (_selected != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('$_selected — ${_rooms.firstWhere((r) => r.name == _selected).db.toInt()} dB',
                style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ],
    ]);
  }
}

class _Room {
  final String name;
  final double x, y, w, h, db;
  const _Room(this.name, this.x, this.y, this.w, this.h, this.db);
}

// ═══════════════════════════════════════════════
// NEIGHBORS SCREEN
// ═══════════════════════════════════════════════

class NeighborsScreen extends StatelessWidget {
  const NeighborsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const neighbors = [
      (name: 'משפחת כהן', pos: 'תקרה', db: 61, initials: 'כה'),
      (name: 'אלי לוי', pos: 'קיר ימין', db: 34, initials: 'אל'),
      (name: 'שרה מזרחי', pos: 'רצפה', db: 58, initials: 'שמ'),
    ];

    Color dbColor(int db) {
      if (db < 45) return const Color(0xFF22C55E);
      if (db < 65) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('השכנים שלי'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final n in neighbors)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                  child: Text(n.initials,
                      style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                ),
                title: Text(n.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(n.pos),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: dbColor(n.db).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${n.db} dB',
                      style: TextStyle(color: dbColor(n.db), fontWeight: FontWeight.bold)),
                ),
                onTap: () {},
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('הוסף שכן'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// HISTORY SCREEN
// ═══════════════════════════════════════════════

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = List.generate(10, (i) => (
      time: '${(22 - i).toString().padLeft(2, '0')}:${(i * 7 % 60).toString().padLeft(2, '0')}',
      room: ['סלון', 'חדר שינה', 'מטבח', 'חדר ילדים'][i % 4],
      db: 30 + (i * 7 % 50),
    ));

    Color dbColor(int db) {
      if (db < 45) return const Color(0xFF22C55E);
      if (db < 65) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('היסטוריה'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _HistStat(label: 'ממוצע היום', value: '48 dB', color: const Color(0xFF6366F1)),
            const SizedBox(width: 10),
            _HistStat(label: 'שיא היום', value: '79 dB', color: const Color(0xFFEF4444)),
            const SizedBox(width: 10),
            _HistStat(label: 'שעות שקטות', value: '14 ש\'', color: const Color(0xFF22C55E)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final color = dbColor(e.db);
              return ListTile(
                leading: Text(e.time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                title: Text(e.room),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${e.db} dB',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _HistStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HistStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }
}
