import 'package:flutter/material.dart';

import '../../errors.dart';
import 'fake_outcome.dart';

/// Presents the fake screens without any cooperation from the host app.
///
/// The plugin has no `BuildContext` of its own, and requiring consuming apps to
/// attach a navigator key would break the promise that the simulator fake needs
/// no setup. So the host's root [Navigator] is located by walking the element
/// tree from [WidgetsBinding.rootElement].
///
/// That walk is the only unsupported API surface in this package. It is kept to
/// one function with one failure mode, so a future Flutter change is a
/// single-file repair, and [navigatorKey] lets a host unblock itself without
/// waiting for a plugin release.
class FakeUi {
  FakeUi._();

  /// When set, screens resolve to this outcome immediately and nothing renders.
  ///
  /// Exists so that host-app integration tests calling into the plugin do not
  /// hang waiting for a tap that never comes. Exposed publicly as
  /// `SimulatorEidmsdk.autoRespond`.
  static FakeOutcome? autoRespond;

  /// Optional escape hatch, exposed publicly as `Eidmsdk.navigatorKey`. Only
  /// consulted when walking the element tree finds nothing.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Pushes [builder] and resolves to the outcome it pops.
  ///
  /// A screen dismissed without an explicit outcome — the system back button,
  /// for instance — counts as [FakeCancel].
  static Future<FakeOutcome> presentOutcome(WidgetBuilder builder) async {
    final shortCircuit = autoRespond;
    if (shortCircuit != null) {
      return shortCircuit;
    }

    final navigator = _requireNavigator();
    final outcome = await navigator.push<FakeOutcome>(
      MaterialPageRoute<FakeOutcome>(builder: builder),
    );

    return outcome ?? const FakeCancel();
  }

  /// Pushes [builder] for a screen with nothing to choose, such as the tutorial.
  static Future<void> presentTutorial(WidgetBuilder builder) async {
    if (autoRespond != null) {
      return;
    }

    await _requireNavigator().push<void>(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  static NavigatorState _requireNavigator() {
    final navigator = findRootNavigator() ?? navigatorKey?.currentState;
    if (navigator == null) {
      throw EidmsdkException(
        'The eID simulator fake could not find a Navigator to present its '
        'screens on. Wrap your app in a MaterialApp, or assign '
        'Eidmsdk.navigatorKey to your app\'s navigatorKey.',
      );
    }

    return navigator;
  }

  /// Walks the element tree for the first [Navigator] in the host app.
  @visibleForTesting
  static NavigatorState? findRootNavigator() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) {
      return null;
    }

    NavigatorState? found;

    void visit(Element element) {
      if (found != null) {
        return;
      }
      if (element is StatefulElement && element.state is NavigatorState) {
        found = element.state as NavigatorState;

        return;
      }
      element.visitChildElements(visit);
    }

    visit(root);

    return found;
  }
}
