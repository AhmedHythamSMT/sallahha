// Deterministic triage rules-v1. Pure Dart — no Flutter, fully offline.
// Every suggestion carries reasons + heuristic confidence and REQUIRES
// human confirmation (see docs/ai/model-card.md). Never a diagnosis.
class TriageSuggestion {
  final String category;
  final String priority;
  final double confidence;
  final List<String> reasons;
  final String modelId;
  const TriageSuggestion({
    required this.category,
    required this.priority,
    required this.confidence,
    required this.reasons,
    this.modelId = 'rules-v1',
  });
}

const _categoryKeywords = <String, List<String>>{
  'cooling': [
    'تبريد',
    'بيبرد',
    'يبرد',
    'ساقع',
    'هواء دافئ',
    'هواء سخن',
    'ما بيبردش',
    'cooling',
    'no cooling',
    'warm air',
    'not cold',
    'weak cooling',
  ],
  'electrical': [
    'كهربا',
    'كهرباء',
    'شرر',
    'شرارة',
    'قاطع',
    'فيوز',
    'ماس',
    'power',
    'spark',
    'breaker',
    'fuse',
    'short circuit',
    'trips',
  ],
  'leak': [
    'تسريب',
    'تنقيط',
    'مية',
    'مياه',
    'تصريف',
    'خرطوم',
    'leak',
    'leaking',
    'drip',
    'water',
    'drain',
  ],
  'noise': [
    'صوت',
    'ضوضاء',
    'اهتزاز',
    'زنة',
    'خشخشة',
    'noise',
    'noisy',
    'vibration',
    'rattle',
    'buzz',
  ],
  'no_power': [
    'مش شغال',
    'لا يعمل',
    'فاصل',
    'مطفي',
    'ما بيشتغلش',
    'not working',
    'dead',
    'won\'t turn on',
    'no power',
    'does not start',
  ],
  'cleaning': [
    'تنظيف',
    'فلتر',
    'فلاتر',
    'صيانة دورية',
    'غسيل',
    'clean',
    'filter',
    'maintenance',
    'service wash',
  ],
};

/// Safety keywords: still need human confirm, but UI must show a
/// "call supervisor now" banner and suggest urgent priority.
const safetyKeywords = [
  'شرر',
  'ريحة حرق',
  'رائحة حرق',
  'دخان',
  'ماس كهربائي',
  'spark',
  'burning smell',
  'smoke',
];

bool needsSafetyWarning(String description) {
  final text = description.toLowerCase();
  return safetyKeywords.any((k) => text.contains(k.toLowerCase()));
}

TriageSuggestion suggestTriage(String description, {String serviceType = ''}) {
  final text = description.toLowerCase();
  String best = 'uncertain';
  int bestHits = 0;
  for (final entry in _categoryKeywords.entries) {
    final hits = entry.value
        .where((k) => text.contains(k.toLowerCase()))
        .length;
    if (hits > bestHits) {
      bestHits = hits;
      best = entry.key;
    }
  }
  final safety = needsSafetyWarning(description);
  // Repeat mentions escalate operational faults; routine cleaning never does.
  final operational = best != 'cleaning' && best != 'uncertain';
  final priority = safety
      ? 'urgent'
      : best == 'no_power'
      ? 'high'
      : (operational && bestHits >= 2)
      ? 'high'
      : 'normal';
  final confidence = best == 'uncertain'
      ? 0.3
      : switch (bestHits) {
          1 => 0.55,
          2 => 0.75,
          _ => 0.9,
        };
  return TriageSuggestion(
    category: best,
    priority: priority,
    confidence: confidence,
    reasons: [
      if (safety) 'safety-keyword',
      if (best != 'uncertain') 'keyword:$best×$bestHits',
      if (best == 'uncertain') 'no-keyword-match',
      if (serviceType.isNotEmpty) 'service:$serviceType',
    ],
  );
}

/// Deterministic technician scoring (no ML). Higher wins.
/// skill match ×3, available ×2, same governorate +1, each active job −1.
int matchTechnicianScore({
  required List<String> techSkills,
  required String serviceType,
  required bool available,
  required bool sameGovernorate,
  required int activeJobs,
}) {
  var score = 0;
  if (techSkills.contains(serviceType)) score += 3;
  if (available) score += 2;
  if (sameGovernorate) score += 1;
  score -= activeJobs;
  return score;
}
