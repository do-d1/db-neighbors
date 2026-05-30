import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/audio_measurement_service.dart';

// ══════════════════════════════════════════════════════════════
// BPM Widget — מציג קצב בפעמים לדקה עם אנימציית לב פועם
// ══════════════════════════════════════════════════════════════

class BpmWidget extends StatefulWidget {
  final BpmReading? reading;
  final bool isActive;

  const BpmWidget({super.key, this.reading, required this.isActive});

  @override
  State<BpmWidget> createState() => _BpmWidgetState();
}

class _BpmWidgetState extends State<BpmWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(vsync: this);
    _scheduleHeartbeat();
  }

  void _scheduleHeartbeat() {
    if (!mounted || !widget.isActive) return;
    final bpm = widget.reading?.bpm ?? 72;
    final interval = Duration(milliseconds: (60000 / bpm).round());

    _heartController.forward(from: 0).then((_) {
      if (mounted) {
        Future.delayed(interval, _scheduleHeartbeat);
      }
    });
  }

  @override
  void didUpdateWidget(BpmWidget old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _scheduleHeartbeat();
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bpm = widget.reading?.bpm ?? 0;
    final label = widget.reading?.label ?? '—';
    final cs = Theme.of(context).colorScheme;
    final color = Colors.pink.shade400;

    return Column(
      children: [
        // Heartbeat icon (animated)
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOut))
              .animate(_heartController),
          child: Icon(Icons.favorite_rounded, size: 80, color: color),
        ),
        const SizedBox(height: 24),

        // BPM number
        Text(
          bpm > 0 ? bpm.toStringAsFixed(0) : '—',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text('BPM', style: TextStyle(fontSize: 18, color: color.withOpacity(0.7))),
        const SizedBox(height: 12),

        // Label badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 15, color: color,
                  fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 24),

        // BPM scale
        _BpmScale(current: bpm),

        const SizedBox(height: 16),
        Text(
          'מזהה קצב בסיסי מהסביבה — מוזיקה, צעדים, מכונות',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BpmScale extends StatelessWidget {
  final double current;

  const _BpmScale({required this.current});

  @override
  Widget build(BuildContext context) {
    const zones = [
      (label: 'איטי', min: 40.0, max: 70.0, color: Color(0xFF60A5FA)),
      (label: 'מתון', min: 70.0, max: 100.0, color: Color(0xFF4ADE80)),
      (label: 'בינוני', min: 100.0, max: 140.0, color: Color(0xFFFACC15)),
      (label: 'מהיר', min: 140.0, max: 200.0, color: Color(0xFFEF4444)),
    ];

    return SizedBox(
      height: 32,
      child: Row(
        children: zones.map((zone) {
          final isActive = current >= zone.min && current < zone.max;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? zone.color : zone.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(zone.label,
                  style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.white : zone.color,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Speech Speed Widget — מהירות דיבור
// ══════════════════════════════════════════════════════════════

class SpeechSpeedWidget extends StatelessWidget {
  final SpeechSpeedReading? reading;
  final bool isActive;

  const SpeechSpeedWidget({super.key, this.reading, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final sps = reading?.syllablesPerSecond ?? 0;
    final wpm = reading?.wordsPerMinute ?? 0;
    final label = reading?.label ?? '—';
    final cs = Theme.of(context).colorScheme;
    final color = Colors.teal.shade400;

    // Normalize 0–12 sps to 0–1
    final normalized = (sps / 10).clamp(0.0, 1.0);

    return Column(
      children: [
        // Speed-o-meter visualization
        SizedBox(
          width: 220, height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 130),
                painter: _SpeedArcPainter(
                    value: normalized, color: color),
              ),
              Positioned(
                bottom: 20,
                child: Column(
                  children: [
                    Text(
                      sps > 0 ? sps.toStringAsFixed(1) : '—',
                      style: TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w700, color: color),
                    ),
                    Text('הברות/שנייה',
                        style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // WPM card
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatCard(
              label: 'מילים לדקה',
              value: wpm > 0 ? wpm.toStringAsFixed(0) : '—',
              color: color,
            ),
            const SizedBox(width: 16),
            _StatCard(
              label: 'קצב דיבור',
              value: label,
              color: color,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Language reference
        _SpeechReferenceTable(),

        const SizedBox(height: 12),
        Text(
          'מזהה הברות בדיבור חי — מומלץ לדבר 5 שניות לתוצאה',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SpeechReferenceTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const refs = [
      (lang: 'עברית ממוצעת', wpm: '120–150'),
      (lang: 'אנגלית ממוצעת', wpm: '130–160'),
      (lang: 'מוצג טלוויזיה', wpm: '160–200'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          const Text('עזר השוואה',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...refs.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.lang, style: const TextStyle(fontSize: 11)),
                Text('${r.wpm} wpm',
                    style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w500, color: Colors.teal)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _SpeedArcPainter extends CustomPainter {
  final double value;
  final Color color;

  const _SpeedArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.9;
    final r = size.width * 0.42;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
      3.14159, 3.14159, false, bgPaint,
    );

    // Value arc
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
      3.14159, 3.14159 * value, false, fgPaint,
    );

    // Needle
    final angle = 3.14159 + 3.14159 * value;
    final nx = cx + r * 0.75 * _cos(angle);
    final ny = cy + r * 0.75 * _sin(angle);

    canvas.drawLine(
      Offset(cx, cy), Offset(nx, ny),
      Paint()..color = color..strokeWidth = 3..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = color);
  }

  double _cos(double a) => math.cos(a);
  double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_SpeedArcPainter old) => old.value != value;
}
