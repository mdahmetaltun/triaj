import 'package:flutter/material.dart';

enum TriageSystem {
  sts,
  mts;

  String get label {
    switch (this) {
      case TriageSystem.sts:
        return 'Sağlık Bakanlığı (STS)';
      case TriageSystem.mts:
        return 'Manchester Triage (MTS)';
    }
  }
}

enum FindingGroup {
  primary,
  circulation,
  neurological,
  trauma,
  painAndFever,
  gastrointestinal,
  toxicAndPsych,
  minorCare,
}

extension FindingGroupLabel on FindingGroup {
  String get label {
    switch (this) {
      case FindingGroup.primary:
        return 'Birincil Değerlendirme';
      case FindingGroup.circulation:
        return 'Dolaşım / Solunum';
      case FindingGroup.neurological:
        return 'Nörolojik';
      case FindingGroup.trauma:
        return 'Travma';
      case FindingGroup.painAndFever:
        return 'Ağrı / Ateş';
      case FindingGroup.gastrointestinal:
        return 'Gastrointestinal';
      case FindingGroup.toxicAndPsych:
        return 'Toksikoloji / Psikiyatri';
      case FindingGroup.minorCare:
        return 'Düşük Risk';
    }
  }
}

class ClinicalFinding {
  const ClinicalFinding({
    required this.id,
    required this.title,
    required this.description,
    required this.group,
  });

  final String id;
  final String title;
  final String description;
  final FindingGroup group;
}

class TriageCategory {
  const TriageCategory({
    required this.rank,
    required this.code,
    required this.name,
    required this.zone,
    required this.maxWaitMinutes,
    required this.color,
  });

  final int rank;
  final String code;
  final String name;
  final String zone;
  final int maxWaitMinutes;
  final Color color;
}

class TriageResult {
  const TriageResult({
    required this.system,
    required this.category,
    required this.decisionRule,
    required this.rationale,
    required this.triggeredFindings,
    required this.recommendation,
  });

  final TriageSystem system;
  final TriageCategory category;
  final String decisionRule;
  final String rationale;
  final List<ClinicalFinding> triggeredFindings;
  final String recommendation;

  Set<String> get triggeredIds =>
      triggeredFindings.map((finding) => finding.id).toSet();
}

class TriageComparison {
  const TriageComparison({required this.sts, required this.mts});

  final TriageResult sts;
  final TriageResult mts;

  int get urgencyGap => sts.category.rank - mts.category.rank;

  int get urgencyGapAbs => urgencyGap.abs();

  bool get isAligned => urgencyGap == 0;

  bool get majorMismatch => urgencyGapAbs >= 2;

  TriageResult get recommended =>
      sts.category.rank <= mts.category.rank ? sts : mts;

  String get mismatchSummary {
    if (isAligned) {
      return 'Her iki sistem aynı aciliyet seviyesinde.';
    }

    if (sts.category.rank < mts.category.rank) {
      return 'STS, MTS sistemine göre daha acil sınıfladı.';
    }

    return 'MTS, STS sistemine göre daha acil sınıfladı.';
  }
}

class ScenarioPreset {
  const ScenarioPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.findingIds,
  });

  final String id;
  final String title;
  final String description;
  final Set<String> findingIds;
}
