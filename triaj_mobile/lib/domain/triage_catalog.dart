import 'triage_models.dart';

class FindingIds {
  static const cardiacRespArrest = 'cardiac_resp_arrest';
  static const airwayCompromise = 'airway_compromise';
  static const inadequateBreathing = 'inadequate_breathing';
  static const majorTrauma = 'major_trauma';
  static const shockOrHypotension = 'shock_or_hypotension';
  static const unresponsiveOrPainOnly = 'unresponsive_or_pain_only';
  static const activeSeizure = 'active_seizure';

  static const cardiacChestPain = 'cardiac_chest_pain';
  static const severeDyspneaO2Low = 'severe_dyspnea_o2_low';
  static const circulationFailure = 'circulation_failure';
  static const acuteStrokeSigns = 'acute_stroke_signs';
  static const majorFractureOrAmputation = 'major_fracture_or_amputation';
  static const toxicOverdose = 'toxic_overdose';
  static const violentPsychiatricRisk = 'violent_psychiatric_risk';

  static const severeAbdominalPain = 'severe_abdominal_pain';
  static const elderlyAbdominalPain = 'elderly_abdominal_pain';
  static const criticalHypertension = 'critical_hypertension';
  static const moderateBloodLoss = 'moderate_blood_loss';
  static const headTraumaWithAmnesia = 'head_trauma_with_amnesia';
  static const immunosuppressedFever = 'immunosuppressed_fever';
  static const persistentVomiting = 'persistent_vomiting';
  static const seriousExtremityInjury = 'serious_extremity_injury';

  static const simpleBleeding = 'simple_bleeding';
  static const mildAbdominalPain = 'mild_abdominal_pain';
  static const swallowingDifficulty = 'swallowing_difficulty';
  static const minorHeadTrauma = 'minor_head_trauma';
  static const minorChestTrauma = 'minor_chest_trauma';
  static const vomitDiarrheaNoDehydration = 'vomit_diarrhea_no_dehydration';
  static const minorExtremityTrauma = 'minor_extremity_trauma';

  static const severePainNrs710 = 'severe_pain_nrs_7_10';
  static const moderatePainNrs46 = 'moderate_pain_nrs_4_6';
  static const mildPainNrs13 = 'mild_pain_nrs_1_3';
  static const hotChild = 'hot_child';
  static const veryHotAdult = 'very_hot_adult';
  static const historyUnconsciousness = 'history_unconsciousness';
  static const hotAdult = 'hot_adult';

  static const peritonism = 'peritonism';
  static const meningismThunderclap = 'meningism_thunderclap';
  static const chemicalEyeExposure = 'chemical_eye_exposure';
  static const dangerToSelfOthers = 'danger_to_self_others';

  static const superficialWound = 'superficial_wound';
  static const chronicStableComplaint = 'chronic_stable_complaint';
  static const mildBehavioralSymptoms = 'mild_behavioral_symptoms';
}

const List<ClinicalFinding> triageFindings = [
  ClinicalFinding(
    id: FindingIds.cardiacRespArrest,
    title: 'Kardiyak / solunumsal arrest',
    description: 'Nabız yokluğu, apne veya arrest tablosu.',
    group: FindingGroup.primary,
  ),
  ClinicalFinding(
    id: FindingIds.airwayCompromise,
    title: 'Havayolu tehditi / obstruksiyon',
    description: 'Stridor, yabancı cisim, tam veya yakın tam tıkanma.',
    group: FindingGroup.primary,
  ),
  ClinicalFinding(
    id: FindingIds.inadequateBreathing,
    title: 'Yetersiz solunum',
    description: 'Apne, ciddi hipoventilasyon veya solunum sayısı çok düşük.',
    group: FindingGroup.primary,
  ),
  ClinicalFinding(
    id: FindingIds.majorTrauma,
    title: 'Majör travma / çoklu travma',
    description: 'Hayatı tehdit eden çoklu travma bulguları.',
    group: FindingGroup.trauma,
  ),
  ClinicalFinding(
    id: FindingIds.shockOrHypotension,
    title: 'Şok veya ciddi hipotansiyon',
    description: 'Sistolik <80 mmHg veya perfüzyon bozukluğu.',
    group: FindingGroup.circulation,
  ),
  ClinicalFinding(
    id: FindingIds.unresponsiveOrPainOnly,
    title: 'Yanıtsız veya sadece ağrıya yanıt',
    description: 'Bilinç düzeyinde kritik düşüş.',
    group: FindingGroup.neurological,
  ),
  ClinicalFinding(
    id: FindingIds.activeSeizure,
    title: 'Aktif / uzamış nöbet',
    description: 'Triyaj anında devam eden ya da uzamış konvülziyon.',
    group: FindingGroup.neurological,
  ),
  ClinicalFinding(
    id: FindingIds.cardiacChestPain,
    title: 'Kardiyak özellikli göğüs ağrısı',
    description:
        'Basıcı ağrı, kola/çeneye yayılım, akut koroner sendrom şüphesi.',
    group: FindingGroup.circulation,
  ),
  ClinicalFinding(
    id: FindingIds.severeDyspneaO2Low,
    title: 'Ciddi nefes darlığı / O2 < %90',
    description: 'Yardımcı solunum kası kullanımı veya belirgin hipoksemi.',
    group: FindingGroup.circulation,
  ),
  ClinicalFinding(
    id: FindingIds.circulationFailure,
    title: 'Dolaşım instabilitesi',
    description: 'Kalp hızı <50 veya >150, soğuk nemli deri, hipotansiyon.',
    group: FindingGroup.circulation,
  ),
  ClinicalFinding(
    id: FindingIds.acuteStrokeSigns,
    title: 'Akut nörolojik defisit (inme bulgusu)',
    description: 'Hemiparezi, disfazi veya yeni fokal defisit.',
    group: FindingGroup.neurological,
  ),
  ClinicalFinding(
    id: FindingIds.majorFractureOrAmputation,
    title: 'Majör kırık / ampütasyon',
    description: 'Uzuv kaybı riski veya açık ciddi kırık.',
    group: FindingGroup.trauma,
  ),
  ClinicalFinding(
    id: FindingIds.toxicOverdose,
    title: 'İlaç aşırı alımı / toksik maruziyet',
    description: 'Kritik toksisite riski olan alım veya maruziyet.',
    group: FindingGroup.toxicAndPsych,
  ),
  ClinicalFinding(
    id: FindingIds.violentPsychiatricRisk,
    title: 'Şiddet riski olan psikiyatrik durum',
    description: 'Kendine veya çevreye ciddi zarar verme olasılığı.',
    group: FindingGroup.toxicAndPsych,
  ),
  ClinicalFinding(
    id: FindingIds.severeAbdominalPain,
    title: 'Şiddetli karın ağrısı',
    description: 'Yüksek morbidite riski taşıyan belirgin ağrı.',
    group: FindingGroup.gastrointestinal,
  ),
  ClinicalFinding(
    id: FindingIds.elderlyAbdominalPain,
    title: '65 yaş üstü karın ağrısı',
    description: 'İleri yaşta karın ağrısı nedeniyle yüksek risk.',
    group: FindingGroup.gastrointestinal,
  ),
  ClinicalFinding(
    id: FindingIds.criticalHypertension,
    title: 'Kritik hipertansiyon',
    description: 'Sistolik >180 veya diyastolik >110 mmHg.',
    group: FindingGroup.circulation,
  ),
  ClinicalFinding(
    id: FindingIds.moderateBloodLoss,
    title: 'Orta derecede kan kaybı',
    description: 'Hemodinamik etkilenme potansiyeli olan kanama.',
    group: FindingGroup.circulation,
  ),
  ClinicalFinding(
    id: FindingIds.headTraumaWithAmnesia,
    title: 'Amnezi ile kafa travması',
    description: 'Kafa travması ve bellek kaybı öyküsü.',
    group: FindingGroup.neurological,
  ),
  ClinicalFinding(
    id: FindingIds.immunosuppressedFever,
    title: 'İmmünsüpresyon + ateş',
    description: 'Onkoloji/steroid öyküsü ile ateş yüksekliği.',
    group: FindingGroup.painAndFever,
  ),
  ClinicalFinding(
    id: FindingIds.persistentVomiting,
    title: 'İnatçı kusma',
    description: 'Uzamış kusma nedeniyle klinik kötüleşme riski.',
    group: FindingGroup.gastrointestinal,
  ),
  ClinicalFinding(
    id: FindingIds.seriousExtremityInjury,
    title: 'Ciddi ekstremite yaralanması',
    description: 'Deformite/ezilme içeren yüksek riskli travma.',
    group: FindingGroup.trauma,
  ),
  ClinicalFinding(
    id: FindingIds.simpleBleeding,
    title: 'Basit kanama',
    description: 'Kontrol edilebilir, düşük hacimli kanama.',
    group: FindingGroup.minorCare,
  ),
  ClinicalFinding(
    id: FindingIds.mildAbdominalPain,
    title: 'Hafif-orta karın ağrısı',
    description: 'Şiddetli olmayan ve stabil karın ağrısı.',
    group: FindingGroup.gastrointestinal,
  ),
  ClinicalFinding(
    id: FindingIds.swallowingDifficulty,
    title: 'Nefes darlığı olmadan yutma güçlüğü',
    description: 'Hava yolu riski olmadan disfaji.',
    group: FindingGroup.minorCare,
  ),
  ClinicalFinding(
    id: FindingIds.minorHeadTrauma,
    title: 'Bilinç kaybı olmayan minör kafa travması',
    description: 'Nörolojik bulgu vermeyen minör travma öyküsü.',
    group: FindingGroup.trauma,
  ),
  ClinicalFinding(
    id: FindingIds.minorChestTrauma,
    title: 'Basit göğüs travması',
    description: 'Stabil vital bulgularla hafif göğüs yaralanması.',
    group: FindingGroup.trauma,
  ),
  ClinicalFinding(
    id: FindingIds.vomitDiarrheaNoDehydration,
    title: 'Dehidratasyon olmadan kusma/ishal',
    description: 'Orta riskli gastrointestinal yakınma.',
    group: FindingGroup.gastrointestinal,
  ),
  ClinicalFinding(
    id: FindingIds.minorExtremityTrauma,
    title: 'Minör ekstremite travması',
    description: 'Burkulma, basit kesi veya basit kırık şüphesi.',
    group: FindingGroup.trauma,
  ),
  ClinicalFinding(
    id: FindingIds.severePainNrs710,
    title: 'Şiddetli ağrı (NRS 7-10)',
    description: 'MTS genel discriminator: çok şiddetli ağrı.',
    group: FindingGroup.painAndFever,
  ),
  ClinicalFinding(
    id: FindingIds.moderatePainNrs46,
    title: 'Orta ağrı (NRS 4-6)',
    description: 'MTS genel discriminator: orta düzey ağrı.',
    group: FindingGroup.painAndFever,
  ),
  ClinicalFinding(
    id: FindingIds.mildPainNrs13,
    title: 'Hafif ağrı (NRS 1-3)',
    description: 'MTS genel discriminator: düşük düzey ağrı.',
    group: FindingGroup.minorCare,
  ),
  ClinicalFinding(
    id: FindingIds.hotChild,
    title: 'Ateşli çocuk / <3 ay bebekte ateş',
    description: 'MTS yüksek risk ateş bulgusu.',
    group: FindingGroup.painAndFever,
  ),
  ClinicalFinding(
    id: FindingIds.veryHotAdult,
    title: 'Çok ateşli erişkin (>=38.5C)',
    description: 'MTS turuncu seviyeye çıkaran ateş bulgusu.',
    group: FindingGroup.painAndFever,
  ),
  ClinicalFinding(
    id: FindingIds.historyUnconsciousness,
    title: 'Geçici bilinç kaybı öyküsü',
    description: 'Başvuru öncesi senkop/bilinç kaybı öyküsü.',
    group: FindingGroup.neurological,
  ),
  ClinicalFinding(
    id: FindingIds.hotAdult,
    title: 'Ateşli erişkin (37.5-38.4C)',
    description: 'MTS sarı seviyeye çıkarabilen ateş bulgusu.',
    group: FindingGroup.painAndFever,
  ),
  ClinicalFinding(
    id: FindingIds.peritonism,
    title: 'Peritonizm bulguları',
    description: 'Defans/rebound gibi akut cerrahi karın bulguları.',
    group: FindingGroup.gastrointestinal,
  ),
  ClinicalFinding(
    id: FindingIds.meningismThunderclap,
    title: 'Menenjizm / thunderclap baş ağrısı',
    description: 'MTS’de yüksek risk nörolojik başvuru bulgusu.',
    group: FindingGroup.neurological,
  ),
  ClinicalFinding(
    id: FindingIds.chemicalEyeExposure,
    title: 'Kimyasal göz maruziyeti',
    description: 'Asit/alkali temas, acil irrigasyon gereksinimi.',
    group: FindingGroup.trauma,
  ),
  ClinicalFinding(
    id: FindingIds.dangerToSelfOthers,
    title: 'Kendine/çevreye zarar riski',
    description: 'MTS psikiyatrik discriminator.',
    group: FindingGroup.toxicAndPsych,
  ),
  ClinicalFinding(
    id: FindingIds.superficialWound,
    title: 'Yüzeyel yara / küçük sıyrık',
    description: 'Düşük riskli basit yara bakımı ihtiyacı.',
    group: FindingGroup.minorCare,
  ),
  ClinicalFinding(
    id: FindingIds.chronicStableComplaint,
    title: 'Kronik, stabil yakınma',
    description: 'Acil risk taşımayan kronik yakınmalar.',
    group: FindingGroup.minorCare,
  ),
  ClinicalFinding(
    id: FindingIds.mildBehavioralSymptoms,
    title: 'Genel durumu iyi davranışsal yakınma',
    description: 'Akut şiddet riski olmayan davranışsal durumlar.',
    group: FindingGroup.minorCare,
  ),
];

final Map<String, ClinicalFinding> triageFindingsById = {
  for (final finding in triageFindings) finding.id: finding,
};

const List<ScenarioPreset> scenarioPresets = [
  ScenarioPreset(
    id: 'cardiac_critical',
    title: 'Kritik kardiyak vaka',
    description: 'Arrest veya ileri kardiyopulmoner risk bulguları.',
    findingIds: {
      FindingIds.cardiacRespArrest,
      FindingIds.airwayCompromise,
      FindingIds.shockOrHypotension,
    },
  ),
  ScenarioPreset(
    id: 'orange_chest_pain',
    title: 'Yüksek risk göğüs ağrısı',
    description: 'Kardiyak ağrı + solunum sıkıntısı + dolaşım bozulması.',
    findingIds: {
      FindingIds.cardiacChestPain,
      FindingIds.severeDyspneaO2Low,
      FindingIds.circulationFailure,
      FindingIds.severePainNrs710,
    },
  ),
  ScenarioPreset(
    id: 'elderly_abdominal',
    title: 'Yaşlı hastada karın ağrısı',
    description: '65+ karın ağrısı ve eşlik eden riskli bulgular.',
    findingIds: {
      FindingIds.elderlyAbdominalPain,
      FindingIds.severeAbdominalPain,
      FindingIds.persistentVomiting,
    },
  ),
  ScenarioPreset(
    id: 'minor_trauma',
    title: 'Minör travma',
    description: 'Ayaktan yönetilebilir düşük riskli travma örneği.',
    findingIds: {
      FindingIds.minorExtremityTrauma,
      FindingIds.mildPainNrs13,
      FindingIds.superficialWound,
    },
  ),
  ScenarioPreset(
    id: 'stable_chronic',
    title: 'Stabil kronik yakınma',
    description: 'Acil tehdit içermeyen, kronik ve stabil başvuru.',
    findingIds: {
      FindingIds.chronicStableComplaint,
      FindingIds.mildBehavioralSymptoms,
    },
  ),
];
