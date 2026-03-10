import 'dart:async';

import 'package:opentelemetry/api.dart' hide SpanProcessor;
import 'package:opentelemetry/sdk.dart';

/// Zone key used to propagate the current OTel [Context] through the
/// call-stack.  Every [runInSpan] / [runInSpanSync] stores the new
/// child context here so that nested calls automatically find their
/// parent span.
final _contextKey = Symbol('otel.context');

/// Retrieves the [Context] stored in the current [Zone], falling back
/// to [Context.current] (the global root) if none was set.
Context get _zoneContext =>
    (Zone.current[_contextKey] as Context?) ?? Context.current;

String _attributeValueToString(Object value) {
  if (value is Iterable) {
    return value.map((item) => item.toString()).join(',');
  }
  return value.toString();
}

Iterable<Attribute> _buildAttributes(Map<String, Object?>? attributes) sync* {
  if (attributes == null) return;
  for (final entry in attributes.entries) {
    final value = entry.value;
    if (value == null) continue;
    yield Attribute.fromString(entry.key, _attributeValueToString(value));
  }
}

/// Central OpenTelemetry entry-point for the Hostr SDK.
///
/// Create a single instance during bootstrap (via [HostrConfig]) and
/// pass it around through DI. The class holds a [TracerProvider] and
/// exposes helpers that wrap arbitrary code in properly-nested spans
/// using [Zone]s for automatic parent propagation.
///
/// ```dart
/// final telemetry = Telemetry(serviceName: 'hostr-sdk');
/// await telemetry.runInSpan('my-operation', () async {
///   // nested spans automatically become children:
///   await telemetry.runInSpan('sub-step', () async { ... });
/// });
/// telemetry.shutdown();
/// ```
class Telemetry {
  late final TracerProvider _provider;
  late final Tracer _tracer;
  final String serviceName;

  /// If true, spans are exported to the configured OTLP endpoint.
  /// If false, only the console exporter is used (local dev).
  final bool enableExport;

  /// OTLP endpoint for the collector (e.g. http://localhost:4318/v1/traces).
  final String? otlpEndpoint;

  Telemetry({
    this.serviceName = 'hostr-sdk',
    this.enableExport = false,
    this.otlpEndpoint,
    String? serviceVersion,
  }) {
    final resource = Resource([
      Attribute.fromString('service.name', serviceName),
      if (serviceVersion != null)
        Attribute.fromString('service.version', serviceVersion),
    ]);

    final processors = <SpanProcessor>[];

    if (enableExport && otlpEndpoint != null) {
      processors.add(
        SimpleSpanProcessor(CollectorExporter(Uri.parse(otlpEndpoint!))),
      );
    }

    _provider = TracerProviderBase(resource: resource, processors: processors);

    _tracer = _provider.getTracer(serviceName);
  }

  /// A no-op telemetry instance that creates no-op spans and does not
  /// export anything.  Useful for tests or when OTel is disabled.
  Telemetry.noop()
    : serviceName = 'noop',
      enableExport = false,
      otlpEndpoint = null {
    _provider = TracerProviderBase();
    _tracer = _provider.getTracer('noop');
  }

  Tracer get tracer => _tracer;

  // ---------------------------------------------------------------------------
  // Span helpers
  // ---------------------------------------------------------------------------

  /// Runs [fn] inside a new child span named [name].
  ///
  /// The span is automatically ended when [fn] completes (or throws).
  /// If [fn] throws, the span records the error and is marked with
  /// [StatusCode.error].  The span's [Context] is propagated via a
  /// child [Zone] so that any nested [runInSpan] calls automatically
  /// become children.
  Future<T> runInSpan<T>(
    String name,
    Future<T> Function() fn, {
    Map<String, Object?>? attributes,
    SpanKind kind = SpanKind.internal,
  }) async {
    final parentCtx = _zoneContext;
    final span = _tracer.startSpan(name, context: parentCtx, kind: kind);
    for (final attribute in _buildAttributes(attributes)) {
      span.setAttribute(attribute);
    }

    final childCtx = parentCtx.withSpan(span);

    try {
      final result = await runZoned(fn, zoneValues: {_contextKey: childCtx});
      span.setStatus(StatusCode.ok);
      return result;
    } catch (error, stack) {
      span.setStatus(StatusCode.error, error.toString());
      span.recordException(error, stackTrace: stack);
      rethrow;
    } finally {
      span.end();
    }
  }

  /// Synchronous variant of [runInSpan].
  T runInSpanSync<T>(
    String name,
    T Function() fn, {
    Map<String, Object?>? attributes,
    SpanKind kind = SpanKind.internal,
  }) {
    final parentCtx = _zoneContext;
    final span = _tracer.startSpan(name, context: parentCtx, kind: kind);
    for (final attribute in _buildAttributes(attributes)) {
      span.setAttribute(attribute);
    }

    final childCtx = parentCtx.withSpan(span);

    try {
      final result = runZoned(fn, zoneValues: {_contextKey: childCtx});
      span.setStatus(StatusCode.ok);
      return result;
    } catch (error, stack) {
      span.setStatus(StatusCode.error, error.toString());
      span.recordException(error, stackTrace: stack);
      rethrow;
    } finally {
      span.end();
    }
  }

  /// Adds an event to the currently active span (from the zone context).
  /// Use this for log-like messages inside an existing span.
  void addEvent(String name, {Map<String, Object?>? attributes}) {
    final span = _zoneContext.span;
    final attrs = _buildAttributes(attributes).toList();
    span.addEvent(name, attributes: attrs);
  }

  /// Sets an attribute on the currently active span.
  void setSpanAttribute(String key, Object value) {
    final span = _zoneContext.span;
    span.setAttribute(
      Attribute.fromString(key, _attributeValueToString(value)),
    );
  }

  /// Sets multiple attributes on the currently active span.
  void setSpanAttributes(Map<String, Object?> attributes) {
    final span = _zoneContext.span;
    for (final attribute in _buildAttributes(attributes)) {
      span.setAttribute(attribute);
    }
  }

  /// Gracefully shuts down all span processors and exporters.
  void shutdown() {
    _provider.shutdown();
  }
}
