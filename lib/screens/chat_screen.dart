import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/audio_measurement_service.dart';

class ChatScreen extends StatefulWidget {
  final String connectionId, neighborId;

  const ChatScreen({
    super.key,
    required this.connectionId,
    required this.neighborId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _audio = AudioMeasurementService();
  final _myId = AuthService().currentUser?.uid ?? '';

  static const _quickReplies = [
    '👍 אוקי, אין בעיה',
    '🔇 בבקשה תנמיכו',
    '⏰ עוד כמה זמן?',
    '😴 מנסים לישון',
    '🙏 תודה רבה',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users').doc(widget.neighborId).get(),
          builder: (_, snap) {
            final name = (snap.data?.data() as Map?)?['displayName'] ?? 'שכן';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('connections')
                      .doc(widget.connectionId)
                      .snapshots(),
                  builder: (_, cs) {
                    final data = cs.data?.data() as Map?;
                    final db = (data?['lastDbReadings']
                        as Map?)?[widget.neighborId] ?? 0.0;
                    return Text(
                      '${(db as num).toStringAsFixed(0)} dB כרגע',
                      style: TextStyle(
                        fontSize: 12,
                        color: db > 65
                            ? Colors.red.shade300
                            : Colors.green.shade300,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          // Share my current dB
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'שתף מדידה',
            onPressed: _shareMyDb,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('connections')
                  .doc(widget.connectionId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg = docs[i].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _myId;
                    final isAlert = msg['type'] == 'db_alert';

                    if (isAlert) return _AlertBubble(data: msg);
                    return _MessageBubble(data: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Quick replies
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(_quickReplies[i], style: const TextStyle(fontSize: 12)),
                onPressed: () => _sendMessage(_quickReplies[i]),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Input bar
          Padding(
            padding: EdgeInsets.only(
              left: 12, right: 12, bottom:
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: 'הודעה...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24))),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _send,
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    await FirebaseFirestore.instance
        .collection('connections')
        .doc(widget.connectionId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': _myId,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('connections')
        .doc(widget.connectionId)
        .update({'lastActivity': FieldValue.serverTimestamp()});
  }

  Future<void> _shareMyDb() async {
    final db = _audio.averageDb;
    await FirebaseFirestore.instance
        .collection('connections')
        .doc(widget.connectionId)
        .collection('messages')
        .add({
      'text': 'שיתפתי מדידה: ${db.toStringAsFixed(0)} dB',
      'db': db,
      'senderId': _myId,
      'type': 'db_share',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;

  const _MessageBubble({required this.data, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = data['timestamp'] as Timestamp?;
    final time = ts != null
        ? TimeOfDay.fromDateTime(ts.toDate()).format(context)
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(data['text'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? cs.onPrimary : cs.onSurfaceVariant,
                )),
            const SizedBox(height: 2),
            Text(time,
                style: TextStyle(
                  fontSize: 10,
                  color: (isMe ? cs.onPrimary : cs.onSurfaceVariant)
                      .withOpacity(0.6),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Alert bubble ─────────────────────────────────────────────────────────────

class _AlertBubble extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AlertBubble({required this.data});

  @override
  Widget build(BuildContext context) {
    final db = (data['db'] as num?)?.toDouble() ?? 0;
    final isHigh = db > 75;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHigh
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHigh ? Colors.red.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: isHigh ? Colors.red : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${isHigh ? "התראת רעש" : "רעש גבוה"}: ${db.toStringAsFixed(0)} dB',
            style: TextStyle(
              color: isHigh ? Colors.red.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
