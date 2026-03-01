import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

DateTime? _asDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.providerIds,
    this.name,
    this.surname,
    this.institution,
    this.profession,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<String> providerIds;
  final String? name;
  final String? surname;
  final String? institution;
  final String? profession;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  bool get isComplete {
    return name != null &&
        name!.trim().isNotEmpty &&
        surname != null &&
        surname!.trim().isNotEmpty &&
        institution != null &&
        institution!.trim().isNotEmpty &&
        profession != null &&
        profession!.trim().isNotEmpty;
  }

  factory AppUserProfile.fromFirebaseUser(User user) {
    final providers = user.providerData
        .map((entry) => entry.providerId)
        .toSet()
        .toList();

    return AppUserProfile(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providerIds: providers,
      lastLoginAt: DateTime.now(),
    );
  }

  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      providerIds: List<String>.from(map['providerIds'] ?? []),
      name: map['name'] as String?,
      surname: map['surname'] as String?,
      institution: map['institution'] as String?,
      profession: map['profession'] as String?,
      createdAt: _asDateTime(map['createdAt']),
      updatedAt: _asDateTime(map['updatedAt']),
      lastLoginAt: _asDateTime(map['lastLoginAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'providerIds': providerIds,
      'name': name,
      'surname': surname,
      'institution': institution,
      'profession': profession,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  AppUserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? providerIds,
    String? name,
    String? surname,
    String? institution,
    String? profession,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return AppUserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      providerIds: providerIds ?? this.providerIds,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      institution: institution ?? this.institution,
      profession: profession ?? this.profession,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class UserAppSettings {
  const UserAppSettings({
    required this.uid,
    required this.themeMode,
    required this.evalOrder,
    required this.mtsStopAtFirstYes,
    this.updatedAt,
  });

  final String uid;
  final String themeMode;
  final String evalOrder;
  final bool mtsStopAtFirstYes;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'themeMode': themeMode,
      'evalOrder': evalOrder,
      'mtsStopAtFirstYes': mtsStopAtFirstYes,
      'updatedAt': updatedAt,
    };
  }

  factory UserAppSettings.fromMap(Map<String, dynamic> map) {
    return UserAppSettings(
      uid: (map['uid'] as String?) ?? '',
      themeMode: (map['themeMode'] as String?) ?? 'light',
      evalOrder: (map['evalOrder'] as String?) ?? 'sts_then_mts',
      mtsStopAtFirstYes: (map['mtsStopAtFirstYes'] as bool?) ?? false,
      updatedAt: _asDateTime(map['updatedAt']),
    );
  }
}

class PatientSnapshot {
  const PatientSnapshot({
    required this.age,
    required this.gender,
    required this.history,
    required this.arrivalTime,
  });

  final String age;
  final String gender;
  final List<String> history;
  final String arrivalTime;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'age': age,
      'gender': gender,
      'history': history,
      'arrivalTime': arrivalTime,
    };
  }

  factory PatientSnapshot.fromMap(Map<String, dynamic> map) {
    return PatientSnapshot(
      age: (map['age'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? '',
      history: ((map['history'] as List?) ?? <dynamic>[])
          .map((item) => '$item')
          .toList(),
      arrivalTime: (map['arrivalTime'] as String?) ?? '',
    );
  }
}

class TriageCaseRecord {
  const TriageCaseRecord({
    required this.id,
    required this.uid,
    required this.userEmail,
    required this.caseNo,
    required this.schema,
    required this.schemaKey,
    required this.tsb,
    required this.mts,
    required this.tsbMode,
    required this.seconds,
    required this.compatibilityType,
    required this.compatibilityShort,
    required this.compatibilityMessage,
    required this.time,
    required this.discriminator,
    required this.patient,
    required this.tsbResponses,
    required this.mtsPath,
    this.nrsValue,
    this.createdAt,
    this.savedAt,
  });

  final String id;
  final String uid;
  final String? userEmail;
  final int caseNo;
  final String schema;
  final String schemaKey;
  final String tsb;
  final String mts;
  final String? tsbMode;
  final int seconds;
  final String compatibilityType;
  final String compatibilityShort;
  final String compatibilityMessage;
  final String time;
  final String discriminator;
  final PatientSnapshot patient;
  final List<Map<String, dynamic>> tsbResponses;
  final List<Map<String, dynamic>> mtsPath;
  final int? nrsValue;
  final DateTime? createdAt;
  final DateTime? savedAt;

  TriageCaseRecord copyWith({
    String? id,
    String? uid,
    String? userEmail,
    List<Map<String, dynamic>>? tsbResponses,
    List<Map<String, dynamic>>? mtsPath,
    int? nrsValue,
    DateTime? createdAt,
    DateTime? savedAt,
  }) {
    return TriageCaseRecord(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      userEmail: userEmail ?? this.userEmail,
      caseNo: caseNo,
      schema: schema,
      schemaKey: schemaKey,
      tsb: tsb,
      mts: mts,
      tsbMode: tsbMode,
      seconds: seconds,
      compatibilityType: compatibilityType,
      compatibilityShort: compatibilityShort,
      compatibilityMessage: compatibilityMessage,
      time: time,
      discriminator: discriminator,
      patient: patient,
      tsbResponses: tsbResponses ?? this.tsbResponses,
      mtsPath: mtsPath ?? this.mtsPath,
      nrsValue: nrsValue ?? this.nrsValue,
      createdAt: createdAt ?? this.createdAt,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'userEmail': userEmail,
      'caseNo': caseNo,
      'schema': schema,
      'schemaKey': schemaKey,
      'tsb': tsb,
      'mts': mts,
      'tsbMode': tsbMode,
      'seconds': seconds,
      'compatibilityType': compatibilityType,
      'compatibilityShort': compatibilityShort,
      'compatibilityMessage': compatibilityMessage,
      'time': time,
      'discriminator': discriminator,
      'patient': patient.toMap(),
      'tsbResponses': tsbResponses,
      'mtsPath': mtsPath,
      'nrsValue': nrsValue,
      'createdAt': createdAt,
      'savedAt': savedAt,
    };
  }

  factory TriageCaseRecord.fromMap(String id, Map<String, dynamic> map) {
    return TriageCaseRecord(
      id: id,
      uid: (map['uid'] as String?) ?? '',
      userEmail: map['userEmail'] as String?,
      caseNo: (map['caseNo'] as num?)?.toInt() ?? 0,
      schema: (map['schema'] as String?) ?? '',
      schemaKey: (map['schemaKey'] as String?) ?? '',
      tsb: (map['tsb'] as String?) ?? '',
      mts: (map['mts'] as String?) ?? '',
      tsbMode: map['tsbMode'] as String?,
      seconds: (map['seconds'] as num?)?.toInt() ?? 0,
      compatibilityType: (map['compatibilityType'] as String?) ?? '',
      compatibilityShort: (map['compatibilityShort'] as String?) ?? '',
      compatibilityMessage: (map['compatibilityMessage'] as String?) ?? '',
      time: (map['time'] as String?) ?? '',
      discriminator: (map['discriminator'] as String?) ?? '',
      patient: PatientSnapshot.fromMap(
        (map['patient'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      tsbResponses: List<Map<String, dynamic>>.from(
        (map['tsbResponses'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [],
      ),
      mtsPath: List<Map<String, dynamic>>.from(
        (map['mtsPath'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      ),
      nrsValue: map['nrsValue'] as int?,
      createdAt: _asDateTime(map['createdAt']),
      savedAt: _asDateTime(map['savedAt']),
    );
  }
}
