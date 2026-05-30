import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/audio_measurement_service.dart';
import '../widgets/db_gauge.dart';
import '../widgets/bpm_widget.dart';
import '../widgets/speech_speed_widget.dart';
import '../widgets/room_selector.dart';

class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> {
  final _audio = AudioMeasurementService();
  bool _isRecording = false;
  DbReading? _lastDb;
  BpmReading? _lastBpm;
  SpeechSpeedReading? _lastSpeech;
  String _selectedRoom = 'סלון';
  String _activeMeasurement = 'db'; // 'db' | 'bpm' | 'speech'

  StreamSubscription? _dbSub, _bpmSub, _speechSub;

  @override
  void initState() {
    super.initState();
    _dbSub = _audio.dbStream.listen((r) => setState(() => _lastDb = r));
    _bpmSub = _audio.bpmStream.listen((r) => setState(() => _lastBpm = r));
    _speechSub = _audio.speechStream.listen((r) => setState(() => _lastSpeech = r));
  }

  @override
  void dispose() {
    _dbSub?.cancel();
    _bpmSub?.cancel();
    _speechSub?.cancel();
    _audio.stopMeasuring();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _audio.stopMeasuring();
      setState(() => _isRecording = false);
    } else {
      try {
        await _audio.startMeasuring();
        setState(() => _isRecording = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('dB Neighbors', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(_selectedRoom,
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
                ],
              ),
              actions: [
                // Room selector
                TextButton.icon(
                  onPressed: _showRoomSelector,
                  icon: const Icon(Icons.door_front_door_outlined, size: 18),
                  label: const Text('החדר'),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Measurement mode selector ──
                    _ModeSelector(
                      selected: _activeMeasurement,
                      onChanged: (m) => setState(() => _activeMeasurement = m),
                    ),
                    const SizedBox(height: 20),

                    // ── Main measurement display ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildMainWidget(),
                    ),
                    const SizedBox(height: 20),

                    // ── Record button ──
                    _RecordButton(
                      isRecording: _isRecording,
                      onTap: _toggleRecording,
                    ),
                    const SizedBox(height: 24),

                    // ── Mini summary cards (always visible) ──
                    if (_isRecording) _buildSummaryRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainWidget() {
    switch (_activeMeasurement) {
      case 'db':
        return DbGauge(
          key: const ValueKey('db'),
          reading: _lastDb,
          isActive: _isRecording,
        );
      case 'bpm':
        return BpmWidget(
          key: const ValueKey('bpm'),
          reading: _lastBpm,
          isActive: _isRecording,
        );
      case 'speech':
        return SpeechSpeedWidget(
          key: const ValueKey('speech'),
          reading: _lastSpeech,
          isActive: _isRecording,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        if (_activeMeasurement != 'db' && _lastDb != null)
          Expanded(child: _MiniCard(
            label: 'רעש',
            value: '${_lastDb!.db.toStringAsFixed(0)} dB',
            color: Colors.green,
          )),
        if (_activeMeasurement != 'bpm' && _lastBpm != null) ...[
          const SizedBox(width: 8),
          Expanded(child: _MiniCard(
            label: 'קצב',
            value: '${_lastBpm!.bpm.toStringAsFixed(0)} BPM',
            color: Colors.purple,
          )),
        ],
        if (_activeMeasurement != 'speech' && _lastSpeech != null) ...[
          const SizedBox(width: 8),
          Expanded(child: _MiniCard(
            label: 'דיבור',
            value: '${_lastSpeech!.wordsPerMinute.toStringAsFixed(0)} wpm',
            color: Colors.teal,
          )),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showRoomSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) => RoomSelector(
        selected: _selectedRoom,
        onSelect: (room) {
          setState(() => _selectedRoom = room);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Mode selector chips ───────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(id: 'db', label: 'רמת רעש', icon: Icons.volume_up_outlined,
            selected: selected == 'db', onTap: onChanged),
        const SizedBox(width: 8),
        _Chip(id: 'bpm', label: 'BPM', icon: Icons.music_note_outlined,
            selected: selected == 'bpm', onTap: onChanged),
        const SizedBox(width: 8),
        _Chip(id: 'speech', label: 'דיבור', icon: Icons.record_voice_over_outlined,
            selected: selected == 'speech', onTap: onChanged),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String id, label;
  final IconData icon;
  final bool selected;
  final ValueChanged<String> onTap;

  const _Chip({required this.id, required this.label, required this.icon,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20,
                  color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Record button ─────────────────────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const _RecordButton({required this.isRecording, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? cs.errorContainer : cs.primaryContainer,
          border: Border.all(
            color: isRecording ? cs.error : cs.primary,
            width: 2,
          ),
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          size: 36,
          color: isRecording ? cs.error : cs.primary,
        ),
      ),
    );
  }
}

// ─── Mini summary card ─────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final String label, value;
  final Color color;

  const _MiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
