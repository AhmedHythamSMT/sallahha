import 'package:sallahha/features/requests/domain/triage.dart';

/// AI abstraction. Rules-v1 is the only production implementation in the
/// MVP (see docs/ai/); ML adapters plug in here post-MVP behind this
/// same interface, never changing call sites.
abstract class AIService {
  TriageSuggestion suggest(String description, {String serviceType});
  int matchScore({
    required List<String> techSkills,
    required String serviceType,
    required bool available,
    required bool sameGovernorate,
    required int activeJobs,
  });
}

class RuleBasedTriageService implements AIService {
  @override
  TriageSuggestion suggest(String description, {String serviceType = ''}) =>
      suggestTriage(description, serviceType: serviceType);

  @override
  int matchScore({
    required List<String> techSkills,
    required String serviceType,
    required bool available,
    required bool sameGovernorate,
    required int activeJobs,
  }) => matchTechnicianScore(
    techSkills: techSkills,
    serviceType: serviceType,
    available: available,
    sameGovernorate: sameGovernorate,
    activeJobs: activeJobs,
  );
}

/// Deterministic stand-in for widget tests and demos.
class FakeAIService implements AIService {
  @override
  TriageSuggestion suggest(String description, {String serviceType = ''}) =>
      const TriageSuggestion(
        category: 'cooling',
        priority: 'normal',
        confidence: 1,
        reasons: ['fake'],
        modelId: 'fake',
      );

  @override
  int matchScore({
    required List<String> techSkills,
    required String serviceType,
    required bool available,
    required bool sameGovernorate,
    required int activeJobs,
  }) => 0;
}
