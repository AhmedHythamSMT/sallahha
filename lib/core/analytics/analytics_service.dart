/// Analytics abstraction: non-sensitive events only, never PII.
/// Debug buffer now; Firebase adapter later behind a flag.
class AnalyticsEvent {
  final String name;
  final Map<String, String> params;
  final DateTime at;
  AnalyticsEvent(this.name, [Map<String, String>? params])
    : params = Map.unmodifiable(params ?? const {}),
      at = DateTime.now();
}

abstract class AnalyticsService {
  void log(String name, [Map<String, String> params]);
  List<AnalyticsEvent> get events;
}

class MemoryAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> _events = [];
  @override
  void log(String name, [Map<String, String> params = const {}]) {
    _events.add(AnalyticsEvent(name, params));
    if (_events.length > 200) _events.removeAt(0);
  }

  @override
  List<AnalyticsEvent> get events => List.unmodifiable(_events);
}
