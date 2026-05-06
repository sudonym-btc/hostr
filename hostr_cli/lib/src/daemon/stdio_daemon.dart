import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import '../actions/hostr_actions.dart';
import '../context/hostr_cli_context.dart';
import '../output/result.dart';
import 'hostr_daemon.dart';

class HostrDaemonStdioServer {
  HostrDaemonStdioServer({
    required this.context,
    required this.stdin,
    required this.stdout,
    required this.stderr,
    this.maxConcurrentRequests = 16,
  }) {
    daemon = HostrDaemon(
      context,
      notifications: (method, params) =>
          _write({'method': method, 'params': params}),
    );
  }

  final HostrCliRuntimeContext context;
  final Stream<List<int>> stdin;
  final IOSink stdout;
  final IOSink stderr;
  late final HostrDaemon daemon;
  final int maxConcurrentRequests;
  late final _AsyncSemaphore _requestSlots = _AsyncSemaphore(
    maxConcurrentRequests,
  );

  Future<void> serve() async {
    final inFlight = <Future<void>>{};

    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) continue;

      final task = _handleLineConcurrent(line);
      inFlight.add(task);
      task.whenComplete(() => inFlight.remove(task)).ignore();
    }

    if (inFlight.isNotEmpty) {
      await Future.wait(inFlight);
    }
  }

  Future<void> _handleLineConcurrent(String line) async {
    final queuedAt = DateTime.now();
    await _requestSlots.acquire();
    try {
      await _handleLine(line, queuedAt: queuedAt);
    } finally {
      _requestSlots.release();
    }
  }

  Future<void> _handleLine(String line, {required DateTime queuedAt}) async {
    Object? id;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        throw HostrCliException(
          'invalid_request',
          'Daemon request must be a JSON object.',
        );
      }
      final request = Map<String, dynamic>.from(decoded);
      id = request['id'];
      final method = request['method']?.toString();
      final params = request['params'] is Map
          ? Map<String, dynamic>.from(request['params'])
          : <String, dynamic>{};
      final stopwatch = Stopwatch()..start();
      final queueMs = DateTime.now().difference(queuedAt).inMilliseconds;
      _log('request', {
        'id': id,
        'method': method,
        if (queueMs > 0) 'queueMs': queueMs,
        'params': _redactForLog(params),
      });

      final result = switch (method) {
        'describe' => HostrActionCatalog.toJson(),
        'visibleActions' => daemon.visibleActions(
          pubkey: _optionalString(params, 'pubkey'),
        ),
        'uploadImage' =>
          await daemon
              .uploadImage(
                pubkey: _optionalString(params, 'pubkey'),
                base64: _requiredString(params, 'base64'),
                mime: _optionalString(params, 'mime'),
                filename: _optionalString(params, 'filename'),
              )
              .then((result) => result.toJson()),
        'startOAuthNostrConnect' =>
          await daemon
              .startOAuthNostrConnect(
                requestId: _requiredString(params, 'requestId'),
                regenerate: params['regenerate'] == true,
              )
              .then((result) => result.toJson()),
        'completeOAuthNostrConnect' =>
          await daemon
              .completeOAuthNostrConnect(
                requestId: _requiredString(params, 'requestId'),
                timeoutSeconds: _optionalInt(params, 'timeoutSeconds') ?? 180,
              )
              .then((result) => result.toJson()),
        'callAction' =>
          await daemon
              .call(
                pubkey: _optionalString(params, 'pubkey'),
                action: _requiredString(params, 'action'),
                notificationToken: _optionalString(params, 'notificationToken'),
                input: params['input'] is Map
                    ? Map<String, dynamic>.from(params['input'])
                    : <String, dynamic>{},
              )
              .then((result) => result.toJson()),
        _ => throw HostrCliException(
          'unknown_method',
          'Unknown Hostr daemon method "$method".',
        ),
      };

      _log('response', {
        'id': id,
        'method': method,
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'result': _redactForLog(result),
      });
      _write({'id': id, 'result': result});
    } on HostrCliException catch (error) {
      _log('error', {
        'id': id,
        'code': error.code,
        'message': error.message,
        if (error.path != null) 'path': error.path,
        'retryable': error.retryable,
        if (error.details != null) 'details': _redactForLog(error.details),
      });
      _write({
        'id': id,
        'error': {
          'code': error.code,
          'message': error.message,
          if (error.path != null) 'path': error.path,
          if (error.hint != null) 'hint': error.hint,
          'retryable': error.retryable,
          if (error.details != null) 'details': error.details,
        },
      });
    } catch (error) {
      _log('unexpectedError', {'id': id, 'message': error.toString()});
      _write({
        'id': id,
        'error': {
          'code': 'unexpected_error',
          'message': error.toString(),
          'retryable': false,
        },
      });
    }
  }

  String _requiredString(Map<String, dynamic> params, String key) {
    final value = params[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw HostrCliException(
        'missing_param',
        'Missing required daemon parameter "$key".',
        path: key,
      );
    }
    return value;
  }

  String? _optionalString(Map<String, dynamic> params, String key) {
    final value = params[key]?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  int? _optionalInt(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _write(Map<String, Object?> response) {
    stdout.writeln(jsonEncode(response));
  }

  void _log(String event, Map<String, Object?> data) {
    stderr.writeln(jsonEncode({'event': event, ...data}));
  }

  Object? _redactForLog(Object? value) {
    if (value is Map) {
      return value.map((key, entry) {
        final keyString = key.toString();
        return MapEntry(
          keyString,
          _sensitiveKey.hasMatch(keyString)
              ? '[redacted]'
              : _redactForLog(entry),
        );
      });
    }
    if (value is List) {
      return value.map(_redactForLog).toList();
    }
    if (value is String && value.length > 1000) {
      return '${value.substring(0, 1000)}... [truncated ${value.length} chars]';
    }
    return value;
  }

  static final _sensitiveKey = RegExp(
    r'(secret|token|authorization|cookie|password|private|nsec|jwt|qrImage|nostrconnect)',
    caseSensitive: false,
  );
}

class _AsyncSemaphore {
  _AsyncSemaphore(this._available) {
    if (_available < 1) {
      throw ArgumentError.value(_available, 'maxConcurrentRequests');
    }
  }

  int _available;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future.value();
    }

    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
      return;
    }
    _available++;
  }
}
