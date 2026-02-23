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

const kEthPrivPath = "m/44'/60'/0'/0/0";

// ── Animation ──────────────────────────────────────────────────────────────

/// Standard animation duration used across the app for transitions, slides,
/// fades, and switchers.
const kAnimationDuration = Duration(milliseconds: 300);

/// Standard animation curve used across the app.
const kAnimationCurve = Curves.easeInOut;

/// Per-item stagger delay for list entry animations.
const kStaggerDelay = Duration(milliseconds: 60);
