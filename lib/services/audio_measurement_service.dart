import 'dart:async';
import 'dart:math';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Data classes ────────────────────────────────────────────────────────────

class DbReading {
  final double db;
  final DateTime timestamp;
  const DbReading(this.db, this.timestamp);

  String get label {
    if (db < 30) return 'שקט מאוד';
    if (db < 45) return 'שקט';
    if (db < 60) return 'רגיל';
    if (db < 75) return 'רועש';
    if (db < 90) return 'רועש מאוד';
    return 'מסוכן';
  }

  String get colorHex {
    if (db < 45) return "#4ADE80";
    if (db < 65) return "#FACC15";
    if (db < 80) return const Color(0xFFF97316);
    return "#EF4444";
  }
}

class BpmReading {
  final double bpm;
  final DateTime timestamp;
  const BpmReading(this.bpm, this.timestamp);

  String get label {
    if (bpm < 60) return 'איטי';
    if (bpm < 80) return 'מתון';
    if (bpm < 120) return 'בינוני';
    if (bpm < 160) return 'מהיר';
    return 'מהיר מאוד';
  }
}

class SpeechSpeedReading {
  final double syllablesPerSecond;
  final DateTime timestamp;
  const SpeechSpeedReading(this.syllablesPerSecond, this.timestamp);

  String get label {
    if (syllablesPerSecond < 2.5) return 'איטי מאוד';
    if (syllablesPerSecond < 3.5) return 'איטי';
    if (syllablesPerSecond < 5.0) return 'נורמלי';
    if (syllablesPerSecond < 6.5) return 'מהיר';
    return 'מהיר מאוד';
  }

  double get wordsPerMinute => syllablesPerSecond * 60 / 1.5;
}

// ─── Main service ─────────────────────────────────────────────────────────────

class AudioMeasurementService {
  static final AudioMeasurementService _instance = AudioMeasurementService._();
  factory AudioMeasurementService() => _instance;
  AudioMeasurementService._();

  // Streams
  final _dbController = StreamController<DbReading>.broadcast();
  final _bpmController = StreamController<BpmReading>.broadcast();
  final _speechController = StreamController<SpeechSpeedReading>.broadcast();

  Stream<DbReading> get dbStream => _dbController.stream;
  Stream<BpmReading> get bpmStream => _bpmController.stream;
  Stream<SpeechSpeedReading> get speechStream => _speechController.stream;

  // State
  bool _isRunning = false;
  NoiseMeter? _noiseMeter;
  StreamSubscription? _noiseSub;

  // Buffers for BPM and speech analysis
  final List<double> _amplitudeBuffer = [];
  final List<double> _dbHistory = [];
  DateTime? _lastSyllable;
  int _syllableCount = 0;
  DateTime? _speechWindowStart;
  static const int _fftWindowSize = 1024;

  // ─── Permissions ─────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ─── Start / Stop ─────────────────────────────────────────────────────────

  Future<void> startMeasuring() async {
    if (_isRunning) return;
    final granted = await requestPermissions();
    if (!granted) throw Exception('הרשאת מיקרופון נדחתה');

    _isRunning = true;
    _noiseMeter = NoiseMeter();
    _amplitudeBuffer.clear();
    _dbHistory.clear();

    _noiseSub = _noiseMeter!.noise.listen(
      _onNoiseEvent,
      onError: (e) => _stopOnError(e),
    );
  }

  void stopMeasuring() {
    _isRunning = false;
    _noiseSub?.cancel();
    _noiseSub = null;
    _noiseMeter = null;
    _amplitudeBuffer.clear();
    _syllableCount = 0;
    _speechWindowStart = null;
  }

  // ─── dB processing ────────────────────────────────────────────────────────

  void _onNoiseEvent(NoiseReading event) {
    final db = event.meanDecibel.isFinite ? event.meanDecibel : 0.0;
    final reading = DbReading(db.clamp(0, 120), DateTime.now());
    _dbController.add(reading);
    _dbHistory.add(db);
    if (_dbHistory.length > 200) _dbHistory.removeAt(0);

    // Feed amplitude buffer for BPM analysis
    final amplitude = _dbToAmplitude(db);
    _amplitudeBuffer.add(amplitude);

    // Run BPM analysis every 512 samples
    if (_amplitudeBuffer.length >= _fftWindowSize) {
      _analyzeBpm(List.from(_amplitudeBuffer));
      _amplitudeBuffer.removeRange(0, _fftWindowSize ~/ 2);
    }

    // Speech speed detection
    _detectSpeechEvents(db, amplitude);
  }

  double _dbToAmplitude(double db) {
    return pow(10.0, db / 20.0).toDouble();
  }

  // ─── BPM via autocorrelation ───────────────────────────────────────────────
  // Works for any periodic low-frequency signal (music bass, footsteps, etc.)

  void _analyzeBpm(List<double> samples) {
    final n = samples.length;
    if (n < 64) return;

    // Normalize
    final mean = samples.reduce((a, b) => a + b) / n;
    final centered = samples.map((s) => s - mean).toList();

    // Autocorrelation for lags 20–200 samples
    // At typical 44100/20 = 2205 Hz effective rate → lags 20–200 = 11–90 BPM
    double bestCorr = -1;
    int bestLag = 0;

    for (int lag = 20; lag < min(200, n ~/ 2); lag++) {
      double corr = 0;
      for (int i = 0; i < n - lag; i++) {
        corr += centered[i] * centered[i + lag];
      }
      corr /= (n - lag);
      if (corr > bestCorr) {
        bestCorr = corr;
        bestLag = lag;
      }
    }

    if (bestLag > 0 && bestCorr > 0.1) {
      // Assume ~22050 Hz effective sample rate for noise_meter
      final effectiveSampleRate = 22050.0;
      final secondsPerBeat = bestLag / effectiveSampleRate;
      final bpm = (60.0 / secondsPerBeat).clamp(40.0, 200.0);
      _bpmController.add(BpmReading(bpm, DateTime.now()));
    }
  }

  // ─── Speech speed via syllable onset detection ────────────────────────────
  // Detects amplitude spikes above a dynamic threshold → counts syllables

  static const double _speechThresholdDb = 45.0;
  static const double _syllablePeakDb = 55.0;
  static const Duration _minSyllableGap = Duration(milliseconds: 100);
  static const Duration _speechWindow = Duration(seconds: 5);

  bool _inSpeech = false;
  double _peakInSyllable = 0;

  void _detectSpeechEvents(double db, double amplitude) {
    final now = DateTime.now();

    // Detect speech activity
    if (db > _speechThresholdDb) {
      _inSpeech = true;
      _speechWindowStart ??= now;
      _peakInSyllable = max(_peakInSyllable, db);
    }

    // Syllable peak detection
    if (_inSpeech && db < _peakInSyllable - 5 && _peakInSyllable > _syllablePeakDb) {
      final gap = _lastSyllable != null ? now.difference(_lastSyllable!) : const Duration(seconds: 1);
      if (gap > _minSyllableGap) {
        _syllableCount++;
        _lastSyllable = now;
        _peakInSyllable = 0;
      }
    }

    // Reset after silence
    if (db < _speechThresholdDb) {
      if (_inSpeech) _peakInSyllable = max(0, _peakInSyllable - 1);
      if (db < 35) _inSpeech = false;
    }

    // Emit every 5-second window
    if (_speechWindowStart != null &&
        now.difference(_speechWindowStart!) >= _speechWindow &&
        _syllableCount > 0) {
      final elapsed = now.difference(_speechWindowStart!).inMilliseconds / 1000.0;
      final sps = _syllableCount / elapsed;
      _speechController.add(SpeechSpeedReading(sps.clamp(0, 12), now));
      _syllableCount = 0;
      _speechWindowStart = now;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  double get averageDb {
    if (_dbHistory.isEmpty) return 0;
    return _dbHistory.reduce((a, b) => a + b) / _dbHistory.length;
  }

  double get peakDb {
    if (_dbHistory.isEmpty) return 0;
    return _dbHistory.reduce(max);
  }

  void _stopOnError(dynamic e) {
    stopMeasuring();
  }

  void dispose() {
    stopMeasuring();
    _dbController.close();
    _bpmController.close();
    _speechController.close();
  }
}
