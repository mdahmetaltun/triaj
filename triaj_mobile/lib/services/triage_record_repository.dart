import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/firestore_models.dart';

class TriageRecordRepository {
  TriageRecordRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore,
      _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  FirebaseFirestore get _firestoreInstance =>
      _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestoreInstance.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _users.doc(uid);

  CollectionReference<Map<String, dynamic>> _userRecords(String uid) =>
      _userDoc(uid).collection('triage_records');

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) =>
      _userDoc(uid).collection('meta').doc('settings');

  Future<void> upsertUserProfile(AppUserProfile profile) async {
    final payload = <String, dynamic>{
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    await _userDoc(profile.uid).set(payload, SetOptions(merge: true));
  }

  Future<void> saveUserSettings(UserAppSettings settings) async {
    final payload = <String, dynamic>{
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _settingsDoc(settings.uid).set(payload, SetOptions(merge: true));
  }

  Future<UserAppSettings?> fetchUserSettings() async {
    final user = _authInstance.currentUser;
    if (user == null) {
      return null;
    }

    final snapshot = await _settingsDoc(user.uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return UserAppSettings.fromMap(data);
  }

  Future<void> saveCaseRecord(TriageCaseRecord record) async {
    final user = _authInstance.currentUser;
    if (user == null) {
      return;
    }

    final recordRef = record.id.isEmpty
        ? _userRecords(user.uid).doc()
        : _userRecords(user.uid).doc(record.id);

    final prepared = record.copyWith(
      id: recordRef.id,
      uid: user.uid,
      userEmail: user.email,
      createdAt: record.createdAt ?? DateTime.now(),
    );

    final payload = <String, dynamic>{
      ...prepared.toMap(),
      'savedAt': FieldValue.serverTimestamp(),
    };

    final legacyPayload = <String, dynamic>{...payload};

    final batch = _firestoreInstance.batch();
    batch.set(recordRef, payload, SetOptions(merge: true));
    batch.set(
      _firestoreInstance.collection('triage_records').doc(recordRef.id),
      legacyPayload,
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> saveRecord(Map<String, dynamic> data) async {
    final user = _authInstance.currentUser;
    if (user == null) {
      return;
    }

    final record = TriageCaseRecord.fromMap('', <String, dynamic>{
      ...data,
      'uid': user.uid,
      'userEmail': user.email,
    });

    await saveCaseRecord(record);
  }

  Future<List<TriageCaseRecord>> fetchUserRecords() async {
    final user = _authInstance.currentUser;
    if (user == null) {
      return [];
    }

    final snapshot = await _userRecords(
      user.uid,
    ).orderBy('savedAt', descending: true).get();

    return snapshot.docs
        .map((doc) => TriageCaseRecord.fromMap(doc.id, doc.data()))
        .toList();
  }
}
