// Smoke test for the example app: it should build and expose a button for every
// method the plugin wraps.

import 'package:eidmsdk/eidmsdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eidmsdk_example/main.dart';

void main() {
  testWidgets('renders a button for each wrapped method',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('showTutorial()'), findsOneWidget);

    for (final level in EIDLogLevel.values) {
      expect(find.text('setLogLevel(logLevel: ${level.name})'), findsOneWidget);
    }

    for (final type in EIDCertificateIndex.values) {
      expect(
        find.text('getCertificates(type: ${type.name})'),
        findsOneWidget,
      );
    }

    expect(
      find.byWidgetPredicate((widget) =>
          widget is Text && widget.data?.startsWith('signData(') == true),
      findsOneWidget,
    );
  });
}
