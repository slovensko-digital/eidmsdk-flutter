import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/screens/error_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lists every error case', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ErrorPickerScreen()));

    for (final c in FakeErrorCase.values) {
      await tester.scrollUntilVisible(find.text(c.label), 100);
      expect(find.text(c.label), findsOneWidget, reason: c.name);
    }
  });

  testWidgets('pops the picked case', (tester) async {
    FakeErrorCase? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => TextButton(
                onPressed: () async {
                  picked = await Navigator.of(context).push<FakeErrorCase>(
                    MaterialPageRoute<FakeErrorCase>(
                      builder: (_) => const ErrorPickerScreen(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(FakeErrorCase.signingFailed.label));
    await tester.pumpAndSettle();

    expect(picked, FakeErrorCase.signingFailed);
  });
}
