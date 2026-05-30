import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/room_selector.dart';

class ConnectNeighborScreen extends StatefulWidget {
  const ConnectNeighborScreen({super.key});

  @override
  State<ConnectNeighborScreen> createState() => _ConnectNeighborScreenState();
}

class _ConnectNeighborScreenState extends State<ConnectNeighborScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedWall = 'קיר ימין';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('חיבור שכן'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.location_on_outlined), text: 'GPS'),
            Tab(icon: Icon(Icons.location_city_outlined), text: 'כתובת'),
            Tab(icon: Icon(Icons.qr_code_scanner_outlined), text: 'QR'),
            Tab(icon: Icon(Icons.tag_outlined), text: 'קוד'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Wall selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: _WallSelector(
              selected: _selectedWall,
              onChanged: (w) => setState(() => _selectedWall = w),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _GpsConnect(sharedWall: _selectedWall),
                _AddressConnect(sharedWall: _selectedWall),
                _QrConnect(sharedWall: _selectedWall),
                _CodeConnect(sharedWall: _selectedWall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wall/ceiling/floor selector ────────────────────────────────────────────

class _WallSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _WallSelector({required this.selected, required this.onChanged});

  static const options = [
    (label: 'קיר ימין', icon: Icons.border_right_outlined),
    (label: 'קיר שמאל', icon: Icons.border_left_outlined),
    (label: 'קיר קדמי', icon: Icons.border_top_outlined),
    (label: 'קיר אחורי', icon: Icons.border_bottom_outlined),
    (label: 'תקרה / רצפה מעל', icon: Icons.keyboard_arrow_up_outlined),
    (label: 'רצפה / תקרה מתחת', icon: Icons.keyboard_arrow_down_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('מה משותף ביניכם?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((o) {
            final isSelected = selected == o.label;
            return FilterChip(
              avatar: Icon(o.icon, size: 16),
              label: Text(o.label),
              selected: isSelected,
              onSelected: (_) => onChanged(o.label),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── GPS connect ─────────────────────────────────────────────────────────────

class _GpsConnect extends StatefulWidget {
  final String sharedWall;
  const _GpsConnect({required this.sharedWall});

  @override
  State<_GpsConnect> createState() => _GpsConnectState();
}

class _GpsConnectState extends State<_GpsConnect> {
  List<Map<String, dynamic>> _nearby = [];
  bool _loading = false;

  Future<void> _scan() async {
    setState(() => _loading = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) throw Exception('הרשאה נדחתה');

      final pos = await Geolocator.getCurrentPosition();

      // Query Firestore for users within ~50m
      // Note: real-world geoqueries use GeoFlutterFire or geohash
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('location', isNotEqualTo: null)
          .limit(20)
          .get();

      final results = snap.docs.where((doc) {
        final data = doc.data();
        final lat = data['lat'] as double?;
        final lng = data['lng'] as double?;
        if (lat == null || lng == null) return false;
        final dist = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, lat, lng);
        return dist < 100; // 100m radius
      }).map((d) => {'id': d.id, ...d.data()}).toList();

      setState(() {
        _nearby = results;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FilledButton.icon(
            onPressed: _loading ? null : _scan,
            icon: _loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.radar_outlined),
            label: Text(_loading ? 'מחפש...' : 'סרוק שכנים קרובים'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _nearby.isEmpty
                ? Center(
                    child: Text('לחץ סרוק למציאת שכנים ב-100 מ',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline)))
                : ListView.builder(
                    itemCount: _nearby.length,
                    itemBuilder: (context, i) {
                      final u = _nearby[i];
                      return _NearbyUserTile(
                        userId: u['id'],
                        name: u['displayName'] ?? 'שכן',
                        apartment: u['apartment'] ?? '',
                        sharedWall: widget.sharedWall,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── QR connect ──────────────────────────────────────────────────────────────

class _QrConnect extends StatefulWidget {
  final String sharedWall;
  const _QrConnect({required this.sharedWall});

  @override
  State<_QrConnect> createState() => _QrConnectState();
}

class _QrConnectState extends State<_QrConnect> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return _scanned
        ? const Center(child: Text('קוד נסרק!'))
        : MobileScanner(
            onDetect: (capture) async {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue == null) return;
              setState(() => _scanned = true);

              final targetId = barcode!.rawValue!;
              await _createConnection(targetId);
            },
          );
  }

  Future<void> _createConnection(String targetId) async {
    final myId = AuthService().currentUser?.uid;
    if (myId == null) return;

    await FirebaseFirestore.instance.collection('connections').add({
      'participants': [myId, targetId],
      'sharedWall': widget.sharedWall,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'lastDbReadings': {},
      'status': 'pending',
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('בקשת חיבור נשלחה!')));
    }
  }
}

// ─── Code connect ─────────────────────────────────────────────────────────────

class _CodeConnect extends StatefulWidget {
  final String sharedWall;
  const _CodeConnect({required this.sharedWall});

  @override
  State<_CodeConnect> createState() => _CodeConnectState();
}

class _CodeConnectState extends State<_CodeConnect> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.tag_outlined, size: 48),
          const SizedBox(height: 16),
          const Text('הזן קוד בניין', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text('הקוד מחלק מנהל הבית או הוועד',
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 24),
          TextField(
            controller: _codeCtrl,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 8,
                fontWeight: FontWeight.w600),
            maxLength: 6,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'XXXXXX',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _join,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('הצטרף לבניין'),
          ),
        ],
      ),
    );
  }

  Future<void> _join() async {
    if (_codeCtrl.text.length < 4) return;
    setState(() => _loading = true);

    final snap = await FirebaseFirestore.instance
        .collection('buildings')
        .where('code', isEqualTo: _codeCtrl.text.toUpperCase())
        .limit(1)
        .get();

    setState(() => _loading = false);

    if (!mounted) return;
    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('קוד לא נמצא')));
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הצטרפת לבניין!')));
    }
  }
}

// ─── Address connect ──────────────────────────────────────────────────────────

class _AddressConnect extends StatelessWidget {
  final String sharedWall;
  const _AddressConnect({required this.sharedWall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.location_city_outlined, size: 48),
          const SizedBox(height: 16),
          const TextField(
              decoration: InputDecoration(
                  labelText: 'רחוב ומספר',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: TextField(
                decoration: InputDecoration(
                    labelText: 'קומה', border: OutlineInputBorder()))),
            SizedBox(width: 12),
            Expanded(child: TextField(
                decoration: InputDecoration(
                    labelText: 'דירה', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.search),
            label: const Text('חפש דייר'),
          ),
        ],
      ),
    );
  }
}

// ─── Nearby user tile ─────────────────────────────────────────────────────────

class _NearbyUserTile extends StatelessWidget {
  final String userId, name, apartment, sharedWall;

  const _NearbyUserTile({
    required this.userId, required this.name,
    required this.apartment, required this.sharedWall,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(name[0])),
      title: Text(name),
      subtitle: Text(apartment),
      trailing: FilledButton.tonalIcon(
        icon: const Icon(Icons.person_add_outlined, size: 16),
        label: const Text('חבר'),
        onPressed: () => _sendRequest(context),
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context) async {
    final myId = AuthService().currentUser?.uid;
    if (myId == null) return;

    await FirebaseFirestore.instance.collection('connections').add({
      'participants': [myId, userId],
      'sharedWall': sharedWall,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'lastDbReadings': {},
      'status': 'pending',
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('בקשה נשלחה!')));
    }
  }
}
