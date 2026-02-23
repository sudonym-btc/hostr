import 'package:flutter/animation.dart';

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

const kEthPrivPath = "m/44'/60'/0'/0/0";

// ── Animation ──────────────────────────────────────────────────────────────

/// Standard animation duration used across the app for transitions, slides,
/// fades, and switchers.
const kAnimationDuration = Duration(milliseconds: 300);

/// Standard animation curve used across the app.
const kAnimationCurve = Curves.easeInOut;

/// Per-item stagger delay for list entry animations.
const kStaggerDelay = Duration(milliseconds: 60);
