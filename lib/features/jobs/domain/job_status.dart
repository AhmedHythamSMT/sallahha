// Pure-Dart job status state machine. No Flutter imports — unit tested.
// Statuses: new, assigned, accepted, on_the_way, arrived, in_progress,
// waiting_for_parts, completed, cancelled.
const Map<String, List<String>> legalTransitions = {
  'new': ['assigned', 'cancelled'],
  'assigned': ['accepted', 'cancelled'],
  'accepted': ['on_the_way', 'cancelled'],
  'on_the_way': ['arrived'],
  'arrived': ['in_progress'],
  'in_progress': ['waiting_for_parts', 'completed'],
  'waiting_for_parts': ['in_progress', 'completed'],
  'completed': [],
  'cancelled': [],
};

bool canTransition(String from, String to) =>
    legalTransitions[from]?.contains(to) ?? false;

List<String> nextStates(String from) =>
    List.unmodifiable(legalTransitions[from] ?? const []);
