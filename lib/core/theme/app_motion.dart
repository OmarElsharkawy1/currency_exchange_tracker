import 'package:flutter/animation.dart';

/// The app's motion vocabulary.
///
/// One curve and a small set of durations, so nothing on screen moves in a
/// way that looks borrowed from somewhere else. Every value is at or under
/// 400ms: this is feedback, not choreography.
abstract final class AppMotion {
  /// The only easing curve the app uses.
  static const Curve curve = Curves.easeOutCubic;

  /// A value changing in place — a number rolling to its new figure.
  static const Duration value = Duration(milliseconds: 300);

  /// An element arriving on screen.
  static const Duration entrance = Duration(milliseconds: 260);

  /// Gap between one list row's entrance and the next.
  static const Duration stagger = Duration(milliseconds: 40);

  /// The chart drawing itself in.
  static const Duration chart = Duration(milliseconds: 400);
}
