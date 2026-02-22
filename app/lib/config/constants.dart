import 'package:flutter/animation.dart';

const kDefaultPadding = 32;

const kEthPrivPath = "m/44'/60'/0'/0/0";

// ── Animation ──────────────────────────────────────────────────────────────

/// Standard animation duration used across the app for transitions, slides,
/// fades, and switchers.
const kAnimationDuration = Duration(milliseconds: 300);

/// Standard animation curve used across the app.
const kAnimationCurve = Curves.easeInOut;

/// Per-item stagger delay for list entry animations.
const kStaggerDelay = Duration(milliseconds: 60);
