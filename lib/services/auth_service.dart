import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String apartment,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    await cred.user!.updateDisplayName(displayName);

    // Save profile + location to Firestore
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {}

    await _db.collection('users').doc(cred.user!.uid).set({
      'displayName': displayName,
      'email': email,
      'apartment': apartment,
      'lat': pos?.latitude,
      'lng': pos?.longitude,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updateDbReading(String connectionId, double db) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await _db.collection('connections').doc(connectionId).update({
      'lastDbReadings.$uid': db,
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }
}
