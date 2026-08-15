import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/phone_surface.dart';

/// Runs every test on a phone-sized surface.
///
/// The framework's 800×600 default is wider than any handset, which hides
/// horizontal overflow: a row that breaks on a real phone lays out happily in
/// a test. Phone width is the default here; desktop width is opt-in through
/// `useDesktopSurface()`.
///
/// The view is resized directly rather than through `setSurfaceSize`, which
/// asserts it is inside a test body and so cannot run from `setUp`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => binding.applySurface(PhoneSurface.medium));
  tearDown(binding.resetSurface);

  return testMain();
}
