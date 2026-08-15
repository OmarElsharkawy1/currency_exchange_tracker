import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen sizes real phones actually have.
///
/// The framework's default test surface is wider than any phone and shorter
/// than most, so a row that overflows on a handset fits comfortably in a
/// test. Anything that lays out horizontally should be pumped at these.
abstract final class PhoneSurface {
  /// A common mid-size handset (Pixel-class, logical pixels).
  static const Size medium = Size(360, 640);

  /// The narrowest size still worth supporting (iPhone SE-class).
  static const Size small = Size(320, 568);

  /// Both, for tests that should hold at either width.
  static const List<Size> all = [medium, small];

  /// The framework's own default, for the rare test that wants room.
  static const Size desktop = Size(800, 600);
}

/// Resizes the surface a test renders into.
extension SurfaceBinding on TestWidgetsFlutterBinding {
  /// Renders at [size] logical pixels, one physical pixel each.
  void applySurface(Size size) {
    platformDispatcher.implicitView!
      ..devicePixelRatio = 1
      ..physicalSize = size;
  }

  /// Restores the framework's default surface.
  void resetSurface() {
    platformDispatcher.implicitView!
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  }
}

/// Pumps at a size other than the phone default.
extension PhoneSurfaceTester on WidgetTester {
  /// Renders the rest of this test at [size].
  ///
  /// The default is [PhoneSurface.medium]; call this only to go narrower, or
  /// to opt back into desktop room.
  void usePhoneSurface(Size size) {
    binding.applySurface(size);
    addTearDown(binding.resetSurface);
  }

  /// Opts back into the framework's roomy default surface.
  ///
  /// Only for tests that genuinely need the space; a layout assertion made
  /// here proves nothing about a phone.
  void useDesktopSurface() => usePhoneSurface(PhoneSurface.desktop);
}
