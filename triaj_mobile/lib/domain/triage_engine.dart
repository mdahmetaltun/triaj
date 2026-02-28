import 'package:flutter/material.dart';

import 'triage_catalog.dart';
import 'triage_models.dart';

class TriageEngine {
  static TriageComparison evaluate(Set<String> selectedFindingIds) {
    final stsResult = _evaluateSTS(selectedFindingIds);
    final mtsResult = _evaluateMTS(selectedFindingIds);
    return TriageComparison(sts: stsResult, mts: mtsResult);
  }

  static TriageResult _evaluateSTS(Set<String> selectedFindingIds) {
    return _evaluateWithRules(
      system: TriageSystem.sts,
      selectedFindingIds: selectedFindingIds,
      orderedRules: _stsOrderedRules,
      emptySelectionCategory: _stsGreen,
      emptySelectionRule: 'Veri Yok',
      emptySelectionRationale:
          'Klinik bulgu seçilmediği için otomatik sınıflama yapılmadı. '
          'Triyaj için en az bir bulgu seçiniz.',
      fallbackCategory: _stsYellow2,
      fallbackRule: 'STS Güvenli Üst Kategori Kuralı',
      fallbackRationale:
          'Seçilen bulgular STS adımlarında birebir eşleşmedi. '
          'Riskten kaçınma yaklaşımı ile SARI Kategori 2 önerildi.',
    );
  }

  static TriageResult _evaluateMTS(Set<String> selectedFindingIds) {
    return _evaluateWithRules(
      system: TriageSystem.mts,
      selectedFindingIds: selectedFindingIds,
      orderedRules: _mtsOrderedRules,
      emptySelectionCategory: _mtsBlue,
      emptySelectionRule: 'No Urgency Indicators',
      emptySelectionRationale:
          'Bulgu girilmediği için MTS varsayılan olarak non-urgent kabul edildi.',
      fallbackCategory: _mtsYellow,
      fallbackRule: 'MTS Risk-Averse Rule',
      fallbackRationale:
          'Bulgu eşleşmesi sınırlı kaldı. MTS riskten kaçınma prensibi ile '
          'daha üst aciliyet kategorisi seçildi.',
    );
  }

  static TriageResult _evaluateWithRules({
    required TriageSystem system,
    required Set<String> selectedFindingIds,
    required List<_Rule> orderedRules,
    required TriageCategory emptySelectionCategory,
    required String emptySelectionRule,
    required String emptySelectionRationale,
    required TriageCategory fallbackCategory,
    required String fallbackRule,
    required String fallbackRationale,
  }) {
    if (selectedFindingIds.isEmpty) {
      return TriageResult(
        system: system,
        category: emptySelectionCategory,
        decisionRule: emptySelectionRule,
        rationale: emptySelectionRationale,
        triggeredFindings: const [],
        recommendation: _buildRecommendation(system, emptySelectionCategory),
      );
    }

    for (final rule in orderedRules) {
      final matchedIds = selectedFindingIds.intersection(rule.findingIds);
      if (matchedIds.isNotEmpty) {
        return TriageResult(
          system: system,
          category: rule.category,
          decisionRule: rule.name,
          rationale: rule.rationale,
          triggeredFindings: _toFindings(matchedIds),
          recommendation: _buildRecommendation(system, rule.category),
        );
      }
    }

    return TriageResult(
      system: system,
      category: fallbackCategory,
      decisionRule: fallbackRule,
      rationale: fallbackRationale,
      triggeredFindings: _toFindings(selectedFindingIds),
      recommendation: _buildRecommendation(system, fallbackCategory),
    );
  }

  static List<ClinicalFinding> _toFindings(Set<String> findingIds) {
    return triageFindings
        .where((finding) => findingIds.contains(finding.id))
        .toList();
  }

  static String _buildRecommendation(
    TriageSystem system,
    TriageCategory category,
  ) {
    final area = category.zone;
    if (category.rank == 1) {
      return '$area: Eş zamanlı değerlendirme ve tedavi başlatın.';
    }
    if (category.rank == 2) {
      return '$area: Maksimum ${category.maxWaitMinutes} dakika içinde hekim değerlendirmesi.';
    }
    if (category.rank == 3) {
      return '$area: Klinik kötüleşme açısından yakın izlem ve retriyaj.';
    }
    if (category.rank == 4) {
      return '$area: Bekleme sırasında vital değişim olursa retriyaj.';
    }
    if (system == TriageSystem.mts) {
      return '$area: Non-urgent süreçte semptom artışında yeniden değerlendirin.';
    }
    return '$area: Ayaktan süreçte bilgilendirme ve uygun poliklinik yönlendirmesi.';
  }
}

class _Rule {
  const _Rule({
    required this.name,
    required this.rationale,
    required this.category,
    required this.findingIds,
  });

  final String name;
  final String rationale;
  final TriageCategory category;
  final Set<String> findingIds;
}

const TriageCategory _stsRed1 = TriageCategory(
  rank: 1,
  code: 'KIRMIZI K1',
  name: 'Resüsitasyon / Hemen Müdahale',
  zone: 'Kırmızı Alan',
  maxWaitMinutes: 0,
  color: Color(0xFFC62828),
);

const TriageCategory _stsRed2 = TriageCategory(
  rank: 2,
  code: 'KIRMIZI K2',
  name: 'Yüksek Riskli Acil',
  zone: 'Kırmızı Alan',
  maxWaitMinutes: 10,
  color: Color(0xFFEF6C00),
);

const TriageCategory _stsYellow1 = TriageCategory(
  rank: 3,
  code: 'SARI K1',
  name: 'Ciddi / Öncelikli',
  zone: 'Sarı Alan',
  maxWaitMinutes: 30,
  color: Color(0xFFF9A825),
);

const TriageCategory _stsYellow2 = TriageCategory(
  rank: 4,
  code: 'SARI K2',
  name: 'Yarı Acil',
  zone: 'Sarı Alan',
  maxWaitMinutes: 60,
  color: Color(0xFFFDD835),
);

const TriageCategory _stsGreen = TriageCategory(
  rank: 5,
  code: 'YEŞİL',
  name: 'Acil Olmayan',
  zone: 'Yeşil Alan',
  maxWaitMinutes: 120,
  color: Color(0xFF2E7D32),
);

const TriageCategory _mtsRed = TriageCategory(
  rank: 1,
  code: 'RED',
  name: 'Immediate',
  zone: 'Resuscitation',
  maxWaitMinutes: 0,
  color: Color(0xFFC62828),
);

const TriageCategory _mtsOrange = TriageCategory(
  rank: 2,
  code: 'ORANGE',
  name: 'Very Urgent',
  zone: 'Very Urgent Area',
  maxWaitMinutes: 10,
  color: Color(0xFFEF6C00),
);

const TriageCategory _mtsYellow = TriageCategory(
  rank: 3,
  code: 'YELLOW',
  name: 'Urgent',
  zone: 'Urgent Area',
  maxWaitMinutes: 60,
  color: Color(0xFFF9A825),
);

const TriageCategory _mtsGreen = TriageCategory(
  rank: 4,
  code: 'GREEN',
  name: 'Standard',
  zone: 'Standard Area',
  maxWaitMinutes: 120,
  color: Color(0xFF2E7D32),
);

const TriageCategory _mtsBlue = TriageCategory(
  rank: 5,
  code: 'BLUE',
  name: 'Non-Urgent',
  zone: 'Minor Area',
  maxWaitMinutes: 240,
  color: Color(0xFF1565C0),
);

const List<_Rule> _stsOrderedRules = [
  _Rule(
    name: 'STS Adım 1 - Hayatı Tehdit Eden Durum',
    rationale:
        'Hastada hiç bekletilmeden eş zamanlı müdahale gerektiren kritik '
        'bulgular mevcut.',
    category: _stsRed1,
    findingIds: {
      FindingIds.cardiacRespArrest,
      FindingIds.airwayCompromise,
      FindingIds.inadequateBreathing,
      FindingIds.majorTrauma,
      FindingIds.shockOrHypotension,
      FindingIds.unresponsiveOrPainOnly,
      FindingIds.activeSeizure,
    },
  ),
  _Rule(
    name: 'STS Adım 2 - Yüksek Risk Değerlendirmesi',
    rationale:
        'Hayatı tehdit etme olasılığı yüksek ve 10 dakika içinde müdahale '
        'gerektiren bulgular saptandı.',
    category: _stsRed2,
    findingIds: {
      FindingIds.cardiacChestPain,
      FindingIds.severeDyspneaO2Low,
      FindingIds.circulationFailure,
      FindingIds.acuteStrokeSigns,
      FindingIds.majorFractureOrAmputation,
      FindingIds.toxicOverdose,
      FindingIds.violentPsychiatricRisk,
      FindingIds.chemicalEyeExposure,
      FindingIds.dangerToSelfOthers,
    },
  ),
  _Rule(
    name: 'STS Adım 3 - Ciddi / Acil Durum',
    rationale:
        'Önemli morbidite veya uzuv kaybı riski taşıyan ciddi klinik durum '
        'bulguları mevcut.',
    category: _stsYellow1,
    findingIds: {
      FindingIds.criticalHypertension,
      FindingIds.severeAbdominalPain,
      FindingIds.elderlyAbdominalPain,
      FindingIds.moderateBloodLoss,
      FindingIds.headTraumaWithAmnesia,
      FindingIds.immunosuppressedFever,
      FindingIds.persistentVomiting,
      FindingIds.seriousExtremityInjury,
      FindingIds.peritonism,
      FindingIds.meningismThunderclap,
    },
  ),
  _Rule(
    name: 'STS Adım 4 - Yarı Acil Durum',
    rationale:
        'Orta düzey riskli ve bekleme sırasında yakın takip gerektiren '
        'klinik bulgular saptandı.',
    category: _stsYellow2,
    findingIds: {
      FindingIds.simpleBleeding,
      FindingIds.mildAbdominalPain,
      FindingIds.swallowingDifficulty,
      FindingIds.minorHeadTrauma,
      FindingIds.minorChestTrauma,
      FindingIds.vomitDiarrheaNoDehydration,
      FindingIds.minorExtremityTrauma,
      FindingIds.moderatePainNrs46,
      FindingIds.hotAdult,
      FindingIds.historyUnconsciousness,
    },
  ),
  _Rule(
    name: 'STS Adım 5 - Acil Olmayan Durum',
    rationale:
        'Ayaktan tedavi ile yönetilebilecek düşük riskli bulgular ön planda.',
    category: _stsGreen,
    findingIds: {
      FindingIds.mildPainNrs13,
      FindingIds.superficialWound,
      FindingIds.chronicStableComplaint,
      FindingIds.mildBehavioralSymptoms,
    },
  ),
];

const List<_Rule> _mtsOrderedRules = [
  _Rule(
    name: 'MTS General Discriminator - RED',
    rationale:
        'Airway, breathing, circulation veya bilinç düzeyi açısından '
        'anında müdahale gerektiren kırmızı discriminator eşleşti.',
    category: _mtsRed,
    findingIds: {
      FindingIds.cardiacRespArrest,
      FindingIds.airwayCompromise,
      FindingIds.inadequateBreathing,
      FindingIds.shockOrHypotension,
      FindingIds.activeSeizure,
      FindingIds.unresponsiveOrPainOnly,
      FindingIds.majorTrauma,
    },
  ),
  _Rule(
    name: 'MTS General/Specific Discriminator - ORANGE',
    rationale:
        'Hızlı kötüleşme riski taşıyan yüksek öncelikli MTS discriminator '
        'eşleşti.',
    category: _mtsOrange,
    findingIds: {
      FindingIds.severePainNrs710,
      FindingIds.cardiacChestPain,
      FindingIds.severeDyspneaO2Low,
      FindingIds.circulationFailure,
      FindingIds.acuteStrokeSigns,
      FindingIds.majorFractureOrAmputation,
      FindingIds.toxicOverdose,
      FindingIds.violentPsychiatricRisk,
      FindingIds.hotChild,
      FindingIds.veryHotAdult,
      FindingIds.chemicalEyeExposure,
      FindingIds.dangerToSelfOthers,
      FindingIds.peritonism,
      FindingIds.meningismThunderclap,
    },
  ),
  _Rule(
    name: 'MTS General Discriminator - YELLOW',
    rationale:
        'Hastada acil değerlendirme gerektiren ancak anlık yaşam tehdidi '
        'olmayan sarı düzey discriminator bulundu.',
    category: _mtsYellow,
    findingIds: {
      FindingIds.moderatePainNrs46,
      FindingIds.moderateBloodLoss,
      FindingIds.historyUnconsciousness,
      FindingIds.hotAdult,
      FindingIds.headTraumaWithAmnesia,
      FindingIds.severeAbdominalPain,
      FindingIds.elderlyAbdominalPain,
      FindingIds.immunosuppressedFever,
      FindingIds.persistentVomiting,
      FindingIds.seriousExtremityInjury,
      FindingIds.criticalHypertension,
    },
  ),
  _Rule(
    name: 'MTS General Discriminator - GREEN',
    rationale:
        'Hastada düşük aciliyetli, bekleyebilen standard düzey bulgular '
        'ön planda.',
    category: _mtsGreen,
    findingIds: {
      FindingIds.mildPainNrs13,
      FindingIds.simpleBleeding,
      FindingIds.mildAbdominalPain,
      FindingIds.swallowingDifficulty,
      FindingIds.minorHeadTrauma,
      FindingIds.minorChestTrauma,
      FindingIds.vomitDiarrheaNoDehydration,
      FindingIds.minorExtremityTrauma,
      FindingIds.superficialWound,
      FindingIds.chronicStableComplaint,
      FindingIds.mildBehavioralSymptoms,
    },
  ),
];
