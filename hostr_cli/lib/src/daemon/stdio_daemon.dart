import 'dart:async';
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
  }) : daemon = HostrDaemon(
         context,
         notifications: (method, params) =>
             stdout.writeln(jsonEncode({'method': method, 'params': params})),
       );

  final HostrCliRuntimeContext context;
  final Stream<List<int>> stdin;
  final IOSink stdout;
  final IOSink stderr;
  final HostrDaemon daemon;

  Future<void> serve() async {
    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) continue;
      await _handleLine(line);
    }
  }

  Future<void> _handleLine(String line) async {
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
      _log('request', {
        'id': id,
        'method': method,
        'params': _redactForLog(params),
      });

      final result = switch (method) {
        'describe' => HostrActionCatalog.toJson(),
        'visibleActions' => daemon.visibleActions(
          pubkey: _optionalString(params, 'pubkey'),
        ),
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
