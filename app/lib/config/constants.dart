import 'package:flutter/material.dart';

const kDefaultPadding = 32;

// ── Spacing scale (4px grid) ───────────────────────────────────────────────

const double kSpace0 = 0;
const double kSpace1 = kDefaultPadding / 8; // 4
const double kSpace2 = kDefaultPadding / 4; // 8
const double kSpace3 = kDefaultPadding * 3 / 8; // 12
const double kSpace4 = kDefaultPadding / 2; // 16
const double kSpace5 = kDefaultPadding * 3 / 4; // 24
const double kSpace6 = kDefaultPadding / 1; // 32
const double kSpace7 = kDefaultPadding * 1.5; // 48
const double kSpace8 = kDefaultPadding * 2; // 64

// ── Icon size scale ───────────────────────────────────────────────────────

const double kIconXs = 14.0; // Chips, inline labels
const double kIconSm = 16.0; // List item trailing, copy actions
const double kIconMd = 20.0; // Standard interactive icons
const double kIconLg = 24.0; // Navigation bar, section headers
const double kIconXl = 32.0; // Empty states, feature icons
const double kIconHero = 48.0; // Error/success status, onboarding

// ── Shape scale ────────────────────────────────────────────────────────────

abstract final class AppRadii {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

abstract final class AppBorderRadii {
  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius xs = BorderRadius.all(Radius.circular(AppRadii.xs));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(AppRadii.sm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(AppRadii.md));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(AppRadii.lg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(AppRadii.xl));
  static const BorderRadius full = BorderRadius.all(
    Radius.circular(AppRadii.full),
  );
  static const BorderRadius topLg = BorderRadius.vertical(
    top: Radius.circular(AppRadii.lg),
  );
  static const BorderRadius modalSheet = BorderRadius.vertical(
    top: Radius.circular(AppRadii.xl),
  );
}

abstract final class AppShapes {
  static const RoundedRectangleBorder button = RoundedRectangleBorder(
    borderRadius: AppBorderRadii.sm,
  );
  static const RoundedRectangleBorder card = RoundedRectangleBorder(
    borderRadius: AppBorderRadii.sm,
  );
  static const RoundedRectangleBorder dialog = RoundedRectangleBorder(
    borderRadius: AppBorderRadii.xl,
  );
  static const RoundedRectangleBorder modalSheet = RoundedRectangleBorder(
    borderRadius: AppBorderRadii.modalSheet,
  );
  static const StadiumBorder chip = StadiumBorder();
  static const CircleBorder circle = CircleBorder();

  static StadiumBorder chipWithSide({Color? color, double width = 1.0}) {
    return StadiumBorder(
      side: BorderSide(color: color ?? Colors.transparent, width: width),
    );
  }

  static RoundedRectangleBorder pillWithSide({
    Color? color,
    double width = 1.0,
  }) {
    return RoundedRectangleBorder(
      borderRadius: AppBorderRadii.full,
      side: BorderSide(color: color ?? Colors.transparent, width: width),
    );
  }
}

const kEthPrivPath = "m/44'/60'/0'/0/0";

// ── Animation ──────────────────────────────────────────────────────────────

/// Standard animation duration used across the app for transitions, slides,
/// fades, and switchers.
const kAnimationDuration = Duration(milliseconds: 300);

/// Standard animation curve used across the app.
const kAnimationCurve = Curves.easeInOut;

/// Per-item stagger delay for list entry animations.
const kStaggerDelay = Duration(milliseconds: 60);

/// The git commit SHA baked in at build time via --dart-define=COMMIT_SHA.
const kCommitSha = String.fromEnvironment('COMMIT_SHA', defaultValue: 'dev');

/// UTC build date baked in at build time via --dart-define=BUILD_DATE.
const kBuildDate = String.fromEnvironment('BUILD_DATE', defaultValue: '');

/// Human-readable build label for in-app diagnostics.
const kBuildLabel = kBuildDate == ''
    ? kCommitSha
    : 'Build $kBuildDate · $kCommitSha';
