import 'package:equatable/equatable.dart';

/// The user's app mode — host or guest.
enum AppMode {
  guest,
  host;

  /// Parse from a stored string, defaulting to [guest].
  static AppMode fromString(String? value) {
    if (value == 'host') return AppMode.host;
    return AppMode.guest;
  }
}

/// Typed, immutable class representing all user-level configuration.
///
/// Persisted as a single JSON blob under one storage key. Every field has a
/// sensible default so a fresh install starts with a valid config.
///
/// Use [copyWith] to produce a modified copy — never mutate in place.
class HostrUserConfig extends Equatable {
  /// Whether the user is in host or guest mode.
  final AppMode mode;

  /// Whether EVM auto-withdrawal is enabled.
  final bool autoWithdrawEnabled;

  const HostrUserConfig({
    this.mode = AppMode.guest,
    this.autoWithdrawEnabled = true,
  });

  /// Default config for a fresh install.
  static const defaults = HostrUserConfig();

  // ── copyWith ────────────────────────────────────────────────────────────

  HostrUserConfig copyWith({AppMode? mode, bool? autoWithdrawEnabled}) {
    return HostrUserConfig(
      mode: mode ?? this.mode,
      autoWithdrawEnabled: autoWithdrawEnabled ?? this.autoWithdrawEnabled,
    );
  }

  // ── Serialisation ───────────────────────────────────────────────────────

  factory HostrUserConfig.fromJson(Map<String, dynamic> json) {
    return HostrUserConfig(
      mode: AppMode.fromString(json['mode'] as String?),
      autoWithdrawEnabled: json['autoWithdrawEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'autoWithdrawEnabled': autoWithdrawEnabled,
  };

  // ── Convenience getters ─────────────────────────────────────────────────

  bool get isHost => mode == AppMode.host;
  bool get isGuest => mode == AppMode.guest;

  @override
  List<Object?> get props => [mode, autoWithdrawEnabled];

  @override
  String toString() =>
      'HostrUserConfig('
      'mode: ${mode.name}, '
      'autoWithdraw: $autoWithdrawEnabled)';
}
