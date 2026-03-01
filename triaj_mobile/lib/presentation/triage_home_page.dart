import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/models/firestore_models.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/triage_record_repository.dart';
import 'triage_history_page.dart';
import 'profile_page.dart';
import 'scanner_pages.dart';

class TriageHomePage extends StatefulWidget {
  const TriageHomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<TriageHomePage> createState() => _TriageHomePageState();
}

enum _Scr { ana, hasta, sema, tsb, mts, sonuc, rapor }

enum _DiscType { yesNo, nrs, vital }

enum _EvalOrder { stsThenMts, mtsThenSts }

class _CategoryInfo {
  const _CategoryInfo({
    required this.label,
    required this.bg,
    required this.text,
    required this.bekleme,
    this.sub,
    this.en,
  });

  final String label;
  final Color bg;
  final Color text;
  final String bekleme;
  final String? sub;
  final String? en;
}

class _NumericRule {
  const _NumericRule({
    required this.label,
    required this.min,
    required this.max,
    required this.direction,
    this.threshold,
    this.thresholdLow,
    this.thresholdHigh,
    this.unit,
  });

  final String label;
  final num min;
  final num max;
  final String direction;
  final num? threshold;
  final num? thresholdLow;
  final num? thresholdHigh;
  final String? unit;
}

class _TsbQuestion {
  const _TsbQuestion({
    required this.id,
    required this.stepNo,
    required this.category,
    required this.stepTitle,
    required this.stepSub,
    required this.question,
    required this.description,
    this.tip,
    this.num,
  });

  final String id;
  final int stepNo;
  final String category;
  final String stepTitle;
  final String stepSub;
  final String question;
  final String description;
  final String? tip;
  final _NumericRule? num;
}

class _VitalField {
  const _VitalField({
    required this.key,
    required this.label,
    required this.min,
    required this.max,
    required this.direction,
    this.threshold,
    this.thresholdLow,
    this.thresholdHigh,
    this.note,
  });

  final String key;
  final String label;
  final num min;
  final num max;
  final String direction;
  final num? threshold;
  final num? thresholdLow;
  final num? thresholdHigh;
  final String? note;
}

class _Discriminator {
  const _Discriminator({
    required this.description,
    required this.category,
    required this.type,
    this.note,
    this.threshold,
    this.thresholdLow,
    this.thresholdHigh,
    this.badge,
    this.fields = const <_VitalField>[],
    this.isFinal = false,
  });

  final String description;
  final String category;
  final _DiscType type;
  final String? note;
  final num? threshold;
  final num? thresholdLow;
  final num? thresholdHigh;
  final String? badge;
  final List<_VitalField> fields;
  final bool isFinal;
}

class _Flowchart {
  const _Flowchart({
    required this.group,
    required this.title,
    required this.icon,
    required this.disc,
  });

  final String group;
  final String title;
  final String icon;
  final List<_Discriminator> disc;
}

class _PatientInfo {
  const _PatientInfo({
    this.patientId,
    required this.age,
    required this.gender,
    required this.history,
    required this.time,
  });

  final String? patientId;
  final String age;
  final String gender;
  final Set<String> history;
  final String time;

  _PatientInfo copyWith({
    String? patientId,
    String? age,
    String? gender,
    Set<String>? history,
    String? time,
  }) {
    return _PatientInfo(
      patientId: patientId ?? this.patientId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      history: history ?? this.history,
      time: time ?? this.time,
    );
  }

  static _PatientInfo empty(DateTime now) {
    return _PatientInfo(
      patientId: null,
      age: '',
      gender: '',
      history: <String>{},
      time: _hhmm(now),
    );
  }
}

class _Compat {
  const _Compat({
    required this.type,
    required this.color,
    required this.icon,
    required this.short,
    required this.message,
  });

  final String type;
  final Color color;
  final String icon;
  final String short;
  final String message;
}

class _CaseReport {
  const _CaseReport({
    required this.no,
    required this.patient,
    required this.schema,
    required this.schemaKey,
    required this.tsb,
    required this.mts,
    required this.tsbMode,
    required this.seconds,
    required this.compat,
    required this.time,
    required this.discriminator,
    required this.tsbResponses,
    required this.mtsPath,
    this.nrsValue,
  });

  final int no;
  final _PatientInfo patient;
  final String schema;
  final String schemaKey;
  final String tsb;
  final String mts;
  final String? tsbMode;
  final int seconds;
  final _Compat compat;
  final String time;
  final String discriminator;
  final List<Map<String, dynamic>> tsbResponses;
  final List<Map<String, dynamic>> mtsPath;
  final int? nrsValue;
}

class _TriageHomePageState extends State<TriageHomePage> {
  static const double _maxW = 430;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final TriageRecordRepository _recordRepository = TriageRecordRepository();
  StreamSubscription<User?>? _authSub;

  _Scr _scr = _Scr.ana;
  bool _fade = true;

  List<_CaseReport> _cases = <_CaseReport>[];
  int _caseNo = 1;

  _PatientInfo _patient = _PatientInfo.empty(DateTime.now());

  int _tsbIdx = 0;
  String? _tsbKat;
  String? _tsbMode;
  String _tsbNum = '';

  String? _schemaKey;
  int _mtsIdx = 0;
  Map<String, String> _vals = <String, String>{};
  int _nrs = 5;
  String? _group;
  _EvalOrder _evalOrder = _EvalOrder.stsThenMts;
  bool _mtsStopAtFirstYes = false;
  String? _mtsFirstPositiveCategory;
  String? _mtsFirstPositiveDisc;
  Set<int> _mtsPositiveIndices = <int>{};
  String? _mtsResultCode;
  String? _mtsResultDiscriminator;

  List<Map<String, dynamic>> _tsbResponsesLog = [];
  List<Map<String, dynamic>> _mtsPathLog = [];

  _CaseReport? _active;
  DateTime? _t0;
  User? _authUser;
  bool _authBusy = false;
  String? _authError;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color _pick(Color dark, Color light) => _isDark ? dark : light;

  _Flowchart? get _schema =>
      _schemaKey == null ? null : _flowcharts[_schemaKey!];

  List<_Discriminator> get _dList => _schema?.disc ?? const <_Discriminator>[];

  _Discriminator? get _md {
    if (_mtsIdx < 0 || _mtsIdx >= _dList.length) {
      return null;
    }
    return _dList[_mtsIdx];
  }

  _TsbQuestion get _tq => _tsbQ[_tsbIdx];

  String get _evalOrderLabel => _evalOrder == _EvalOrder.stsThenMts
      ? 'Önce Sağlık Bakanlığı (STS) → sonra MTS'
      : 'Önce MTS → sonra Sağlık Bakanlığı (STS)';

  List<String> get _groups {
    final set = <String>{};
    for (final chart in _flowcharts.values) {
      set.add(chart.group);
    }
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    if (FirebaseBootstrap.isReady) {
      _authUser = _authService.currentUser;
      if (_authUser != null) {
        unawaited(_syncCloudProfileAndSettings(_authUser!));
      }
      _authSub = _authService.authChanges.listen((user) {
        if (!mounted) {
          return;
        }
        setState(() {
          _authUser = user;
          _authError = null;
        });
        if (user != null) {
          unawaited(_syncCloudProfileAndSettings(user));
        }
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _go(_Scr s) async {
    setState(() {
      _fade = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) {
      return;
    }
    setState(() {
      _scr = s;
      _fade = true;
    });
  }

  Future<void> _signInWithGoogle() async {
    if (!FirebaseBootstrap.isReady) {
      setState(() {
        _authError = 'Firebase başlatılamadı. Konfigürasyonu kontrol et.';
      });
      return;
    }

    setState(() {
      _authBusy = true;
      _authError = null;
    });

    try {
      await _authService.signInWithGoogle();
    } on GoogleSignInException catch (e) {
      setState(() {
        _authError = 'Google giriş hatası: ${e.code.name}';
      });
    } on PlatformException catch (e) {
      setState(() {
        _authError = e.message ?? 'Google giriş hatası';
      });
    } catch (e) {
      setState(() {
        _authError = 'Google giriş başarısız: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _authBusy = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (!FirebaseBootstrap.isReady) {
      return;
    }

    setState(() {
      _authBusy = true;
      _authError = null;
    });
    try {
      await _authService.signOut();
    } catch (e) {
      setState(() {
        _authError = 'Çıkış başarısız: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _authBusy = false;
        });
      }
    }
  }

  String _evalOrderCode(_EvalOrder order) {
    return order == _EvalOrder.stsThenMts ? 'sts_then_mts' : 'mts_then_sts';
  }

  Future<void> _syncCloudProfileAndSettings(User user) async {
    try {
      // Fetch existing profile to check completeness.
      AppUserProfile? profile = await _recordRepository.fetchUserProfile();

      if (profile == null) {
        // First login or missing profile record.
        profile = AppUserProfile.fromFirebaseUser(user);
        await _recordRepository.upsertUserProfile(profile);
      }

      // Sync settings.
      final settings = await _recordRepository.fetchUserSettings();
      if (settings != null && mounted) {
        setState(() {
          _evalOrder = settings.evalOrder == 'mts_then_sts'
              ? _EvalOrder.mtsThenSts
              : _EvalOrder.stsThenMts;
          _mtsStopAtFirstYes = settings.mtsStopAtFirstYes;
        });
      } else {
        await _persistUserSettings();
      }

      // Check for completeness and force navigation if needed.
      if (!profile.isComplete && mounted) {
        // Use a post-frame callback to ensure navigation happens smoothly after build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProfilePage(forceCompletion: true),
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authError = 'Profil ve ayarlar yüklenemedi: $e';
      });
    }
  }

  Future<void> _persistUserSettings() async {
    if (!FirebaseBootstrap.isReady || _authUser == null) {
      return;
    }

    try {
      await _recordRepository.saveUserSettings(
        UserAppSettings(
          uid: _authUser!.uid,
          themeMode: widget.themeMode == ThemeMode.dark ? 'dark' : 'light',
          evalOrder: _evalOrderCode(_evalOrder),
          mtsStopAtFirstYes: _mtsStopAtFirstYes,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authError = 'Ayarlar Firebase\'e yazılamadı: $e';
      });
    }
  }

  Future<void> _newCase() async {
    setState(() {
      _patient = _PatientInfo.empty(DateTime.now());
      _schemaKey = null;
      _mtsIdx = 0;
      _vals = <String, String>{};
      _nrs = 5;
      _mtsFirstPositiveCategory = null;
      _mtsFirstPositiveDisc = null;
      _mtsPositiveIndices = <int>{};
      _mtsResultCode = null;
      _mtsResultDiscriminator = null;
      _tsbResponsesLog = [];
      _mtsPathLog = [];
      _tsbIdx = 0;
      _tsbNum = '';
      _tsbKat = null;
      _tsbMode = null;
      _active = null;
      _group = null;
      _t0 = DateTime.now();
    });
    await _go(_Scr.hasta);
  }

  Future<void> _goMts() async {
    setState(() {
      _mtsIdx = 0;
      _vals = <String, String>{};
      _nrs = 5;
      _mtsFirstPositiveCategory = null;
      _mtsFirstPositiveDisc = null;
      _mtsPositiveIndices = <int>{};
      _mtsResultCode = null;
      _mtsResultDiscriminator = null;
      _mtsPathLog = [];
    });
    await _go(_Scr.mts);
  }

  Future<void> _tsbYes() async {
    setState(() {
      _tsbResponsesLog.add({
        'question': _tq.question,
        'answer': 'Evet',
        'category': _tq.category,
      });
      _tsbKat = _tq.category;
      _tsbMode = 'karar';
      _tsbNum = '';
    });
    await _completeTsb();
  }

  Future<void> _tsbNo() async {
    setState(() {
      _tsbResponsesLog.add({
        'question': _tq.question,
        'answer': 'Hayır',
        'category': _tq.category,
      });
      _tsbNum = '';
      if (_tsbIdx + 1 < _tsbQ.length) {
        _tsbIdx += 1;
      } else {
        _tsbKat = 'YE';
        _tsbMode = 'karar';
      }
    });

    if (_tsbKat != null && _tsbIdx + 1 >= _tsbQ.length) {
      await _completeTsb();
    }
  }

  Future<void> _tsbManual(String k) async {
    setState(() {
      _tsbKat = k;
      _tsbMode = 'manuel';
    });
    await _completeTsb();
  }

  Future<void> _completeTsb() async {
    if (_evalOrder == _EvalOrder.stsThenMts) {
      await _goMts();
      return;
    }
    if (_mtsResultCode != null) {
      await _assignCategory(
        _mtsResultCode!,
        discriminator: _mtsResultDiscriminator,
      );
      return;
    }
    await _go(_Scr.mts);
  }

  Future<void> _handleMtsCategory(
    String mtsCode, {
    String? discriminator,
  }) async {
    if (_evalOrder == _EvalOrder.mtsThenSts) {
      setState(() {
        _mtsResultCode = mtsCode;
        _mtsResultDiscriminator = discriminator;
      });
      await _go(_Scr.tsb);
      return;
    }
    await _assignCategory(mtsCode, discriminator: discriminator);
  }

  Future<void> _assignCategory(String mtsCode, {String? discriminator}) async {
    final schema = _schema;
    if (schema == null) {
      return;
    }

    final tsb = _tsbKat ?? 'YE';
    final elapsed = _t0 == null ? 0 : DateTime.now().difference(_t0!).inSeconds;
    final comp = _compatibility(tsb, mtsCode);

    final report = _CaseReport(
      no: _caseNo,
      patient: _patient,
      schema: schema.title,
      schemaKey: _schemaKey ?? '',
      tsb: tsb,
      mts: mtsCode,
      tsbMode: _tsbMode,
      seconds: elapsed,
      compat: comp,
      time: _hhmm(DateTime.now()),
      discriminator:
          discriminator ??
          _mtsFirstPositiveDisc ??
          _md?.description ??
          'Tüm diskriminatörler negatif',
      tsbResponses: List.from(_tsbResponsesLog),
      mtsPath: List.from(_mtsPathLog),
      nrsValue: _nrs,
    );

    setState(() {
      _cases = [..._cases, report];
      _caseNo += 1;
      _active = report;
    });

    unawaited(_persistCaseReport(report));
    await _go(_Scr.sonuc);
  }

  Future<void> _persistCaseReport(_CaseReport report) async {
    if (!FirebaseBootstrap.isReady || _authUser == null) {
      return;
    }

    try {
      final record = TriageCaseRecord(
        id: '',
        uid: _authUser!.uid,
        userEmail: _authUser!.email,
        caseNo: report.no,
        schema: report.schema,
        schemaKey: report.schemaKey,
        tsb: report.tsb,
        mts: report.mts,
        tsbMode: report.tsbMode,
        seconds: report.seconds,
        compatibilityType: report.compat.type,
        compatibilityShort: report.compat.short,
        compatibilityMessage: report.compat.message,
        time: report.time,
        discriminator: report.discriminator,
        patient: PatientSnapshot(
          patientId: _patient.patientId,
          age: _patient.age,
          gender: _patient.gender,
          history: _patient.history.toList(),
          arrivalTime: _patient.time,
        ),
        tsbResponses: report.tsbResponses,
        mtsPath: report.mtsPath,
        nrsValue: report.nrsValue,
        createdAt: DateTime.now(),
      );
      await _recordRepository.saveCaseRecord(record);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authError = 'Triyaj kaydı Firebase\'e yazılamadı: $e';
      });
    }
  }

  void _recordMtsPositive(_Discriminator md) {
    setState(() {
      _mtsFirstPositiveCategory ??= md.category;
      _mtsFirstPositiveDisc ??= md.description;
      _mtsPositiveIndices = {..._mtsPositiveIndices, _mtsIdx};
    });
  }

  Future<void> _advanceMts() async {
    if (_mtsIdx + 1 < _dList.length) {
      setState(() {
        _mtsIdx += 1;
        _vals = <String, String>{};
        _nrs = 5;
      });
      return;
    }

    if (_mtsFirstPositiveCategory != null) {
      await _handleMtsCategory(
        _mtsFirstPositiveCategory!,
        discriminator: _mtsFirstPositiveDisc,
      );
      return;
    }

    await _handleMtsCategory(
      'B',
      discriminator: 'Tüm diskriminatörler negatif',
    );
  }

  Future<void> _mtsYes() async {
    final md = _md;
    if (md == null) {
      return;
    }
    if (_mtsStopAtFirstYes) {
      setState(() {
        _mtsPathLog.add({
          'discriminator': md.description,
          'answer': 'Evet',
          'category': md.category,
        });
      });
      await _handleMtsCategory(md.category, discriminator: md.description);
      return;
    }
    setState(() {
      _mtsPathLog.add({
        'discriminator': md.description,
        'answer': 'Evet',
        'category': md.category,
      });
    });
    _recordMtsPositive(md);
    await _advanceMts();
  }

  Future<void> _mtsNo() async {
    final md = _md;
    if (md != null) {
      setState(() {
        _mtsPathLog.add({'discriminator': md.description, 'answer': 'Hayır'});
      });
    }
    await _advanceMts();
  }

  bool _nrsMatches(_Discriminator d, int value) {
    if (d.thresholdLow != null && d.thresholdHigh != null) {
      return value >= d.thresholdLow! && value <= d.thresholdHigh!;
    }
    if (d.threshold != null) {
      return value >= d.threshold!;
    }
    return false;
  }

  Future<void> _saveNrs() async {
    final md = _md;
    if (md == null) {
      return;
    }

    if (_nrsMatches(md, _nrs)) {
      setState(() {
        _mtsPathLog.add({
          'discriminator': md.description,
          'value': 'NRS $_nrs',
          'answer': 'Evet',
          'category': md.category,
        });
      });
      if (_mtsStopAtFirstYes) {
        await _handleMtsCategory(md.category, discriminator: md.description);
        return;
      }
      _recordMtsPositive(md);
      await _advanceMts();
      return;
    }

    await _mtsNo();
  }

  bool _thresholdCrossed(_NumericRule rule, String? raw) {
    if (raw == null || raw.isEmpty) {
      return false;
    }

    final v = num.tryParse(raw);
    if (v == null) {
      return false;
    }

    if (rule.direction == 'cift') {
      return v < (rule.thresholdLow ?? -1e9) || v > (rule.thresholdHigh ?? 1e9);
    }
    if (rule.direction == 'alt' || rule.direction == 'alt_esik') {
      return v < (rule.threshold ?? -1e9);
    }
    if (rule.direction == 'alt_esik_dahil') {
      return v <= (rule.threshold ?? -1e9);
    }
    if (rule.direction == 'ust') {
      return v >= (rule.threshold ?? 1e9);
    }
    if (rule.direction == 'ust_dahil') {
      return v <= (rule.threshold ?? 1e9);
    }
    return false;
  }

  bool _fieldCrossed(_VitalField field, String? raw) {
    if (raw == null || raw.isEmpty) {
      return false;
    }

    final v = num.tryParse(raw);
    if (v == null) {
      return false;
    }

    if (field.direction == 'cift') {
      return v < (field.thresholdLow ?? -1e9) ||
          v > (field.thresholdHigh ?? 1e9);
    }
    if (field.direction == 'alt' || field.direction == 'alt_esik') {
      return v < (field.threshold ?? -1e9);
    }
    if (field.direction == 'ust') {
      return v >= (field.threshold ?? 1e9);
    }
    if (field.direction == 'ust_dahil') {
      return v <= (field.threshold ?? 1e9);
    }
    return false;
  }

  bool _discCrossed(_Discriminator disc) {
    if (disc.fields.isEmpty) {
      return false;
    }

    return disc.fields.any((field) => _fieldCrossed(field, _vals[field.key]));
  }

  Future<void> _saveVital() async {
    final md = _md;
    if (md == null) {
      return;
    }

    if (_discCrossed(md)) {
      setState(() {
        _mtsPathLog.add({
          'discriminator': md.description,
          'value': _vals.entries.map((e) => '${e.key}: ${e.value}').join(', '),
          'answer': 'Evet',
          'category': md.category,
        });
      });
      if (_mtsStopAtFirstYes) {
        await _handleMtsCategory(md.category, discriminator: md.description);
        return;
      }
      _recordMtsPositive(md);
      await _advanceMts();
      return;
    }

    await _mtsNo();
  }

  _Compat _compatibility(String tsb, String mts) {
    final tsbMapped = _tsbToMts[tsb] ?? 'B';
    final bi = _mtsOrder.indexOf(tsbMapped);
    final mi = _mtsOrder.indexOf(mts);
    final diff = mi - bi;

    final tl = _tsb[tsb]?.label ?? tsb;
    final ml = _mts[mts]?.label ?? mts;

    if (diff == 0) {
      return _Compat(
        type: 'uyumlu',
        color: const Color(0xFF27AE60),
        icon: '✓',
        short: 'Uyumlu',
        message: 'Her iki sistem $tl / $ml ile aynı aciliyet düzeyinde.',
      );
    }

    if (diff > 0) {
      return _Compat(
        type: 'alttriaj',
        color: const Color(0xFFE67E22),
        icon: '⬇',
        short: 'Alt-triaj',
        message:
            'MTS daha az acil (TSB: $tl → MTS: $ml). Klinik değerlendirme esas alınmalı.',
      );
    }

    return _Compat(
      type: 'usttriaj',
      color: const Color(0xFFE74C3C),
      icon: '⬆',
      short: 'Üst-triaj',
      message:
          'MTS daha acil buldu (TSB: $tl → MTS: $ml). Ek risk faktörü olabilir.',
    );
  }

  Color _nrsColor(int v) {
    if (v >= 8) {
      return const Color(0xFFC0392B);
    }
    if (v >= 5) {
      return const Color(0xFFE67E22);
    }
    if (v >= 3) {
      return const Color(0xFFD4AC0D);
    }
    return const Color(0xFF27AE60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _pick(const Color(0xFF1B1330), const Color(0xFFFFF4FB)),
              _pick(const Color(0xFF291A45), const Color(0xFFFFEFD8)),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxW),
              child: Column(
                children: [
                  _buildNav(),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 140),
                      opacity: _fade ? 1 : 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 140),
                        offset: _fade ? Offset.zero : const Offset(0, 0.02),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(13, 14, 13, 50),
                          children: [
                            if (_scr == _Scr.ana) _buildAna(),
                            if (_scr == _Scr.hasta) _buildHasta(),
                            if (_scr == _Scr.sema) _buildSema(),
                            if (_scr == _Scr.tsb) _buildTsb(),
                            if (_scr == _Scr.mts) _buildMts(),
                            if (_scr == _Scr.sonuc) _buildSonuc(),
                            if (_scr == _Scr.rapor) _buildRapor(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _pick(const Color(0x1FFFFFFF), const Color(0xFFFFFBFF)),
        border: Border(
          bottom: BorderSide(
            color: _pick(const Color(0x2BC9B3FF), const Color(0xFFE9D8F8)),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => _go(_Scr.ana),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFFF9F68)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Text('🏥', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRİYAJ KARAR SİSTEMİ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: _pick(
                              const Color(0xFFD4DBE8),
                              const Color(0xFF4A3375),
                            ),
                          ),
                        ),
                        Text(
                          'TSB 25 Kriter · MTS ${_flowcharts.length} Şema',
                          style: TextStyle(
                            fontSize: 7.5,
                            letterSpacing: 0.8,
                            color: _pick(
                              const Color(0xFF9485B2),
                              const Color(0xFF7C6B9F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildAuthControl(),
          IconButton(
            onPressed: widget.onToggleTheme,
            tooltip: widget.themeMode == ThemeMode.dark
                ? 'Açık Temaya Geç'
                : 'Koyu Temaya Geç',
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 18,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TriageHistoryPage()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: _pick(
                const Color(0x0CFFFFFF),
                const Color(0xFFEAF0FC),
              ),
              side: BorderSide(
                color: _pick(const Color(0x12FFFFFF), const Color(0xFFD3DFF3)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '📊 Geçmiş',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _pick(const Color(0xFF718096), const Color(0xFF5D759A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthControl() {
    if (!FirebaseBootstrap.isReady) {
      return Tooltip(
        message: 'Firebase bağlanamadı',
        child: Icon(
          Icons.cloud_off_rounded,
          size: 18,
          color: _pick(const Color(0xFFA38CCF), const Color(0xFFB39CCF)),
        ),
      );
    }

    if (_authUser == null) {
      return TextButton(
        onPressed: _authBusy ? null : _signInWithGoogle,
        style: TextButton.styleFrom(
          backgroundColor: _pick(
            const Color(0x1EFFFFFF),
            const Color(0xFFF2E8FF),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          _authBusy ? '...' : 'Google',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: _pick(const Color(0xFFE5D7FF), const Color(0xFF6B46C1)),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
          child: Tooltip(
            message: 'Profili Düzenle',
            child: CircleAvatar(
              radius: 14,
              backgroundColor: _pick(
                const Color(0x338B5CF6),
                const Color(0x33FF9F68),
              ),
              backgroundImage: _authUser?.photoURL != null
                  ? NetworkImage(_authUser!.photoURL!)
                  : null,
              child: _authUser?.photoURL == null
                  ? Text(
                      ((_authUser?.displayName ?? _authUser?.email ?? 'G')
                              .trim())
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _pick(
                          const Color(0xFFF0E8FF),
                          const Color(0xFF6B46C1),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 6),
        TextButton.icon(
          onPressed: _authBusy ? null : _signOut,
          icon: const Icon(Icons.logout_rounded, size: 14),
          label: const Text('Çıkış'),
          style: TextButton.styleFrom(
            backgroundColor: _pick(
              const Color(0x1EFFFFFF),
              const Color(0xFFFDEDEE),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: _pick(
              const Color(0xFFFFD7DF),
              const Color(0xFFB42318),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAna() {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFFF9F68)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x668B5CF6),
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: const Text('🏥', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Triyaj Karar Destek Sistemi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            'T.C. Sağlık Bakanlığı Algoritması · 25 Ayrı Kriter\n'
            'MTS 3rd Ed. · ${_flowcharts.length} Şema · Vital Bulgu Entegrasyonu',
            style: TextStyle(
              fontSize: 10.5,
              height: 1.7,
              color: _pick(const Color(0xFF4A5568), const Color(0xFF5E7296)),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _pick(const Color(0x1A922B21), const Color(0x22F97316)),
              border: Border.all(
                color: _pick(const Color(0x38922B21), const Color(0x55F97316)),
              ),
            ),
            child: const Text(
              '⚠️ ARAŞTIRMA PROTOTİPİ · Klinik kararlar için hekim değerlendirmesi esastır',
              style: TextStyle(
                fontSize: 8.5,
                color: Color(0xFFE74C3C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!FirebaseBootstrap.isReady) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _pick(const Color(0x24FFB86B), const Color(0x2AFFF0C2)),
                border: Border.all(
                  color: _pick(
                    const Color(0x66FFB86B),
                    const Color(0x88FFC96E),
                  ),
                ),
              ),
              child: Text(
                'Firebase bağlı değil. Google auth ve triaj kayıtları devre dışı.',
                style: TextStyle(
                  fontSize: 9,
                  color: _pick(
                    const Color(0xFFFFD7A6),
                    const Color(0xFF915600),
                  ),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (_authError != null && _authError!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _pick(const Color(0x26EF4444), const Color(0x20F87171)),
                border: Border.all(
                  color: _pick(
                    const Color(0x66EF4444),
                    const Color(0x66F87171),
                  ),
                ),
              ),
              child: Text(
                _authError!,
                style: TextStyle(
                  fontSize: 9,
                  color: _pick(
                    const Color(0xFFFECACA),
                    const Color(0xFF9F1239),
                  ),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_cases.isNotEmpty) _buildSessionStats(),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _newCase,
                  style: _primaryButtonStyle(),
                  child: const Text('＋ Yeni Vaka Başlat'),
                ),
              ),
              if (_cases.isNotEmpty) ...[
                const SizedBox(height: 7),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _go(_Scr.rapor),
                    style: _secondaryButtonStyle(),
                    child: const Text('📊 Vaka Raporları'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStats() {
    final total = _cases.length;
    final mismatch = _cases.where((v) => v.compat.type != 'uyumlu').length;
    final down = _cases.where((v) => v.compat.type == 'alttriaj').length;
    final up = _cases.where((v) => v.compat.type == 'usttriaj').length;

    final items = [
      ('Toplam', total.toString(), const Color(0xFF60A5FA)),
      ('Uyumsuz', mismatch.toString(), const Color(0xFFFBBF24)),
      ('Alt↓', down.toString(), const Color(0xFFF97316)),
      ('Üst↑', up.toString(), const Color(0xFFF87171)),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: _glassBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OTURUM İSTATİSTİKLERİ',
            style: TextStyle(
              fontSize: 7.5,
              letterSpacing: 1.1,
              color: _pick(const Color(0xFF4A5568), const Color(0xFF6A7E9F)),
            ),
          ),
          const SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, i) {
              final item = items[i];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: _pick(
                    const Color(0x0CFFFFFF),
                    const Color(0xFFF8FBFF),
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: item.$3,
                      ),
                    ),
                    Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 7.5,
                        color: _pick(
                          const Color(0xFF4A5568),
                          const Color(0xFF6D819F),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHasta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(1, 'Hasta Bilgileri', null),
        const SizedBox(height: 8),
        _field(
          'TC KİMLİK / DOSYA NO',
          TextField(
            inputFormatters: [LengthLimitingTextInputFormatter(11)],
            decoration: InputDecoration(
              hintText: 'Kimlik veya dosya no girin',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    tooltip: 'Barkod Okut (Dosya No)',
                    onPressed: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarcodeScannerPage(),
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _patient = _patient.copyWith(patientId: result);
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.document_scanner, size: 20),
                    tooltip: 'Kimlik Tara (TC Kimlik No)',
                    onPressed: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TextScannerPage(),
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _patient = _patient.copyWith(patientId: result);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            onChanged: (v) => setState(() {
              _patient = _patient.copyWith(patientId: v);
            }),
            controller: TextEditingController(text: _patient.patientId ?? '')
              ..selection = TextSelection.collapsed(
                offset: (_patient.patientId ?? '').length,
              ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _field(
                'YAŞ',
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'örn. 45'),
                  onChanged: (v) => setState(() {
                    _patient = _patient.copyWith(age: v);
                  }),
                  controller: TextEditingController(text: _patient.age)
                    ..selection = TextSelection.collapsed(
                      offset: _patient.age.length,
                    ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _field(
                'CİNSİYET',
                Row(
                  children: ['E', 'K', '?'].map((c) {
                    final selected = _patient.gender == c;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: c == '?' ? 0 : 3),
                        child: TextButton(
                          onPressed: () => setState(() {
                            _patient = _patient.copyWith(gender: c);
                          }),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(
                                color: selected
                                    ? _pick(
                                        const Color(0x80922B21),
                                        const Color(0x80F97316),
                                      )
                                    : _pick(
                                        const Color(0x12FFFFFF),
                                        const Color(0xFFD7E2F4),
                                      ),
                              ),
                            ),
                            backgroundColor: selected
                                ? _pick(
                                    const Color(0x2E922B21),
                                    const Color(0x22F97316),
                                  )
                                : _pick(
                                    const Color(0x0CFFFFFF),
                                    const Color(0xFFF6FAFF),
                                  ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? const Color(0xFFF87171)
                                  : _pick(
                                      const Color(0xFF718096),
                                      const Color(0xFF5D759A),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _field(
          'KOMORBİDİTE',
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _historyOptions.map((g) {
              final selected = _patient.history.contains(g);
              return TextButton(
                onPressed: () {
                  final copy = Set<String>.from(_patient.history);
                  if (copy.contains(g)) {
                    copy.remove(g);
                  } else {
                    copy.add(g);
                  }
                  setState(() {
                    _patient = _patient.copyWith(history: copy);
                  });
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                      color: selected
                          ? _pick(
                              const Color(0x66922B21),
                              const Color(0x66F97316),
                            )
                          : _pick(
                              const Color(0x10FFFFFF),
                              const Color(0xFFD8E2F3),
                            ),
                    ),
                  ),
                  backgroundColor: selected
                      ? _pick(const Color(0x24922B21), const Color(0x1AF97316))
                      : _pick(const Color(0x0CFFFFFF), const Color(0xFFF7FAFF)),
                ),
                child: Text(
                  g,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFFFCA5A5)
                        : _pick(
                            const Color(0xFF718096),
                            const Color(0xFF5D759A),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 9),
        _field(
          'BAŞVURU SAATİ',
          TextField(
            decoration: const InputDecoration(hintText: 'HH:MM'),
            controller: TextEditingController(text: _patient.time)
              ..selection = TextSelection.collapsed(
                offset: _patient.time.length,
              ),
            onChanged: (v) => setState(() {
              _patient = _patient.copyWith(time: v);
            }),
          ),
        ),
        const SizedBox(height: 9),
        _field(
          'DEĞERLENDİRME SIRASI',
          Container(
            padding: const EdgeInsets.all(10),
            decoration: _glassBox(radius: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _orderChip(
                      label: '1) STS → 2) MTS',
                      selected: _evalOrder == _EvalOrder.stsThenMts,
                      onTap: () {
                        setState(() {
                          _evalOrder = _EvalOrder.stsThenMts;
                        });
                        unawaited(_persistUserSettings());
                      },
                    ),
                    _orderChip(
                      label: '1) MTS → 2) STS',
                      selected: _evalOrder == _EvalOrder.mtsThenSts,
                      onTap: () {
                        setState(() {
                          _evalOrder = _EvalOrder.mtsThenSts;
                        });
                        unawaited(_persistUserSettings());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _evalOrderLabel,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: _pick(
                      const Color(0xFF718096),
                      const Color(0xFF5E769C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _go(_Scr.sema),
            style: _primaryButtonStyle(),
            child: const Text('İleri → MTS Şema Seç'),
          ),
        ),
      ],
    );
  }

  Widget _buildSema() {
    final entries = _flowcharts.entries
        .where((e) => _group == null || e.value.group == _group)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          2,
          'Baş Şikayet / MTS Şeması',
          'Gruba göre filtrele, şemayı seç · $_evalOrderLabel',
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            _pill('Tümü', _group == null, () => setState(() => _group = null)),
            ..._groups.map(
              (g) => _pill(g, _group == g, () => setState(() => _group = g)),
            ),
          ],
        ),
        const SizedBox(height: 9),
        GridView.builder(
          itemCount: entries.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.06,
          ),
          itemBuilder: (context, index) {
            final key = entries[index].key;
            final flow = entries[index].value;

            return TextButton(
              onPressed: () async {
                setState(() {
                  _schemaKey = key;
                  _mtsIdx = 0;
                  _vals = <String, String>{};
                  _nrs = 5;
                  _mtsFirstPositiveCategory = null;
                  _mtsFirstPositiveDisc = null;
                  _mtsPositiveIndices = <int>{};
                  _mtsResultCode = null;
                  _mtsResultDiscriminator = null;
                  _tsbIdx = 0;
                  _tsbNum = '';
                  _tsbKat = null;
                  _tsbMode = null;
                });
                await _go(
                  _evalOrder == _EvalOrder.stsThenMts ? _Scr.tsb : _Scr.mts,
                );
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: _pick(
                      const Color(0x14FFFFFF),
                      const Color(0xFFD6E1F4),
                    ),
                  ),
                ),
                backgroundColor: _pick(
                  const Color(0x0AFFFFFF),
                  const Color(0xFFF6FAFF),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 10,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: _pick(
                        const Color(0x11FFFFFF),
                        const Color(0xFFEAF2FF),
                      ),
                      border: Border.all(
                        color: _pick(
                          const Color(0x1EFFFFFF),
                          const Color(0xFFD4E1F4),
                        ),
                      ),
                    ),
                    child: Text(
                      flow.icon,
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    flow.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${flow.disc.length} disk.',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: _pick(
                        const Color(0xFF4A5568),
                        const Color(0xFF6B809F),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTsb() {
    final tq = _tq;
    final stepQuestions = _tsbQ.where((q) => q.stepNo == tq.stepNo).toList();
    final stepQuestionNo = stepQuestions.indexOf(tq) + 1;
    final tsbPct = ((_tsbIdx + 1) / _tsbQ.length) * 100;

    Color stepColor;
    if (tq.stepNo <= 2) {
      stepColor = const Color(0xFFE74C3C);
    } else if (tq.stepNo <= 4) {
      stepColor = const Color(0xFFD4AC0D);
    } else {
      stepColor = const Color(0xFF1E8449);
    }

    final numRule = tq.num;
    final numCrossed = numRule == null
        ? false
        : _thresholdCrossed(numRule, _tsbNum);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          3,
          'Sağlık Bakanlığı (STS) Değerlendirmesi',
          '${_schema?.icon ?? ''} ${_schema?.title ?? ''} · '
              '${_evalOrder == _EvalOrder.stsThenMts ? 'Sistem 1/2' : 'Sistem 2/2'}',
        ),
        const SizedBox(height: 8),
        _buildSystemOrderStrip(current: 'sts'),
        const SizedBox(height: 8),
        Text(
          'HIZLI MANUEL GİRİŞ (hemşire kararı)',
          style: TextStyle(
            fontSize: 7.5,
            letterSpacing: 1,
            color: _pick(const Color(0xFF4A5568), const Color(0xFF6C819F)),
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: _tsb.entries.map((entry) {
            final kat = entry.value;
            return SizedBox(
              width: 92,
              child: FilledButton(
                onPressed: () => _tsbManual(entry.key),
                style: FilledButton.styleFrom(
                  backgroundColor: kat.bg,
                  foregroundColor: kat.text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 7,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      kat.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(kat.bekleme, style: const TextStyle(fontSize: 7.5)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: _pick(const Color(0x14FFFFFF), const Color(0xFFD8E2F3)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'VEYA ADIM ADIM (25 KRİTER)',
                style: TextStyle(
                  fontSize: 7.5,
                  color: _pick(
                    const Color(0xFF4A5568),
                    const Color(0xFF6A7E9E),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: _pick(const Color(0x14FFFFFF), const Color(0xFFD8E2F3)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: Text(
                '${tq.stepTitle} · Kriter $stepQuestionNo/${stepQuestions.length}',
                style: TextStyle(
                  fontSize: 7.5,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                  color: stepColor,
                ),
              ),
            ),
            Text(
              '${tsbPct.round()}%',
              style: TextStyle(
                fontSize: 7.5,
                color: _pick(const Color(0xFF4A5568), const Color(0xFF6A7E9D)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        _progressBar(tsbPct, stepColor),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _pick(const Color(0x0AFFFFFF), const Color(0xFFF9FCFF)),
            border: Border.all(
              color: _pick(const Color(0x12FFFFFF), const Color(0xFFD8E3F5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tq.stepSub,
                style: TextStyle(
                  fontSize: 8,
                  color: _pick(
                    const Color(0xFF718096),
                    const Color(0xFF5E769B),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                tq.question,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.5,
                  color: _pick(
                    const Color(0xFFEDF2F7),
                    const Color(0xFF162A4A),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tq.description,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.6,
                  color: _pick(
                    const Color(0xFFA0AEC0),
                    const Color(0xFF4E668D),
                  ),
                ),
              ),
              if (tq.tip != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: _pick(
                      const Color(0x10FFFFFF),
                      const Color(0xFFEFF5FF),
                    ),
                  ),
                  child: Text(
                    '💡 ${tq.tip!}',
                    style: TextStyle(
                      fontSize: 9,
                      color: _pick(
                        const Color(0xFF718096),
                        const Color(0xFF4E668C),
                      ),
                    ),
                  ),
                ),
              ],
              if (numRule != null) ...[
                const SizedBox(height: 11),
                Text(
                  numRule.label,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: _pick(
                      const Color(0xFF718096),
                      const Color(0xFF58719A),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '${numRule.min}–${numRule.max}',
                    filled: true,
                    fillColor: numCrossed
                        ? _pick(
                            const Color(0x33922B21),
                            const Color(0x22F97316),
                          )
                        : _pick(
                            const Color(0x0CFFFFFF),
                            const Color(0xFFF7FAFF),
                          ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: numCrossed
                            ? _pick(
                                const Color(0x80922B21),
                                const Color(0x80F97316),
                              )
                            : _pick(
                                const Color(0x17FFFFFF),
                                const Color(0xFFD5E1F3),
                              ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: numCrossed
                            ? _pick(
                                const Color(0xFF922B21),
                                const Color(0xFFF97316),
                              )
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  controller: TextEditingController(text: _tsbNum)
                    ..selection = TextSelection.collapsed(
                      offset: _tsbNum.length,
                    ),
                  onChanged: (v) => setState(() {
                    _tsbNum = v;
                  }),
                ),
                if (_tsbNum.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      numCrossed
                          ? '⚠️ Eşik aşıldı → Kriter POZİTİF'
                          : '✓ Normal sınırlar',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: numCrossed
                            ? const Color(0xFFF87171)
                            : const Color(0xFF68D391),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _tsbYes,
                style: _yesButtonStyle(),
                child: const Text('✓ Evet'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _tsbNo,
                style: _noButtonStyle(),
                child: const Text('✕ Hayır'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMts() {
    final schema = _schema;
    final md = _md;

    if (schema == null || md == null) {
      return const Text('Şema veya diskriminatör bulunamadı.');
    }

    final double mtsPct = _dList.isEmpty
        ? 0
        : ((_mtsIdx + 1) / _dList.length) * 100;
    final color = _dot[md.category] ?? const Color(0xFF3498DB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          4,
          'Manchester Triage (MTS) · ${schema.title}',
          '${schema.icon} · Diskriminatör ${_mtsIdx + 1}/${_dList.length} · '
              '${_evalOrder == _EvalOrder.stsThenMts ? 'Sistem 2/2' : 'Sistem 1/2'}',
        ),
        const SizedBox(height: 8),
        _buildSystemOrderStrip(current: 'mts'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_mts[md.category]?.label.toUpperCase() ?? md.category} · '
                '${_mts[md.category]?.en ?? ''} · '
                '${_mts[md.category]?.bekleme ?? ''}',
                style: TextStyle(
                  fontSize: 7.5,
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            Text(
              '${mtsPct.round()}%',
              style: TextStyle(
                fontSize: 7.5,
                color: _pick(const Color(0xFF4A5568), const Color(0xFF60789E)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        _progressBar(mtsPct, color),
        const SizedBox(height: 6),
        Row(
          children: _dList.asMap().entries.map((entry) {
            final idx = entry.key;
            final disc = entry.value;
            final dot = _dot[disc.category] ?? const Color(0xFF3498DB);
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: idx < _mtsIdx
                      ? _pick(const Color(0x33FFFFFF), const Color(0xFFCAD7EE))
                      : idx == _mtsIdx
                      ? dot
                      : dot.withAlpha(85),
                  border: idx == _mtsIdx ? Border.all(color: dot) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        _buildMtsModeCard(),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withAlpha(_isDark ? 20 : 30),
            border: Border.all(color: color.withAlpha(_isDark ? 60 : 90)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pozitifse → ${_mts[md.category]?.label ?? md.category} kategorisi atanır',
                    style: TextStyle(
                      fontSize: 8,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                md.description,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _pick(
                    const Color(0xFFEDF2F7),
                    const Color(0xFF162A4A),
                  ),
                ),
              ),
              if (md.note != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: const Color(0x19F6AD55),
                  ),
                  child: Text(
                    'ℹ️ ${md.note!}',
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFFF6AD55),
                    ),
                  ),
                ),
              ],
              if (md.type == _DiscType.nrs) ...[
                const SizedBox(height: 10),
                _buildNrsInput(md),
              ],
              if (md.type == _DiscType.vital) ...[
                const SizedBox(height: 10),
                _buildVitalInput(md),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (md.type == _DiscType.yesNo)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _mtsYes,
                  style: _yesButtonStyle(),
                  child: Text(
                    _mtsStopAtFirstYes ? '✓ Evet' : '✓ Evet (Kaydet)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _mtsNo,
                  style: _noButtonStyle(),
                  child: Text(
                    _mtsStopAtFirstYes ? '✕ Hayır' : '✕ Hayır / Sonraki',
                  ),
                ),
              ),
            ],
          ),
        if (md.type == _DiscType.nrs)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saveNrs,
                  style: FilledButton.styleFrom(
                    backgroundColor: _nrsMatches(md, _nrs)
                        ? const Color(0xFF198754)
                        : _pick(
                            const Color(0x0CFFFFFF),
                            const Color(0xFFE9F1FF),
                          ),
                    foregroundColor: _nrsMatches(md, _nrs)
                        ? Colors.white
                        : _pick(
                            const Color(0xFF718096),
                            const Color(0xFF4F678D),
                          ),
                    side: _nrsMatches(md, _nrs)
                        ? BorderSide.none
                        : BorderSide(
                            color: _pick(
                              const Color(0x14FFFFFF),
                              const Color(0xFFD2DEF2),
                            ),
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(
                    _nrsMatches(md, _nrs)
                        ? (_mtsStopAtFirstYes
                              ? '✓ NRS $_nrs — Pozitif'
                              : '✓ NRS $_nrs — Kaydet')
                        : '✕ NRS $_nrs — Negatif',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _mtsNo,
                  style: _noButtonStyle(),
                  child: const Text('Sonraki Disk. →'),
                ),
              ),
            ],
          ),
        if (md.type == _DiscType.vital)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saveVital,
                  style: FilledButton.styleFrom(
                    backgroundColor: _discCrossed(md)
                        ? const Color(0xFF198754)
                        : _pick(
                            const Color(0x0CFFFFFF),
                            const Color(0xFFE9F1FF),
                          ),
                    foregroundColor: _discCrossed(md)
                        ? Colors.white
                        : _pick(
                            const Color(0xFF718096),
                            const Color(0xFF4E678F),
                          ),
                    side: _discCrossed(md)
                        ? BorderSide.none
                        : BorderSide(
                            color: _pick(
                              const Color(0x14FFFFFF),
                              const Color(0xFFD2DEF2),
                            ),
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(
                    _discCrossed(md)
                        ? (_mtsStopAtFirstYes
                              ? '✓ Eşik Aşıldı'
                              : '✓ Eşik Aşıldı (Kaydet)')
                        : '✓ Pozitif (Klinik)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _mtsNo,
                  style: _noButtonStyle(),
                  child: const Text('✕ Negatif'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        _buildDiscriminatorSequenceTable(),
        if (_tsbKat != null) ...[
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: _glassBox(),
            child: Row(
              children: [
                Text(
                  'TSB ($_tsbMode)',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: _pick(
                      const Color(0xFF4A5568),
                      const Color(0xFF61799C),
                    ),
                  ),
                ),
                const Spacer(),
                if (_tsbKat != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _tsb[_tsbKat!]!.bg,
                    ),
                    child: Text(
                      _tsb[_tsbKat!]!.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _tsb[_tsbKat!]!.text,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMtsModeCard() {
    final positiveCode = _mtsFirstPositiveCategory;
    final positiveLabel = positiveCode == null
        ? null
        : _mts[positiveCode]?.label ?? positiveCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _glassBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MTS Akış Modu',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _pick(
                      const Color(0xFFD4DBE8),
                      const Color(0xFF274167),
                    ),
                  ),
                ),
              ),
              Switch.adaptive(
                value: _mtsStopAtFirstYes,
                onChanged: (v) {
                  setState(() {
                    _mtsStopAtFirstYes = v;
                  });
                  unawaited(_persistUserSettings());
                },
              ),
            ],
          ),
          Text(
            _mtsStopAtFirstYes
                ? "İlk 'Evet' yanıtında değerlendirmeyi bitirir."
                : "Tüm diskriminatörleri sırayla sorar; sonuç ilk pozitif kayda göre hesaplanır.",
            style: TextStyle(
              fontSize: 8.5,
              height: 1.4,
              color: _pick(const Color(0xFF718096), const Color(0xFF5D759A)),
            ),
          ),
          if (positiveLabel != null) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: (_dot[positiveCode] ?? const Color(0xFF3498DB))
                        .withAlpha(_isDark ? 32 : 24),
                    border: Border.all(
                      color: (_dot[positiveCode] ?? const Color(0xFF3498DB))
                          .withAlpha(_isDark ? 90 : 130),
                    ),
                  ),
                  child: Text(
                    'İlk pozitif: $positiveLabel',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: _pick(
                        const Color(0xFFDCE6F9),
                        const Color(0xFF244067),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscriminatorSequenceTable() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _glassBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detaylı Diskriminatör Sırası',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: _pick(const Color(0xFFD4DBE8), const Color(0xFF264066)),
            ),
          ),
          const SizedBox(height: 6),
          ..._dList.asMap().entries.map((entry) {
            final idx = entry.key;
            final disc = entry.value;
            final dot = _dot[disc.category] ?? const Color(0xFF3498DB);
            final isCurrent = idx == _mtsIdx;
            final isPositive = _mtsPositiveIndices.contains(idx);
            final isPassed = idx < _mtsIdx;

            return Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isCurrent
                    ? dot.withAlpha(_isDark ? 24 : 20)
                    : isPositive
                    ? dot.withAlpha(_isDark ? 14 : 18)
                    : _pick(const Color(0x08FFFFFF), const Color(0xFFF4F8FF)),
                border: Border.all(
                  color: isCurrent
                      ? dot
                      : isPositive
                      ? dot.withAlpha(_isDark ? 120 : 150)
                      : _pick(const Color(0x11FFFFFF), const Color(0xFFD4E0F2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _pick(
                        const Color(0x18FFFFFF),
                        const Color(0xFFEAF1FF),
                      ),
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _pick(
                          const Color(0xFFD9E3F7),
                          const Color(0xFF365682),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      disc.description,
                      style: TextStyle(
                        fontSize: 8.8,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _pick(
                          const Color(0xFFE8EEF9),
                          const Color(0xFF28446C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: dot.withAlpha(_isDark ? 32 : 24),
                    ),
                    child: Text(
                      _mts[disc.category]?.label ?? disc.category,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: dot,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  if (isPositive)
                    Icon(Icons.check_circle_rounded, size: 16, color: dot)
                  else if (isCurrent)
                    Icon(Icons.play_circle_fill_rounded, size: 16, color: dot)
                  else if (isPassed)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: _pick(
                        const Color(0xFF6B7B95),
                        const Color(0xFF88A0C4),
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNrsInput(_Discriminator md) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ağrı Şiddeti (NRS)',
              style: TextStyle(
                fontSize: 8.5,
                color: _pick(const Color(0xFF718096), const Color(0xFF59729A)),
              ),
            ),
            const Spacer(),
            Text(
              '$_nrs/10',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _nrsColor(_nrs),
              ),
            ),
          ],
        ),
        Slider(
          value: _nrs.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$_nrs',
          activeColor: _nrsColor(_nrs),
          onChanged: (v) => setState(() {
            _nrs = v.round();
          }),
        ),
        Row(
          children: [
            _smallLegend('0 Ağrı yok'),
            const Spacer(),
            _smallLegend('5 Orta'),
            const Spacer(),
            _smallLegend('10 Dayanılmaz'),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _nrsColor(_nrs).withAlpha(24),
            border: Border.all(color: _nrsColor(_nrs).withAlpha(64)),
          ),
          child: Row(
            children: [
              Text(
                _nrs == 0
                    ? 'Ağrı yok'
                    : _nrs <= 3
                    ? 'Hafif (NRS 1-3)'
                    : _nrs <= 6
                    ? 'Orta (NRS 4-6)'
                    : 'Şiddetli (NRS 7-10)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _nrsColor(_nrs),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                md.badge ?? '',
                style: TextStyle(
                  fontSize: 9,
                  color: _pick(
                    const Color(0xFF718096),
                    const Color(0xFF5F799E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVitalInput(_Discriminator md) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: md.fields.map((f) {
        final crossed = _fieldCrossed(f, _vals[f.key]);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.label,
                style: TextStyle(
                  fontSize: 8.5,
                  color: _pick(
                    const Color(0xFF718096),
                    const Color(0xFF58719A),
                  ),
                ),
              ),
              if (f.note != null)
                Text(
                  f.note!,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFFF6AD55),
                  ),
                ),
              const SizedBox(height: 3),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '${f.min}–${f.max}',
                  filled: true,
                  fillColor: crossed
                      ? _pick(const Color(0x33922B21), const Color(0x22F97316))
                      : _pick(const Color(0x0CFFFFFF), const Color(0xFFF7FAFF)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: crossed
                          ? _pick(
                              const Color(0x80922B21),
                              const Color(0x80F97316),
                            )
                          : _pick(
                              const Color(0x14FFFFFF),
                              const Color(0xFFD2DDF2),
                            ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: crossed
                          ? _pick(
                              const Color(0xFF922B21),
                              const Color(0xFFF97316),
                            )
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                controller: TextEditingController(text: _vals[f.key] ?? '')
                  ..selection = TextSelection.collapsed(
                    offset: (_vals[f.key] ?? '').length,
                  ),
                onChanged: (v) => setState(() {
                  _vals = {..._vals, f.key: v};
                }),
              ),
              if ((_vals[f.key] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    crossed ? '⚠️ Eşik aşıldı → Pozitif' : '✓ Normal sınır',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: crossed
                          ? const Color(0xFFF87171)
                          : const Color(0xFF68D391),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSonuc() {
    final a = _active;
    if (a == null) {
      return const Text('Sonuç bulunamadı.');
    }

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0x1F27AE60),
            border: Border.all(color: const Color(0x4027AE60)),
          ),
          child: const Text('✓', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 7),
        const Text(
          'VAKA KAYDEDİLDİ',
          style: TextStyle(
            fontSize: 7.5,
            color: Color(0xFF27AE60),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '#${a.no} · ${a.time} · ⏱${a.seconds}sn · ${a.schema}',
          style: TextStyle(
            fontSize: 8.5,
            color: _pick(const Color(0xFF4A5568), const Color(0xFF60789E)),
          ),
        ),
        if (a.patient.age.isNotEmpty || a.patient.gender.isNotEmpty)
          Text(
            '${a.patient.age.isNotEmpty ? '${a.patient.age}y' : ''}'
            '${a.patient.gender.isNotEmpty ? ' ${a.patient.gender}' : ''}'
            '${a.patient.history.isNotEmpty ? ' · ${a.patient.history.join(', ')}' : ''}',
            style: TextStyle(
              fontSize: 8.5,
              color: _pick(const Color(0xFF4A5568), const Color(0xFF5F789D)),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _catBox('TSB', _tsb[a.tsb]!)),
            const SizedBox(width: 8),
            Expanded(child: _catBox('MTS', _mts[a.mts]!)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: _glassBox(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KATEGORİ BELİRLEYEN DİSKRİMİNATÖR',
                style: TextStyle(
                  fontSize: 7.5,
                  letterSpacing: 0.8,
                  color: _pick(
                    const Color(0xFF4A5568),
                    const Color(0xFF627A9F),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                a.discriminator,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color:
                      _dot[a.mts] ??
                      _pick(const Color(0xFFDDE3EF), const Color(0xFF2C4A72)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: a.compat.color.withAlpha(14),
            border: Border.all(color: a.compat.color.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${a.compat.icon} ${a.compat.short == 'Uyumlu' ? 'Sistemler Uyumlu' : 'Dikkat: ${a.compat.short}'}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: a.compat.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                a.compat.message,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.6,
                  color: _pick(
                    const Color(0xFF718096),
                    const Color(0xFF4F678E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 2.5,
          children: [
            _metric('Süre', '${a.seconds} sn'),
            _metric('TSB Bekleme', _tsb[a.tsb]!.bekleme),
            _metric('MTS Bekleme', _mts[a.mts]!.bekleme),
            _metric(
              'TSB Giriş',
              a.tsbMode == 'manuel' ? 'Manuel' : 'Karar Ağacı',
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _newCase,
            style: _primaryButtonStyle(),
            child: const Text('＋ Yeni Vaka'),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _go(_Scr.rapor),
            style: _secondaryButtonStyle(),
            child: const Text('📊 Tüm Raporlar'),
          ),
        ),
      ],
    );
  }

  Widget _buildRapor() {
    final reversed = _cases.reversed.toList();

    final total = _cases.length;
    final mismatch = _cases.where((v) => v.compat.type != 'uyumlu').length;
    final down = _cases.where((v) => v.compat.type == 'alttriaj').length;
    final up = _cases.where((v) => v.compat.type == 'usttriaj').length;

    final stats = [
      ('Toplam', total.toString(), const Color(0xFF60A5FA)),
      ('Uyumsuz', mismatch.toString(), const Color(0xFFFBBF24)),
      ('Alt↓', down.toString(), const Color(0xFFF97316)),
      ('Üst↑', up.toString(), const Color(0xFFF87171)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton(
              onPressed: () => _go(_Scr.ana),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '← Geri',
                style: TextStyle(
                  fontSize: 9.5,
                  color: _pick(
                    const Color(0xFF718096),
                    const Color(0xFF4F6790),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Vaka Raporları',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_cases.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                '📋\nHenüz kayıtlı vaka yok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _pick(
                    const Color(0xFF4A5568),
                    const Color(0xFF5E759A),
                  ),
                ),
              ),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final stat = stats[index];
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: _glassBox(radius: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.$2,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: stat.$3,
                      ),
                    ),
                    Text(
                      stat.$1,
                      style: TextStyle(
                        fontSize: 7.5,
                        color: _pick(
                          const Color(0xFF4A5568),
                          const Color(0xFF617A9F),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 9),
          _buildMtsDistribution(),
          const SizedBox(height: 9),
          ...reversed.map(_reportTile),
        ],
      ],
    );
  }

  Widget _buildMtsDistribution() {
    final chips = <Widget>[];
    for (final e in _mts.entries) {
      final n = _cases.where((v) => v.mts == e.key).length;
      if (n == 0) {
        continue;
      }
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: e.value.bg,
          ),
          child: Text(
            '${e.value.label}: $n',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: e.value.text,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _glassBox(radius: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MTS DAĞILIMI',
            style: TextStyle(
              fontSize: 7.5,
              letterSpacing: 0.9,
              color: _pick(const Color(0xFF4A5568), const Color(0xFF60799D)),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 4, runSpacing: 4, children: chips),
        ],
      ),
    );
  }

  Widget _reportTile(_CaseReport v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _pick(const Color(0x0AFFFFFF), const Color(0xFFF8FBFF)),
        border: Border.all(
          color: v.compat.type != 'uyumlu'
              ? const Color(0x29F59E0B)
              : _pick(const Color(0x14FFFFFF), const Color(0xFFD8E2F3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${v.no} — ${v.schema}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${v.patient.age.isNotEmpty ? '${v.patient.age}y' : ''}'
                      '${v.patient.gender.isNotEmpty ? ' ${v.patient.gender}' : ''}'
                      '${v.patient.history.isNotEmpty ? ' · ${v.patient.history.join(',')}' : ''}',
                      style: TextStyle(
                        fontSize: 8,
                        color: _pick(
                          const Color(0xFF4A5568),
                          const Color(0xFF627B9F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${v.time}\n${v.seconds}sn',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 8,
                  color: _pick(
                    const Color(0xFF4A5568),
                    const Color(0xFF60789D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _tinyTag(
                'TSB: ${_tsb[v.tsb]!.label}',
                _tsb[v.tsb]!.bg,
                _tsb[v.tsb]!.text,
              ),
              _tinyTag(
                'MTS: ${_mts[v.mts]!.label}',
                _mts[v.mts]!.bg,
                _mts[v.mts]!.text,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: v.compat.color.withAlpha(22),
                  border: Border.all(color: v.compat.color.withAlpha(53)),
                ),
                child: Text(
                  '${v.compat.icon} ${v.compat.short}',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: v.compat.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Disk: ${v.discriminator}',
            style: TextStyle(
              fontSize: 8,
              color: _pick(const Color(0xFF4A5568), const Color(0xFF60789D)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tinyTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: bg,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _catBox(String label, _CategoryInfo cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cat.bg,
        boxShadow: [
          BoxShadow(
            color: cat.bg.withAlpha(102),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: Color(0x8CFFFFFF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cat.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: cat.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cat.bekleme,
            style: const TextStyle(fontSize: 7, color: Color(0x8CFFFFFF)),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: _glassBox(radius: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 7.5,
              letterSpacing: 0.8,
              color: _pick(const Color(0xFF4A5568), const Color(0xFF637BA0)),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            val,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _orderChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? _pick(const Color(0xAA8B5CF6), const Color(0x99C084FC))
                : _pick(const Color(0x24FFFFFF), const Color(0xFFE6D7F8)),
          ),
        ),
        backgroundColor: selected
            ? _pick(const Color(0x2F8B5CF6), const Color(0x26FF9F68))
            : _pick(const Color(0x14FFFFFF), const Color(0xFFFFF8FD)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: selected
              ? _pick(const Color(0xFFF2E9FF), const Color(0xFF9A5C00))
              : _pick(const Color(0xFFC4B5E0), const Color(0xFF67568D)),
        ),
      ),
    );
  }

  Widget _buildSystemOrderStrip({required String current}) {
    final stsFirst = _evalOrder == _EvalOrder.stsThenMts;
    final stsDone = current == 'mts' && stsFirst;
    final mtsDone = current == 'sts' && !stsFirst;
    final stsCurrent = current == 'sts';
    final mtsCurrent = current == 'mts';

    Widget item({
      required String title,
      required String subtitle,
      required bool active,
      required bool done,
      required Color accent,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active
                ? accent.withAlpha(_isDark ? 28 : 22)
                : _pick(const Color(0x0AFFFFFF), const Color(0xFFF6FAFF)),
            border: Border.all(
              color: active
                  ? accent
                  : _pick(const Color(0x14FFFFFF), const Color(0xFFD6E2F4)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : active
                    ? Icons.play_circle_fill_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: done || active
                    ? accent
                    : _pick(const Color(0xFF72819A), const Color(0xFF8FA5C8)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: _pick(
                          const Color(0xFFE4ECF9),
                          const Color(0xFF2C476E),
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 7.5,
                        color: _pick(
                          const Color(0xFF73829A),
                          const Color(0xFF61799F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: stsFirst
          ? [
              item(
                title: '1. STS',
                subtitle: 'Sağlık Bakanlığı',
                active: stsCurrent,
                done: stsDone,
                accent: const Color(0xFFFF9F68),
              ),
              const SizedBox(width: 6),
              item(
                title: '2. MTS',
                subtitle: 'Manchester',
                active: mtsCurrent,
                done: mtsDone,
                accent: const Color(0xFF8B5CF6),
              ),
            ]
          : [
              item(
                title: '1. MTS',
                subtitle: 'Manchester',
                active: mtsCurrent,
                done: mtsDone,
                accent: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 6),
              item(
                title: '2. STS',
                subtitle: 'Sağlık Bakanlığı',
                active: stsCurrent,
                done: stsDone,
                accent: const Color(0xFFFF9F68),
              ),
            ],
    );
  }

  Widget _stepHeader(int no, String title, String? sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADIM $no / 4',
          style: const TextStyle(
            fontSize: 7.5,
            letterSpacing: 1.4,
            color: Color(0xFFE74C3C),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        if (sub != null)
          Text(
            sub,
            style: TextStyle(
              fontSize: 9.5,
              color: _pick(const Color(0xFF4A5568), const Color(0xFF5E769C)),
            ),
          ),
      ],
    );
  }

  Widget _progressBar(double val, Color color) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: _pick(const Color(0x14FFFFFF), const Color(0xFFD7E1F2)),
      ),
      child: FractionallySizedBox(
        widthFactor: (val / 100).clamp(0, 1),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 7.5,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: _pick(const Color(0xFF4A5568), const Color(0xFF60789D)),
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _smallLegend(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 7.5,
        color: _pick(const Color(0xFF4A5568), const Color(0xFF5F789D)),
      ),
    );
  }

  Widget _pill(String label, bool active, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: active
                ? _pick(const Color(0xAA8B5CF6), const Color(0x99C084FC))
                : _pick(const Color(0x24FFFFFF), const Color(0xFFE8DDF6)),
          ),
        ),
        backgroundColor: active
            ? _pick(const Color(0x2F8B5CF6), const Color(0x26FF9F68))
            : _pick(const Color(0x14FFFFFF), const Color(0xFFFFF8FD)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: active
              ? _pick(const Color(0xFFF1E8FF), const Color(0xFF9A5C00))
              : _pick(const Color(0xFFC6B5E3), const Color(0xFF6E5B93)),
        ),
      ),
    );
  }

  BoxDecoration _glassBox({double radius = 12}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: _pick(const Color(0x14FFFFFF), const Color(0xFFFFFBFF)),
      border: Border.all(
        color: _pick(const Color(0x33BFA6FF), const Color(0xFFE6D7F8)),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: const Color(0xFF8B5CF6),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return const Color(0xFF7445DE);
        }
        return const Color(0xFF8B5CF6);
      }),
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      side: BorderSide(
        color: _pick(const Color(0x29CBB0FF), const Color(0xFFE6D7F8)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      foregroundColor: _pick(const Color(0xFFD2C4EA), const Color(0xFF6C4FA8)),
      backgroundColor: _pick(const Color(0x19FFFFFF), const Color(0xFFFFF8FD)),
    );
  }

  ButtonStyle _yesButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: const Color(0xFF198754),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(15),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }

  ButtonStyle _noButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: const Color(0xFF7B2D2D),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(15),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}

String _hhmm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

const List<String> _historyOptions = [
  'DM',
  'KAH',
  'HT',
  'KOAH',
  'KKY',
  'İmmün',
  'Antikoag',
  'Gebelik',
  'Onkoloji',
  'Yok',
];

const Map<String, _CategoryInfo> _tsb = {
  'K1': _CategoryInfo(
    label: 'Kırmızı-1',
    bg: Color(0xFF922B21),
    text: Colors.white,
    bekleme: '0 dk',
    sub: 'Anlık resüsitasyon',
  ),
  'K2': _CategoryInfo(
    label: 'Kırmızı-2',
    bg: Color(0xFFC0392B),
    text: Colors.white,
    bekleme: '≤10 dk',
    sub: 'Çok acil',
  ),
  'S1': _CategoryInfo(
    label: 'Sarı-1',
    bg: Color(0xFF7D6608),
    text: Colors.white,
    bekleme: '≤30 dk',
    sub: 'Öncelikli sarı',
  ),
  'S2': _CategoryInfo(
    label: 'Sarı-2',
    bg: Color(0xFFB7950B),
    text: Colors.white,
    bekleme: '≤60 dk',
    sub: 'Yarı acil',
  ),
  'YE': _CategoryInfo(
    label: 'Yeşil',
    bg: Color(0xFF1E8449),
    text: Colors.white,
    bekleme: '≥120 dk',
    sub: 'Poliklinik',
  ),
};

const Map<String, _CategoryInfo> _mts = {
  'R': _CategoryInfo(
    label: 'Kırmızı',
    bg: Color(0xFF922B21),
    text: Colors.white,
    bekleme: '0 dk',
    en: 'Immediate',
  ),
  'O': _CategoryInfo(
    label: 'Turuncu',
    bg: Color(0xFFBA4A00),
    text: Colors.white,
    bekleme: '≤10 dk',
    en: 'Very Urgent',
  ),
  'Y': _CategoryInfo(
    label: 'Sarı',
    bg: Color(0xFF7D6608),
    text: Colors.white,
    bekleme: '≤60 dk',
    en: 'Urgent',
  ),
  'G': _CategoryInfo(
    label: 'Yeşil',
    bg: Color(0xFF1E8449),
    text: Colors.white,
    bekleme: '≤120 dk',
    en: 'Standard',
  ),
  'B': _CategoryInfo(
    label: 'Mavi',
    bg: Color(0xFF1A5276),
    text: Colors.white,
    bekleme: '≤240 dk',
    en: 'Non-Urgent',
  ),
};

const Map<String, Color> _dot = {
  'R': Color(0xFFE74C3C),
  'O': Color(0xFFE67E22),
  'Y': Color(0xFFF4D03F),
  'G': Color(0xFF2ECC71),
  'B': Color(0xFF3498DB),
};

const Map<String, String> _tsbToMts = {
  'K1': 'R',
  'K2': 'O',
  'S1': 'Y',
  'S2': 'G',
  'YE': 'B',
};

const List<String> _mtsOrder = ['R', 'O', 'Y', 'G', 'B'];

const List<_TsbQuestion> _tsbQ = [
  _TsbQuestion(
    id: 'k1_arrest',
    stepNo: 1,
    category: 'K1',
    stepTitle: 'Adım 1 / 5 — Kırmızı-1',
    stepSub: 'Hayatı tehdit eden — anlık resüsitasyon',
    question: 'Kardiyak veya solunumsal arrest var mı?',
    description:
        'Santral nabız yok (10 sn aranır) VE/VEYA solunum hareketi / hava akımı yok.',
    tip: 'KPR endikasyonu → kategori atamadan önce ekibi çağır',
  ),
  _TsbQuestion(
    id: 'k1_hava',
    stepNo: 1,
    category: 'K1',
    stepTitle: 'Adım 1 / 5 — Kırmızı-1',
    stepSub: 'Hayatı tehdit eden — anlık resüsitasyon',
    question: 'Havayolu tıkanıklığı riski veya solunum hızı <10/dk var mı?',
    description:
        'Stridor, total obstrüksiyon, agonal nefes, yetersiz göğüs hareketi.',
    tip: 'SS: göğüs hareketini 30 sn say × 2. Normal: 12-20/dk',
    num: _NumericRule(
      label: 'SS (/dk)',
      min: 0,
      max: 60,
      threshold: 10,
      direction: 'alt',
      unit: '/dk',
    ),
  ),
  _TsbQuestion(
    id: 'k1_travma',
    stepNo: 1,
    category: 'K1',
    stepTitle: 'Adım 1 / 5 — Kırmızı-1',
    stepSub: 'Hayatı tehdit eden — anlık resüsitasyon',
    question: 'Major çoklu travma var mı?',
    description:
        'İki veya daha fazla bölgeyi etkileyen penetran/künt ciddi yaralanma (MVA, yüksekten düşme, blast).',
    tip: 'Mekanizm + vital bozukluğu birlikteliği major travmayı düşündürür',
  ),
  _TsbQuestion(
    id: 'k1_sok',
    stepNo: 1,
    category: 'K1',
    stepTitle: 'Adım 1 / 5 — Kırmızı-1',
    stepSub: 'Hayatı tehdit eden — anlık resüsitasyon',
    question: 'Sistolik KB <80 mmHg veya şok tablosu var mı?',
    description:
        'Hipotansiyon + soğuk/nemli/soluk deri + taşikardi = şok. SKB <80 tek başına da yeterli.',
    tip: 'Kapiller dolum >3 sn, bilinç bozukluğu şok belirtilerindendir',
    num: _NumericRule(
      label: 'SKB (mmHg)',
      min: 40,
      max: 250,
      threshold: 80,
      direction: 'alt',
      unit: 'mmHg',
    ),
  ),
  _TsbQuestion(
    id: 'k1_bilinc',
    stepNo: 1,
    category: 'K1',
    stepTitle: 'Adım 1 / 5 — Kırmızı-1',
    stepSub: 'Hayatı tehdit eden — anlık resüsitasyon',
    question:
        'Sadece ağrıya yanıt veren / yanıtsız hasta veya uzamış nöbet (>5 dk) var mı?',
    description:
        'AVPU skalasında P veya U. GKS ≤8. Status epilepticus (>5 dk nöbet).',
    tip: 'AVPU: Alert – Voice – Pain – Unresponsive. P veya U → K1',
    num: _NumericRule(
      label: 'GKS (3-15)',
      min: 3,
      max: 15,
      threshold: 8,
      direction: 'alt',
      unit: 'puan',
    ),
  ),
  _TsbQuestion(
    id: 'k2_gogus',
    stepNo: 2,
    category: 'K2',
    stepTitle: 'Adım 2 / 5 — Kırmızı-2',
    stepSub: 'Max 10 dk içinde müdahale',
    question:
        'Kardiyak tipte göğüs ağrısı veya ciddi nefes darlığı var mı?\n(SpO₂ <%90 + yardımcı solunum kası kullanımı)',
    description:
        'Ezici/baskılayıcı göğüs ağrısı + terleme veya SpO₂ <%90 ile aktif yardımcı kas kullanımı.',
    tip: 'Kardiyak ağrı: retrosternal, çene/kola yayılım, bulantı eşliğinde',
    num: _NumericRule(
      label: 'SpO₂ (%)',
      min: 50,
      max: 100,
      threshold: 90,
      direction: 'alt',
      unit: '%',
    ),
  ),
  _TsbQuestion(
    id: 'k2_dolasim',
    stepNo: 2,
    category: 'K2',
    stepTitle: 'Adım 2 / 5 — Kırmızı-2',
    stepSub: 'Max 10 dk içinde müdahale',
    question:
        'Dolaşım bozukluğu var mı?\n(KTA <50 veya >150/dk, soğuk/nemli deri, hipotansiyon)',
    description:
        'Bradikardi veya ciddi taşikardi + periferik dolaşım bozukluğu belirtileri.',
    tip:
        'Normal KTA: 60-100/dk. <50 = ciddi bradikardi. >150 = tehlikeli taşikardi',
    num: _NumericRule(
      label: 'KTA (/dk)',
      min: 20,
      max: 280,
      thresholdLow: 50,
      thresholdHigh: 150,
      direction: 'cift',
      unit: '/dk',
    ),
  ),
  _TsbQuestion(
    id: 'k2_inme',
    stepNo: 2,
    category: 'K2',
    stepTitle: 'Adım 2 / 5 — Kırmızı-2',
    stepSub: 'Max 10 dk içinde müdahale',
    question: 'Akut hemiparezi veya disfazi var mı? (İnme / FAST pozitif)',
    description:
        'Yüz asimetrisi, tek taraflı kol güçsüzlüğü, konuşma güçlüğü — yeni başlayan.',
    tip:
        'FAST: Face – Arm – Speech – Time. Başlangıçtan geçen süreyi kaydet! (<4.5 sa = tromboliz penceresi)',
  ),
  _TsbQuestion(
    id: 'k2_goz',
    stepNo: 2,
    category: 'K2',
    stepTitle: 'Adım 2 / 5 — Kırmızı-2',
    stepSub: 'Max 10 dk içinde müdahale',
    question:
        'İrrigasyon gerektiren asit/alkali göz teması, major fraktür veya ampütasyon var mı?',
    description:
        'Kimyasal göz teması → irrigasyona derhal başla (kategori beklemez). Major fraktür: femur, pelvis. Ampütasyon: herhangi uzuv.',
    tip: '⚠️ Kimyasal göz temasında triajı beklemeden irrigasyon başlatılır!',
  ),
  _TsbQuestion(
    id: 'k2_zehir',
    stepNo: 2,
    category: 'K2',
    stepTitle: 'Adım 2 / 5 — Kırmızı-2',
    stepSub: 'Max 10 dk içinde müdahale',
    question:
        'İlaç aşırı alımı, toksik madde alımı veya agresif / kendine zarar veren psikiyatrik durum var mı?',
    description:
        'Aşırı doz: ne aldığı, ne zaman, ne kadar sorunsuz. Agresif psikiyatrik: aktif zarar verme riski.',
    tip:
        'Toksik madde alımı: vital bulgu bozulmasa bile K2. Psikiyatrik ajitasyon: güvenlik önce',
  ),
  _TsbQuestion(
    id: 's1_ht',
    stepNo: 3,
    category: 'S1',
    stepTitle: 'Adım 3 / 5 — Sarı-1',
    stepSub: 'Hayati tehdit veya uzuv kaybı riski',
    question:
        'Hipertansif acil var mı?\n(Diastolik >110 veya Sistolik >180 mmHg + semptom)',
    description:
        'Semptomatik yüksek KB: baş ağrısı, bulanık görme, göğüs ağrısı veya nörolojik bulgu eşliğinde.',
    tip: 'Asemptomatik yüksek KB (urgency) → S2. Semptomlu (emergency) → S1',
    num: _NumericRule(
      label: 'SKB (mmHg)',
      min: 80,
      max: 300,
      threshold: 180,
      direction: 'ust',
      unit: 'mmHg',
    ),
  ),
  _TsbQuestion(
    id: 's1_karin',
    stepNo: 3,
    category: 'S1',
    stepTitle: 'Adım 3 / 5 — Sarı-1',
    stepSub: 'Hayati tehdit veya uzuv kaybı riski',
    question:
        'Şiddetli karın ağrısı (NRS ≥7) veya 65 yaş üstü karın ağrısı var mı?',
    description:
        'Şiddetli karın ağrısı → akut karın, perforasyon riski. 65+ yaş → atipik prezentasyon, yüksek komplikasyon riski.',
    tip: '65 yaş ve üstü her tür karın ağrısı otomatik S1 alır',
    num: _NumericRule(
      label: 'NRS Ağrı (0-10)',
      min: 0,
      max: 10,
      threshold: 7,
      direction: 'ust',
      unit: '/10',
    ),
  ),
  _TsbQuestion(
    id: 's1_kanama',
    stepNo: 3,
    category: 'S1',
    stepTitle: 'Adım 3 / 5 — Sarı-1',
    stepSub: 'Hayati tehdit veya uzuv kaybı riski',
    question:
        'Orta derecede kan kaybı veya orta derecede solunum sıkıntısı var mı?',
    description:
        'Aktif orta kanama, kanlı kusmuk veya SpO₂ %90-94 / SS 20-28/dk ile orta solunum güçlüğü.',
    tip: 'Orta solunum sıkıntısı: yardımcı kas yok ama hasta rahat değil',
  ),
  _TsbQuestion(
    id: 's1_kafa',
    stepNo: 3,
    category: 'S1',
    stepTitle: 'Adım 3 / 5 — Sarı-1',
    stepSub: 'Hayati tehdit veya uzuv kaybı riski',
    question:
        'Amnezi ile birlikte kafa travması veya uyanık hastada nöbet öyküsü var mı?',
    description:
        'Kafa travması + retrograd/anterograd amnezi → intraserebral kanama ekarte edilmeli. Geçirilmiş nöbet + uyanık → post-iktal, status riski.',
    tip:
        'Retrograd: travma öncesini hatırlamıyor. Anterograd: sonrasını hatırlamıyor. İkisi de önemli.',
  ),
  _TsbQuestion(
    id: 's1_febril',
    stepNo: 3,
    category: 'S1',
    stepTitle: 'Adım 3 / 5 — Sarı-1',
    stepSub: 'Hayati tehdit veya uzuv kaybı riski',
    question:
        'Ateş yüksekliği olan onkoloji / steroid / immünsupresif hasta ya da inatçı kusma var mı?',
    description:
        'Febril nötropeni → hayati tehlike, 30 dk içinde antibiyotik. İnatçı kusma → dehidratasyon + elektrolit bozukluğu.',
    tip:
        'Kemoterapi + ateş → febril nötropeni ekarte edilinceye dek S1 veya üstü',
  ),
  _TsbQuestion(
    id: 's1_eks',
    stepNo: 3,
    category: 'S1',
    stepTitle: 'Adım 3 / 5 — Sarı-1',
    stepSub: 'Hayati tehdit veya uzuv kaybı riski',
    question:
        'Deformite veya ezilme içeren ciddi ekstremite yaralanması ya da çocuk istismarı şüphesi var mı?',
    description:
        'Ciddi ekstremite: açık kırık, damar-sinir tehlikesi, kompartman sendromu riski. Çocuk istismarı: mekanizma ile uyumsuz yaralanma.',
    tip:
        '6P: Pain, Pallor, Pulselessness, Paresthesia, Paralysis, Poikilothermia → Kompartman sendromu!',
  ),
  _TsbQuestion(
    id: 's2_basit',
    stepNo: 4,
    category: 'S2',
    stepTitle: 'Adım 4 / 5 — Sarı-2',
    stepSub: 'Ciddiyet potansiyeli — beklenebilir',
    question:
        'Basit kanama, şiddetli olmayan karın ağrısı (NRS 4-6) veya yutma güçlüğü (solunum sıkıntısı olmadan) var mı?',
    description:
        'Kontrol altındaki kanama, periton irritasyonu olmayan orta karın ağrısı, hava yolu güvende disfaji.',
    tip: 'Bu grupta vital bulgular genellikle normal sınırlardadır',
  ),
  _TsbQuestion(
    id: 's2_minorkafa',
    stepNo: 4,
    category: 'S2',
    stepTitle: 'Adım 4 / 5 — Sarı-2',
    stepSub: 'Ciddiyet potansiyeli — beklenebilir',
    question:
        'Bilinç kaybı olmayan minör kafa travması veya basit göğüs yaralanması var mı?',
    description:
        'GKS 15, amnezi yok, fokal defisit yok. Göğüs: pnömotoraks riski düşük, vital bulgular normal.',
    tip: 'Minör kafa travması: GKS 15 + amnezi yok + normal nörolojik muayene',
  ),
  _TsbQuestion(
    id: 's2_gis',
    stepNo: 4,
    category: 'S2',
    stepTitle: 'Adım 4 / 5 — Sarı-2',
    stepSub: 'Ciddiyet potansiyeli — beklenebilir',
    question: 'Dehidratasyon belirtisi olmayan kusma ve ishal var mı?',
    description:
        'Vital bulgular stabil, deri turgoru normal, mukozalar ıslak, idrar normal renk/miktarda.',
    tip:
        'Dehidratasyon belirtileri: kuru mukoza, turgor ↓, idrar koyu/az → S1\'e yükselt',
  ),
  _TsbQuestion(
    id: 's2_eks',
    stepNo: 4,
    category: 'S2',
    stepTitle: 'Adım 4 / 5 — Sarı-2',
    stepSub: 'Ciddiyet potansiyeli — beklenebilir',
    question:
        'Minör ekstremite travması mı var? (burkulma, basit kesiler, basit fraktür şüphesi)\nVe vital bulgular normal mi?',
    description:
        'Nörovasküler kompromis YOK. Ağrı NRS ≤6. Vital bulgular normal sınırlar.',
    tip: 'Distal nabız yok veya his kaybı varsa → S1 veya K2\'ye yükselt',
  ),
  _TsbQuestion(
    id: 'ye_agri',
    stepNo: 5,
    category: 'YE',
    stepTitle: 'Adım 5 / 5 — Yeşil Alan',
    stepSub: 'Stabil — poliklinik / hızlı bakı',
    question: 'Yüksek risk taşımayan hafif ağrı (NRS ≤3) var mı?',
    description:
        'Vital bulgular normal, tek ve basit şikayet, akut bozulma belirtisi yok.',
    num: _NumericRule(
      label: 'NRS Ağrı (0-10)',
      min: 0,
      max: 10,
      threshold: 3,
      direction: 'alt_esik_dahil',
      unit: '/10',
    ),
  ),
  _TsbQuestion(
    id: 'ye_yara',
    stepNo: 5,
    category: 'YE',
    stepTitle: 'Adım 5 / 5 — Yeşil Alan',
    stepSub: 'Stabil — poliklinik / hızlı bakı',
    question: 'Basit yara, sıyrık veya dikiş gerektirmeyen küçük kesi var mı?',
    description:
        'Kanama kontrol altında, damar/sinir hasarı yok, enfeksiyon belirtisi yok.',
  ),
  _TsbQuestion(
    id: 'ye_kronik',
    stepNo: 5,
    category: 'YE',
    stepTitle: 'Adım 5 / 5 — Yeşil Alan',
    stepSub: 'Stabil — poliklinik / hızlı bakı',
    question:
        'Aktif yakınması olmayan kronik/düşük riskli başvuru mu? (reçete, kontrol, stabil psikiyatri)',
    description:
        'Kronik ilaç yenileme, kontrol randevusu, iyi durumda kronik psikiyatrik şikayet.',
  ),
];

_Flowchart _summaryFlowchart({
  required String group,
  required String title,
  required String icon,
  required List<String> red,
  required List<String> orange,
  List<String> yellow = const <String>[],
  List<String> green = const <String>[],
  bool includeGeneralRed = true,
  bool includePain = true,
}) {
  final disc = <_Discriminator>[];
  final seen = <String>{};

  void add({
    required String description,
    required String category,
    required _DiscType type,
    String? note,
    num? threshold,
    num? thresholdLow,
    num? thresholdHigh,
    String? badge,
    bool isFinal = false,
  }) {
    final key = '$category::$description';
    if (!seen.add(key)) {
      return;
    }
    disc.add(
      _Discriminator(
        description: description,
        category: category,
        type: type,
        note: note,
        threshold: threshold,
        thresholdLow: thresholdLow,
        thresholdHigh: thresholdHigh,
        badge: badge,
        isFinal: isFinal,
      ),
    );
  }

  if (includeGeneralRed) {
    add(
      description: 'Hava yolu tıkanıklığı / tehditi var mı?',
      category: 'R',
      type: _DiscType.yesNo,
    );
    add(
      description: 'Yetersiz solunum / apne var mı?',
      category: 'R',
      type: _DiscType.yesNo,
    );
    add(
      description: 'Şok bulguları var mı?',
      category: 'R',
      type: _DiscType.yesNo,
    );
  }

  for (final description in red) {
    add(description: description, category: 'R', type: _DiscType.yesNo);
  }
  for (final description in orange) {
    add(description: description, category: 'O', type: _DiscType.yesNo);
  }

  if (includePain) {
    add(
      description: 'Şiddetli ağrı NRS 7-10?',
      category: 'O',
      type: _DiscType.nrs,
      threshold: 7,
      badge: 'Şiddetli (7-10) → Turuncu',
    );
  }

  for (final description in yellow) {
    add(description: description, category: 'Y', type: _DiscType.yesNo);
  }

  if (includePain) {
    add(
      description: 'Orta ağrı NRS 4-6?',
      category: 'Y',
      type: _DiscType.nrs,
      thresholdLow: 4,
      thresholdHigh: 6,
      badge: 'Orta (4-6) → Sarı',
    );
  }

  for (final description in green) {
    add(description: description, category: 'G', type: _DiscType.yesNo);
  }

  if (includePain) {
    add(
      description: 'Yeni hafif ağrı NRS 1-3?',
      category: 'G',
      type: _DiscType.nrs,
      thresholdLow: 1,
      thresholdHigh: 3,
      badge: 'Hafif (1-3) → Yeşil',
    );
  }

  add(description: 'Recent Problem', category: 'G', type: _DiscType.yesNo);
  add(
    description: 'No Urgency Indicators',
    category: 'B',
    type: _DiscType.yesNo,
    isFinal: true,
  );

  return _Flowchart(group: group, title: title, icon: icon, disc: disc);
}

final Map<String, _Flowchart> _flowcharts = {
  'c01': _Flowchart(
    group: 'Kardiyovasküler',
    title: 'Kardiyak Arrest',
    icon: '❤️',
    disc: [
      _Discriminator(
        description: 'Hasta yanıtsız, nabız yok, solunum yok',
        category: 'R',
        type: _DiscType.yesNo,
        note: 'Derhal KPR + ekip çağrısı',
      ),
    ],
  ),
  'c02': _Flowchart(
    group: 'Kardiyovasküler',
    title: 'Göğüs Ağrısı',
    icon: '🫀',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı var mı? (stridor, obstrüksiyon)',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum / apne var mı?',
        category: 'R',
        type: _DiscType.yesNo,
        note: 'SpO₂ kritik, agonal nefes',
      ),
      _Discriminator(
        description: 'Şok var mı? (hipotansiyon + taşikardi + soğuk deri)',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı şiddeti NRS kaç?',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli (≥7) → Turuncu',
      ),
      _Discriminator(
        description: 'Kardiyak tipte ağrı var mı? (ezici, çene/kola yayılım)',
        category: 'O',
        type: _DiscType.yesNo,
        note: 'Kardiyak ağrı NRS≥5 bile Turuncu!',
      ),
      _Discriminator(
        description: 'Akut nefes darlığı eşlik ediyor mu? (ani başlangıç)',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Anormal nabız: KTA <50 veya >150/dk?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'kta',
            label: 'KTA (/dk)',
            min: 20,
            max: 280,
            thresholdLow: 50,
            thresholdHigh: 150,
            direction: 'cift',
          ),
        ],
      ),
      _Discriminator(
        description: 'Plöritik ağrı var mı? (inspirasyonla artan)',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı şiddeti NRS kaç? (orta şiddet kontrolü)',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta (4-6) → Sarı',
      ),
      _Discriminator(
        description: 'Önemli kardiyak öykü var mı? (KAH, MI, stent, KKY)',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kusma eşlik ediyor mu?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hafif ağrı (NRS 1-3) var mı?',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif (1-3) → Yeşil',
      ),
      _Discriminator(
        description: 'Yeni başlayan semptom, acil bulgu yok',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kronik şikayet, acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'c03': _Flowchart(
    group: 'Kardiyovasküler',
    title: 'Çarpıntı',
    icon: '💓',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'Anormal nabız: KTA <50 veya >150/dk?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'kta',
            label: 'KTA (/dk)',
            min: 20,
            max: 280,
            thresholdLow: 50,
            thresholdHigh: 150,
            direction: 'cift',
          ),
        ],
      ),
      _Discriminator(
        description: 'Göğüs ağrısı eşlik ediyor mu?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı şiddeti NRS kaç?',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli (≥7) → Turuncu',
      ),
      _Discriminator(
        description: 'Kollaps / senkop öyküsü var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı şiddeti NRS 4-6?',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta (4-6) → Sarı',
      ),
      _Discriminator(
        description: 'Önemli kardiyak öykü',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hafif ağrı (NRS 1-3)',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'c04': _Flowchart(
    group: 'Kardiyovasküler',
    title: 'Kollaps / Senkop',
    icon: '🫸',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'Bilinç bozukluğu var mı?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Anormal nabız: KTA <50 veya >150/dk?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'kta',
            label: 'KTA (/dk)',
            min: 20,
            max: 280,
            thresholdLow: 50,
            thresholdHigh: 150,
            direction: 'cift',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli ≥7 → Turuncu',
      ),
      _Discriminator(
        description: 'Kardiyak tipte ağrı',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta 4-6 → Sarı',
      ),
      _Discriminator(
        description: 'Bilinç kaybı öyküsü (şu an uyanık)',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'n01': _Flowchart(
    group: 'Nörolojik',
    title: 'Baş Ağrısı',
    icon: '🧠',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'Aktif nöbet (Currently Fitting) var mı?',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Şiddetli ağrı (NRS 7-10) var mı?',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Severe Pain (7-10) → Turuncu',
      ),
      _Discriminator(
        description: 'Bilinç düzeyi bozulmuş mu? (GKS < 15)',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Meningizm var mı? (ense sertliği, fotofobi)',
        category: 'O',
        type: _DiscType.yesNo,
        note: 'Kernig / Brudzinski pozitifliği değerlendir',
      ),
      _Discriminator(
        description:
            'Thunderclap başlangıç var mı? (saniyeler içinde maksimum)',
        category: 'O',
        type: _DiscType.yesNo,
        note: 'Subaraknoid kanama ekarte edilmeli',
      ),
      _Discriminator(
        description: 'Yeni nörolojik defisit var mı? (görme/motor/konuşma)',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hot Adult / Hot Child bulgusu var mı?',
        category: 'Y',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'ates',
            label: 'Ateş (°C)',
            min: 35,
            max: 42,
            threshold: 37.5,
            direction: 'ust',
          ),
        ],
      ),
      _Discriminator(
        description: 'Öncesinde bilinç kaybı öyküsü var mı?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Recent Problem',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'No Urgency Indicators',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'n02': _Flowchart(
    group: 'Nörolojik',
    title: 'Nöbet / Konvülsiyon',
    icon: '⚡',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Aktif nöbet (şu an devam ediyor)',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'Uzamış post-iktal (GKS <15)?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Nöbet öyküsü (şu an uyanık, stabil)',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hafif semptom, bilinci açık',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'n03': _Flowchart(
    group: 'Nörolojik',
    title: 'İnme / FAST',
    icon: '🧬',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yeni nörolojik defisit <24 sa (FAST pozitif)?',
        category: 'O',
        type: _DiscType.yesNo,
        note: 'Yüz-Kol-Konuşma. Başlangıç saatini kaydet!',
      ),
      _Discriminator(
        description: 'Bilinç bozukluğu var mı?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Geçirilmiş TİA öyküsü (şu an düzelmiş)?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'n04': _Flowchart(
    group: 'Nörolojik',
    title: 'Bilinç Bozukluğu',
    icon: '💤',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'GKS ≤8 (yanıtsız / sadece ağrıya yanıt)?',
        category: 'R',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 8,
            direction: 'alt',
          ),
        ],
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'GKS 9-14 (orta bilinç bozukluğu)?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
    ],
  ),
  'g01': _Flowchart(
    group: 'Gastrointestinal',
    title: 'Karın Ağrısı (Erişkin)',
    icon: '🩺',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Şok (rüptüre AAA / iç kanama?)',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Exsanguinating haemorrhage var mı?',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Şiddetli ağrı NRS 7-10?',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Severe Pain (7-10) → Turuncu',
      ),
      _Discriminator(
        description: 'Peritonizm var mı? (rebound, defans, rijidite)',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description:
            'Significant vomiting var mı? (kontrolsüz/biliyöz/fekülan)',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Pregnancy complication şüphesi var mı?',
        category: 'O',
        type: _DiscType.yesNo,
        note: 'Ektopik rüptür ekarte edilmeli',
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Altered conscious level var mı?',
        category: 'Y',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Hot Adult (ateş) var mı?',
        category: 'Y',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'ates',
            label: 'Ateş (°C)',
            min: 35,
            max: 42,
            threshold: 37.5,
            direction: 'ust',
          ),
        ],
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Vomiting (mild) var mı?',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Recent Problem',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'No Urgency Indicators',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'g02': _Flowchart(
    group: 'Gastrointestinal',
    title: 'GİS Kanaması',
    icon: '🩸',
    disc: [
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'Masif kanama / eksanjinasyon',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hematemez (kanlı kusmuk)?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Melena (katran dışkı)?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'g03': _Flowchart(
    group: 'Gastrointestinal',
    title: 'Diyare ve Kusma',
    icon: '🤢',
    disc: [
      _Discriminator(
        description: 'Şok / ağır dehidratasyon',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hematemez / kanlı dışkı',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Orta dehidratasyon (kuru mukoza, turgor ↓)?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'r01': _Flowchart(
    group: 'Solunum',
    title: 'Nefes Darlığı (Erişkin)',
    icon: '🫁',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum / apne',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'Severe Pain (NRS 7-10) var mı?',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Severe Pain (7-10) → Turuncu',
      ),
      _Discriminator(
        description: 'Acutely Short of Breath var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Altered conscious level (GKS < 15) var mı?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Plöritik ağrı var mı?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Moderate Pain (NRS 4-6) var mı?',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Moderate Pain (4-6) → Sarı',
      ),
      _Discriminator(
        description: 'Önemli solunum öyküsü (KOAH, astım)?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hemoptizi var mı?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Recent Mild Symptoms',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Recent Problem',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'No Urgency Indicators',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'r02': _Flowchart(
    group: 'Solunum',
    title: 'Astım',
    icon: '💨',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'SpO₂ kritik veya konuşamıyor mu?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'spo2',
            label: 'SpO₂ (%)',
            min: 50,
            max: 100,
            threshold: 90,
            direction: 'alt',
          ),
        ],
      ),
      _Discriminator(
        description: 'Bilinç bozukluğu',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'SpO₂ %90-94 arası (orta bronkospazm)?',
        category: 'Y',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'spo2',
            label: 'SpO₂ (%)',
            min: 50,
            max: 100,
            threshold: 95,
            direction: 'alt',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif wheeze, SpO₂ ≥%95, normal SS',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kronik kontrollü astım, acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  't01': _Flowchart(
    group: 'Travma',
    title: 'Major Travma',
    icon: '🚑',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'GKS ≤8 (bilinçsiz)?',
        category: 'R',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 8,
            direction: 'alt',
          ),
        ],
      ),
      _Discriminator(
        description: 'Masif kontrol edilemeyen kanama?',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'GKS 9-14 (orta bilinç bozukluğu)?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
    ],
  ),
  't02': _Flowchart(
    group: 'Travma',
    title: 'Kafa Travması',
    icon: '🪖',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Aktif nöbet',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'GKS <14?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 14,
            direction: 'alt',
          ),
        ],
      ),
      _Discriminator(
        description: 'Fokal nörolojik defisit var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Bilinç kaybı öyküsü (şu an GKS 15)?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Amnezi var mı?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Minör, acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  't03': _Flowchart(
    group: 'Travma',
    title: 'Ekstremite Problemi',
    icon: '🦵',
    disc: [
      _Discriminator(
        description:
            'Nörovasküler kompromis? (distal nabız yok, renk ↓, his kaybı)',
        category: 'O',
        type: _DiscType.yesNo,
        note: 'Acil vasküler girişim gerekebilir',
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Açık kırık / önemli deformite var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Nörovasküler bütünlük sağlam, deformite yok',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  't04': _Flowchart(
    group: 'Travma',
    title: 'Yanık / Haşlanma',
    icon: '🔥',
    disc: [
      _Discriminator(
        description: 'Hava yolu yanığı / inhalasyon hasarı?',
        category: 'R',
        type: _DiscType.yesNo,
        note: 'Kaş/burun tüyü yanması, ses kısıklığı = inhalasyon',
      ),
      _Discriminator(
        description: '> %25 VKA yanık?',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: '%10-25 VKA yanık?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yüz / eller / genital yanık?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3, minör yanık',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Minör yüzeyel yanık, acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'a01': _Flowchart(
    group: 'Alerji/Sistemik',
    title: 'Anafilaksi / Alerjik Reaksiyon',
    icon: '⚠️',
    disc: [
      _Discriminator(
        description: 'Hava yolu ödemi? (dil/yüz ödemi, stridor)',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description:
            'Anafilaksi triadı: hipotansiyon + ürtiker + solunum sıkıntısı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'Wheeze / bronkospazm var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yaygın anjiyoödem var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Yaygın ürtiker / şiddetli kaşıntı',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Lokal alerjik reaksiyon',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'a02': _Flowchart(
    group: 'Alerji/Sistemik',
    title: 'Diyabet Acili',
    icon: '💉',
    disc: [
      _Discriminator(
        description: 'GKS ≤8 (bilinçsiz)?',
        category: 'R',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 8,
            direction: 'alt',
          ),
        ],
      ),
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kan glukozu?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'glukoz',
            label: 'Kan Glukozu (mg/dL)',
            min: 20,
            max: 600,
            threshold: 70,
            direction: 'alt',
            note: '<70 hipoglisemi',
          ),
        ],
      ),
      _Discriminator(
        description: 'DKA bulguları? (Kussmaul solunumu, meyve kokusu, kusma)',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'GKS 9-14',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Kronik kontrol, stabil',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'a03': _Flowchart(
    group: 'Alerji/Sistemik',
    title: 'Zehirlenme / Aşırı Doz',
    icon: '☠️',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'GKS ≤8 / yanıtsız?',
        category: 'R',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 8,
            direction: 'alt',
          ),
        ],
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Aktif nöbet',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Şok / hemodinamik instabilite',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'GKS 9-14 (orta bilinç bozukluğu)?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Kardiyak aritmi var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif semptom, stabil',
        category: 'G',
        type: _DiscType.yesNo,
      ),
    ],
  ),
  'a04': _Flowchart(
    group: 'Alerji/Sistemik',
    title: 'Hasta Erişkin (Genel)',
    icon: '🧑‍⚕️',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'GKS <15?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Ateş ≥38.5°C (akut)?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'ates',
            label: 'Ateş (°C)',
            min: 35,
            max: 42,
            threshold: 38.5,
            direction: 'ust',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Ateş 37.5-38.4°C?',
        category: 'Y',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'ates',
            label: 'Ateş (°C)',
            min: 35,
            max: 42,
            threshold: 37.5,
            direction: 'ust',
          ),
        ],
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'a05': _Flowchart(
    group: 'Alerji/Sistemik',
    title: 'Hasta Çocuk',
    icon: '👧',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Yetersiz solunum',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Şok (soluk, taşikardi, kapiller dolum >3 sn)',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'GKS <15?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Solunum sıkıntısı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Sıcak çocuk (ateş) — <3 ay ise HERHANGİ ateş → Turuncu!',
        category: 'O',
        type: _DiscType.yesNo,
        note: '<3 ay çocukta her ateş Turuncu\'dur',
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Yüksek ateş >39°C?',
        category: 'Y',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'ates',
            label: 'Ateş (°C)',
            min: 35,
            max: 42,
            threshold: 39,
            direction: 'ust',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif semptom',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'p01': _Flowchart(
    group: 'Psikiyatri',
    title: 'Psikiyatrik Problem / Kendine Zarar',
    icon: '🧩',
    disc: [
      _Discriminator(
        description: 'Aktif intihar girişimi + ciddi fiziksel yaralanma?',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kendine / başkasına yönelik aktif şiddet riski yüksek?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'GKS <15?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Akut psikoz (halüsinasyon, sanrı) var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'İntihar planı + niyeti var mı?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ajitasyon / kontrol edilemeyen davranış?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'İntihar düşüncesi (plan/girişim yok)?',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Hafif emosyonel distres',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kronik, stabil psikiyatrik şikayet',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'e01': _Flowchart(
    group: 'Göz/KBB',
    title: 'Göz Problemi',
    icon: '👁️',
    disc: [
      _Discriminator(
        description: 'Gözde kimyasal maruz kalma (asit/alkali)?',
        category: 'R',
        type: _DiscType.yesNo,
        note: 'Triajı beklemeden irrigasyon başlat!',
      ),
      _Discriminator(
        description: 'Penetran göz yaralanması?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ani görme kaybı?',
        category: 'O',
        type: _DiscType.yesNo,
        note: 'Santral retinal arter tıkanması / dekolman',
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı / kızarıklık / yabancı cisim',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'e02': _Flowchart(
    group: 'Göz/KBB',
    title: 'Boğaz / Hava Yolu Tehlikesi',
    icon: '🗣️',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı? (peritonsillar apse, epiglottit)',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ciddi disfaji (yutamıyor, sekresyon akıyor)?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'd01': _Flowchart(
    group: 'Cilt/Döküntü',
    title: 'Döküntü / Alerjik Cilt',
    icon: '🔴',
    disc: [
      _Discriminator(
        description: 'Yaygın peteşi / purpura (menenjokoksemi?)?',
        category: 'R',
        type: _DiscType.yesNo,
        note: 'Ateş + peteşi = sepsis ekarte edilmeli',
      ),
      _Discriminator(
        description: 'Anafilaksi bulguları (şok + ürtiker + solunum)?',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'GKS <15?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı / kaşıntı',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'ob01': _Flowchart(
    group: 'Kadın Doğum/ÜR',
    title: 'Gebelik Problemi',
    icon: '🤰',
    disc: [
      _Discriminator(
        description: 'Hava yolu tıkanıklığı',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Şok (rüptüre ektopik?)',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Aktif nöbet (eklampsi)?',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Vajinal hemoraji (stabil)?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Olası erken doğum?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'ob02': _Flowchart(
    group: 'Kadın Doğum/ÜR',
    title: 'İdrar Yolu Problemi',
    icon: '🫗',
    disc: [
      _Discriminator(description: 'Şok', category: 'R', type: _DiscType.yesNo),
      _Discriminator(
        description: 'Renal kolik: ağrı NRS ≥7',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Şiddetli → Turuncu',
      ),
      _Discriminator(
        description: 'Tam idrar retansiyonu (hiç yapamıyor)?',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'GKS <15?',
        category: 'O',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'gks',
            label: 'GKS (3-15)',
            min: 3,
            max: 15,
            threshold: 15,
            direction: 'alt_esik',
          ),
        ],
      ),
      _Discriminator(
        description: 'Ağrı NRS 4-6',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Orta → Sarı',
      ),
      _Discriminator(
        description: 'Ateş + idrar şikayeti (piyelonefrit?)',
        category: 'Y',
        type: _DiscType.vital,
        fields: [
          _VitalField(
            key: 'ates',
            label: 'Ateş (°C)',
            min: 35,
            max: 42,
            threshold: 37.5,
            direction: 'ust',
          ),
        ],
      ),
      _Discriminator(
        description: 'Hafif ağrı NRS 1-3',
        category: 'G',
        type: _DiscType.nrs,
        thresholdLow: 1,
        thresholdHigh: 3,
        badge: 'Hafif → Yeşil',
      ),
      _Discriminator(
        description: 'Kronik / acil bulgu yok',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'r03': _Flowchart(
    group: 'Solunum',
    title: 'Nefes Darlığı (Çocuk)',
    icon: '🧒',
    disc: [
      _Discriminator(
        description: 'Airway Compromise',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Inadequate Breathing',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Shock',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Grunting',
        category: 'R',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Severe Pain (NRS 7-10)',
        category: 'O',
        type: _DiscType.nrs,
        threshold: 7,
        badge: 'Severe Pain (7-10) → Turuncu',
      ),
      _Discriminator(
        description: 'Acutely Short of Breath',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Very Abnormal Resp Rate',
        category: 'O',
        type: _DiscType.yesNo,
        note: '>70/dk (<1 yaş) veya >50/dk (1-5 yaş)',
      ),
      _Discriminator(
        description: 'Hot Child',
        category: 'O',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Moderate Pain (NRS 4-6)',
        category: 'Y',
        type: _DiscType.nrs,
        thresholdLow: 4,
        thresholdHigh: 6,
        badge: 'Moderate Pain (4-6) → Sarı',
      ),
      _Discriminator(
        description: 'Abnormal Respiratory Rate',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Significant Respiratory History',
        category: 'Y',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Recent Mild Symptoms',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'Recent Problem',
        category: 'G',
        type: _DiscType.yesNo,
      ),
      _Discriminator(
        description: 'No Urgency Indicators',
        category: 'B',
        type: _DiscType.yesNo,
        isFinal: true,
      ),
    ],
  ),
  'n05': _summaryFlowchart(
    group: 'Nörolojik',
    title: 'Nörolojik Problemler',
    icon: '🧩',
    orange: const [
      'Akut fokal nörolojik defisit var mı?',
      'Ani başlangıçlı nörolojik yakınma var mı?',
      'Bilinç değişikliği (GKS < 15) var mı?',
    ],
    red: const [],
    yellow: const ['History of Unconsciousness'],
  ),
  'n07': _summaryFlowchart(
    group: 'Nörolojik',
    title: 'Yanıtsız Çocuk',
    icon: '🆘',
    red: const ['Unresponsive Child (hiçbir uyarana yanıt yok)'],
    orange: const ['Altered Conscious Level'],
    yellow: const ['Hot Child'],
    includePain: false,
  ),
  'g04': _summaryFlowchart(
    group: 'Gastrointestinal',
    title: 'Karın Ağrısı (Çocuk)',
    icon: '🧒',
    red: const ['Ciddi solunum sıkıntısı / ağır dehidratasyon var mı?'],
    orange: const [
      'Peritonism var mı?',
      'Şiddetli karın ağrısı var mı?',
      'Akut kötüleşme bulguları var mı?',
    ],
    yellow: const ['Hot Child'],
  ),
  'g05': _summaryFlowchart(
    group: 'Gastrointestinal',
    title: 'Rektal Problemler',
    icon: '🩹',
    red: const ['Masif kanama var mı?'],
    orange: const ['Anlamlı rektal kanama var mı?', 'Peritonism var mı?'],
    yellow: const ['Kanama tekrarlıyor mu?'],
  ),
  'gu01': _summaryFlowchart(
    group: 'Kadın Doğum/ÜR',
    title: 'Testis Ağrısı',
    icon: '⚕️',
    red: const [],
    orange: const ['Ani başlangıç + şiddetli ağrı (torsiyon?)'],
    yellow: const ['Süregelen orta şiddet ağrı'],
  ),
  'gu02': _summaryFlowchart(
    group: 'Kadın Doğum/ÜR',
    title: 'Cinsel Saldırı',
    icon: '🛡️',
    red: const ['Şok veya ağır fiziksel yaralanma var mı?'],
    orange: const [
      'Altered conscious level var mı?',
      'Ciddi travma bulgusu var mı?',
    ],
    yellow: const ['Psikolojik kriz / güvenlik riski var mı?'],
    includePain: false,
  ),
  't05': _summaryFlowchart(
    group: 'Travma',
    title: 'Sırt Ağrısı',
    icon: '🦴',
    red: const [],
    orange: const [
      'Cauda equina bulguları var mı?',
      'Nörolojik defisit var mı?',
    ],
    yellow: const ['Yürüme kısıtlılığı veya radiküler ağrı var mı?'],
  ),
  't06': _summaryFlowchart(
    group: 'Travma',
    title: 'Minör Travma',
    icon: '🩼',
    red: const [],
    orange: const ['Nörovasküler kompromis var mı?'],
    yellow: const ['Deformite olmadan kırık şüphesi var mı?'],
  ),
  't07': _summaryFlowchart(
    group: 'Travma',
    title: 'Yaralar',
    icon: '🩹',
    red: const ['Exsanguinating haemorrhage var mı?'],
    orange: const ['Damar/sinir yaralanması şüphesi var mı?'],
    yellow: const ['Sütür gerektiren derin kesi var mı?'],
  ),
  't08': _summaryFlowchart(
    group: 'Travma',
    title: 'Düşmeler',
    icon: '🪜',
    red: const ['Düşme sonrası bilinç kapalı mı?'],
    orange: const ['Nörolojik defisit var mı?', 'Şiddetli ağrı var mı?'],
    yellow: const ['History of Unconsciousness'],
  ),
  'h01': _summaryFlowchart(
    group: 'Göz/KBB',
    title: 'Boyun Ağrısı',
    icon: '🦴',
    red: const [],
    orange: const [
      'Travma sonrası instabilite şüphesi var mı?',
      'Nörolojik defisit var mı?',
    ],
    yellow: const ['Orta derecede ağrı/hareket kısıtı var mı?'],
  ),
  'h02': _summaryFlowchart(
    group: 'Göz/KBB',
    title: 'Yüz Problemleri',
    icon: '🙂',
    red: const ['Airway threat var mı?', 'Aktif majör yüz kanaması var mı?'],
    orange: const ['Yüz kırığı şüphesi var mı?'],
    yellow: const ['Orta şiddet ağrı veya şişlik var mı?'],
  ),
  'h03': _summaryFlowchart(
    group: 'Göz/KBB',
    title: 'Kulak Problemleri',
    icon: '👂',
    red: const [],
    orange: const ['Ani işitme kaybı var mı?', 'Mastoidit bulguları var mı?'],
    yellow: const ['Orta şiddet ağrı/ateş var mı?'],
  ),
  'h04': _summaryFlowchart(
    group: 'Göz/KBB',
    title: 'Dental Problemler',
    icon: '🦷',
    red: const [],
    orange: const ['Yayılan selülit/apse var mı?'],
    yellow: const ['Orta şiddet ağrı + çiğneme güçlüğü var mı?'],
  ),
  'd02': _summaryFlowchart(
    group: 'Cilt/Döküntü',
    title: 'Apse ve Lokal Enfeksiyon',
    icon: '🧫',
    red: const ['Sistemik sepsis bulguları var mı?'],
    orange: const ['Şiddetli ağrı veya yaygın selülit var mı?'],
    yellow: const ['Ateş + lokal enfeksiyon bulgusu var mı?'],
  ),
  'd03': _summaryFlowchart(
    group: 'Cilt/Döküntü',
    title: 'Isırık ve Sokma',
    icon: '🐝',
    red: const ['Anafilaksi / airway ödemi var mı?', 'Şok bulguları var mı?'],
    orange: const ['Sistemik toksisite bulguları var mı?'],
    yellow: const ['Genişleyen lokal reaksiyon var mı?'],
  ),
  'a06': _summaryFlowchart(
    group: 'Alerji/Sistemik',
    title: 'Ebeveyn Endişesi / Worried Parent',
    icon: '👪',
    red: const ['Çocukta yanıtsızlık veya ağır solunum sıkıntısı var mı?'],
    orange: const ['Ebeveynin ciddi klinik kötüleşme endişesi var mı?'],
    yellow: const ['Beslenme/hidrasyon bozulması var mı?'],
    includePain: false,
  ),
  'p02': _summaryFlowchart(
    group: 'Psikiyatri',
    title: 'Anormal Davranış',
    icon: '⚠️',
    red: const [],
    orange: const [
      'Kendine/çevreye aktif zarar riski var mı?',
      'Kontrolsüz ajitasyon var mı?',
    ],
    yellow: const ['De-eskalasyon gerektiren ajitasyon var mı?'],
    includePain: false,
  ),
  'p03': _summaryFlowchart(
    group: 'Psikiyatri',
    title: 'Kendine Zarar (Self-Harm)',
    icon: '🧠',
    red: const ['Ciddi fiziksel yaralanma ile aktif girişim var mı?'],
    orange: const ['İntihar planı + niyeti var mı?'],
    yellow: const ['İntihar düşüncesi var mı?'],
    includePain: false,
  ),
  's01': _summaryFlowchart(
    group: 'Çevresel/Özel',
    title: 'Majör Olay',
    icon: '🚨',
    red: const ['Toplu olayda yaşamı tehdit eden bulgu var mı?'],
    orange: const [
      'Hızla kötüleşebilecek ciddi travma/solunum bulgusu var mı?',
    ],
    yellow: const ['Gecikmeye duyarlı yaralanma var mı?'],
  ),
  's02': _summaryFlowchart(
    group: 'Çevresel/Özel',
    title: 'Kimyasal Olay',
    icon: '☣️',
    red: const ['Airway compromise veya sistemik toksisite var mı?'],
    orange: const ['Kimyasal maruziyet sonrası semptomatik hasta var mı?'],
    yellow: const ['Dekontaminasyon sonrası orta semptom devam ediyor mu?'],
    includePain: false,
  ),
  's03': _summaryFlowchart(
    group: 'Çevresel/Özel',
    title: 'Maruziyet (Sıcak/Soğuk)',
    icon: '🌡️',
    red: const ['Ağır hipertermi/hipotermi bulguları var mı?'],
    orange: const ['Altered consciousness veya ciddi dehidratasyon var mı?'],
    yellow: const ['Orta derecede ısı etkilenimi var mı?'],
    includePain: false,
  ),
  's04': _summaryFlowchart(
    group: 'Çevresel/Özel',
    title: 'Belirsiz Başvuru (No Obvious Presentation)',
    icon: '❔',
    red: const [],
    orange: const ['Genel discriminator ile yüksek risk bulgusu var mı?'],
    yellow: const [
      'Spesifik olmayan ancak kötüleşme riski olan semptom var mı?',
    ],
  ),
};
