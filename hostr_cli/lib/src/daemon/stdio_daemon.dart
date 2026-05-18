import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import '../actions/hostr_actions.dart';
import '../context/hostr_cli_context.dart';
import '../output/result.dart';
import 'cancellation.dart';
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
  final _cancellations = <String, HostrCancellationToken>{};

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
    if (await _tryHandleCancelLine(line)) {
      return;
    }
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
    String? traceId;
    HostrCancellationToken? cancellationToken;
    String? requestId;
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
      requestId = id?.toString();
      final method = request['method']?.toString();
      final params = request['params'] is Map
          ? Map<String, dynamic>.from(request['params'])
          : <String, dynamic>{};
      traceId =
          _optionalString(request, 'traceId') ??
          _optionalString(params, 'traceId');
      final stopwatch = Stopwatch()..start();
      if (requestId != null && requestId.isNotEmpty) {
        cancellationToken = HostrCancellationToken();
        _cancellations[requestId] = cancellationToken;
      }
      final queueMs = DateTime.now().difference(queuedAt).inMilliseconds;
      _log('request', {
        'id': id,
        'method': method,
        'traceId': ?traceId,
        if (queueMs > 0) 'queueMs': queueMs,
        'params': _redactForLog(params),
      });

      final result = switch (method) {
        'describe' => HostrActionCatalog.toJson(),
        'visibleActions' => daemon.visibleActions(
          pubkey: _optionalString(params, 'pubkey'),
          traceId: traceId,
        ),
        'logoutSession' =>
          await daemon
              .logoutSession(
                pubkey: _requiredString(params, 'pubkey'),
                traceId: traceId,
              )
              .then((result) => result.toJson()),
        'uploadImage' =>
          await daemon
              .uploadImage(
                pubkey: _optionalString(params, 'pubkey'),
                base64: _requiredString(params, 'base64'),
                mime: _optionalString(params, 'mime'),
                filename: _optionalString(params, 'filename'),
                traceId: traceId,
                cancellationToken: cancellationToken,
              )
              .then((result) => result.toJson()),
        'startOAuthNostrConnect' =>
          await daemon
              .startOAuthNostrConnect(
                requestId: _requiredString(params, 'requestId'),
                regenerate: params['regenerate'] == true,
                traceId: traceId,
                cancellationToken: cancellationToken,
              )
              .then((result) => result.toJson()),
        'completeOAuthNostrConnect' =>
          await daemon
              .completeOAuthNostrConnect(
                requestId: _requiredString(params, 'requestId'),
                timeoutSeconds: _optionalInt(params, 'timeoutSeconds') ?? 180,
                traceId: traceId,
                cancellationToken: cancellationToken,
              )
              .then((result) => result.toJson()),
        'completeOAuthNsec' =>
          await daemon
              .completeOAuthNsec(
                requestId: _requiredString(params, 'requestId'),
                nsec: _requiredString(params, 'nsec'),
                traceId: traceId,
                cancellationToken: cancellationToken,
              )
              .then((result) => result.toJson()),
        'callAction' =>
          await daemon
              .call(
                pubkey: _optionalString(params, 'pubkey'),
                action: _requiredString(params, 'action'),
                notificationToken: _optionalString(params, 'notificationToken'),
                traceId: traceId,
                cancellationToken: cancellationToken,
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
      cancellationToken?.throwIfCancelled();

      _log('response', {
        'id': id,
        'method': method,
        'traceId': ?traceId,
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'result': _redactForLog(result),
      });
      _write({'id': id, 'traceId': ?traceId, 'result': result});
    } on HostrCliException catch (error) {
      _log('error', {
        'id': id,
        'traceId': ?traceId,
        'code': error.code,
        'message': error.message,
        if (error.path != null) 'path': error.path,
        'retryable': error.retryable,
        if (error.details != null) 'details': _redactForLog(error.details),
      });
      _write({
        'id': id,
        'traceId': ?traceId,
        'error': {
          'code': error.code,
          'message': error.message,
          if (error.path != null) 'path': error.path,
          if (error.hint != null) 'hint': error.hint,
          'retryable': error.retryable,
          if (error.details != null) 'details': error.details,
        },
      });
    } on HostrCancellationException catch (error) {
      _log('cancelled', {
        'id': id,
        'traceId': ?traceId,
        'message': error.message,
      });
      _write({
        'id': id,
        'traceId': ?traceId,
        'error': {
          'code': 'request_cancelled',
          'message': error.message,
          'retryable': false,
        },
      });
    } catch (error) {
      _log('unexpectedError', {
        'id': id,
        'traceId': ?traceId,
        'message': error.toString(),
      });
      _write({
        'id': id,
        'traceId': ?traceId,
        'error': {
          'code': 'unexpected_error',
          'message': error.toString(),
          'retryable': false,
        },
      });
    } finally {
      if (requestId != null) {
        _cancellations.remove(requestId);
      }
    }
  }

  Future<bool> _tryHandleCancelLine(String line) async {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) return false;
      final request = Map<String, dynamic>.from(decoded);
      if (request['method']?.toString() != 'cancel') return false;
      final id = request['id'];
      final params = request['params'] is Map
          ? Map<String, dynamic>.from(request['params'])
          : <String, dynamic>{};
      final traceId =
          _optionalString(request, 'traceId') ??
          _optionalString(params, 'traceId');
      final requestId = _requiredString(params, 'requestId');
      final token = _cancellations[requestId];
      token?.cancel();
      _log('cancel', {
        'id': id,
        'traceId': ?traceId,
        'requestId': requestId,
        'found': token != null,
      });
      _write({
        'id': id,
        'traceId': ?traceId,
        'result': {'cancelled': token != null, 'requestId': requestId},
      });
      return true;
    } catch (error) {
      _log('cancelError', {'message': error.toString()});
      return false;
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
