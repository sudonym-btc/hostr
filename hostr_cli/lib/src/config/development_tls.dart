import 'dart:io';

import 'cli_environment.dart';

bool _configured = false;

/// Allows the CLI and daemon to talk to Docker's locally signed development
/// endpoints through the normal SDK/NDK transport.
///
/// This is intentionally restricted to local development hosts. Staging and
/// production keep Dart's default certificate verification.
void configureDevelopmentTlsTrust(HostrCliEnvironment environment) {
  if (_configured) return;

  final hosts = <String>{
    ..._hostsFrom(environment.hostrRelay),
    for (final relay in environment.bootstrapRelays) ..._hostsFrom(relay),
    for (final blossom in environment.bootstrapBlossom) ..._hostsFrom(blossom),
  };
  final allowDevelopmentWildcard = hosts.any(
    (host) => host.endsWith('.development'),
  );
  final forced =
      Platform.environment['HOSTR_CLI_ACCEPT_SELF_SIGNED_DEV_CERTS'] == '1' ||
      Platform.environment['HOSTR_ACCEPT_SELF_SIGNED_DEV_CERTS'] == '1';

  if (!forced && !allowDevelopmentWildcard) return;

  final previous = HttpOverrides.current;
  HttpOverrides.global = _DevelopmentTlsOverrides(
    previous: previous,
    allowedHosts: hosts,
    allowDevelopmentWildcard: allowDevelopmentWildcard || forced,
  );
  _configured = true;
}

Iterable<String> _hostsFrom(String value) sync* {
  final raw = value.trim();
  if (raw.isEmpty) return;
  final uri = Uri.tryParse(raw);
  final host = uri?.host.trim().toLowerCase();
  if (host != null && host.isNotEmpty) yield host;
}

class _DevelopmentTlsOverrides extends HttpOverrides {
  _DevelopmentTlsOverrides({
    required this.previous,
    required this.allowedHosts,
    required this.allowDevelopmentWildcard,
  });

  final HttpOverrides? previous;
  final Set<String> allowedHosts;
  final bool allowDevelopmentWildcard;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client =
        previous?.createHttpClient(context) ?? super.createHttpClient(context);
    client.badCertificateCallback = (_, host, _) {
      final normalized = host.trim().toLowerCase();
      return allowedHosts.contains(normalized) ||
          (allowDevelopmentWildcard && normalized.endsWith('.development'));
    };
    return client;
  }
}
