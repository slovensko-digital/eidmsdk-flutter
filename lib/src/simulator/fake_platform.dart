import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Which host platform the fake is pretending to be.
///
/// Exists so that platform-faithful behaviour — Android completing with `null`
/// on cancellation where iOS raises an error — can be tested on any machine.
class FakeHostPlatform {
  FakeHostPlatform._();

  /// Overrides the real platform check. Tests only.
  @visibleForTesting
  static bool? debugIsAndroidOverride;

  static bool get isAndroid => debugIsAndroidOverride ?? Platform.isAndroid;
}
