import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import '../services/audio_measurement_service.dart';

Color dbColor(double db) {
  if (db < 45) return const Color(0xFF4ADE80);
  if (db < 65) return const Color(0xFFFACC15);
  return const Color(0xFFEF4444);
}

class DbGauge extends StatelessWidget {
  final DbReading? reading;
  final bool isActive;

  const DbGauge({super.key, this.reading, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final db = reading?.db ?? 0;
    final color = dbColor(reading?.db ?? 0);
    final label = reading?.label ?? '—';

    return Column(
      children: [
        SizedBox(
          width: 220, height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background arc
              CustomPaint(
                size: const Size(220, 220),
                painter: _ArcPainter(
                  value: 0,
                  maxValue: 120,
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 18,
                ),
              ),
              // Value arc
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: CustomPaint(
                  key: ValueKey(db.toStringAsFixed(0)),
                  size: const Size(220, 220),
                  painter: _ArcPainter(
                    value: db,
                    maxValue: 120,
                    color: color,
                    strokeWidth: 18,
                  ),
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    child: Text(db.toStringAsFixed(0)),
                  ),
                  Text('dB',
                      style: TextStyle(fontSize: 16,
                          color: color.withOpacity(0.7),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label,
                        style: TextStyle(fontSize: 13, color: color,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              // Pulsing ring when active
              if (isActive)
                _PulseRing(color: color)
                    .animate(onPlay: (c) => c.repeat())
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05),
                        duration: 1000.ms, curve: Curves.easeInOut)
                    .then()
                    .scale(begin: const Offset(1.05, 1.05), end: const Offset(0.9, 0.9),
                        duration: 1000.ms, curve: Curves.easeInOut),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Scale reference
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ScaleItem(label: 'שקט', db: '< 45', color: const Color(0xFF4ADE80)),
            const SizedBox(width: 16),
            _ScaleItem(label: 'רגיל', db: '45–65', color: const Color(0xFFFACC15)),
            const SizedBox(width: 16),
            _ScaleItem(label: 'רועש', db: '> 65', color: const Color(0xFFEF4444)),
          ],
        ),
      ],
    );
  }
}

class _ScaleItem extends StatelessWidget {
  final String label, db;
  final Color color;

  const _ScaleItem({required this.label, required this.db, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          Text(db, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ],
    );
  }
}

class _PulseRing extends StatelessWidget {
  final Color color;

  const _PulseRing({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220, height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value, maxValue, strokeWidth;
  final Color color;

  const _ArcPainter({
    required this.value, required this.maxValue,
    required this.color, required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width - strokeWidth,
      height: size.height - strokeWidth,
    );
    final startAngle = pi * 0.75;
    final sweepAngle = pi * 1.5 * (value / maxValue).clamp(0, 1);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}
