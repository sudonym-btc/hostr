import 'dart:async';

const Object _traceIdZoneKey = #hostrTraceId;

class TraceContext {
  const TraceContext._();

  static String? get currentTraceId {
    final value = Zone.current[_traceIdZoneKey];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  static R run<R>(String? traceId, R Function() body) {
    if (traceId == null || traceId.trim().isEmpty) {
      return body();
    }
    return runZoned(body, zoneValues: {_traceIdZoneKey: traceId});
  }

  static Map<String, String> headers() {
    final traceId = currentTraceId;
    if (traceId == null) return const {};
    return {'x-trace-id': traceId};
  }
}
