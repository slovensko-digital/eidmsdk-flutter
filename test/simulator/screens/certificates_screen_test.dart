import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/screens/certificates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakeOutcome?> _open(WidgetTester tester) async {
  FakeOutcome? outcome;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder:
            (context) => TextButton(
              onPressed: () async {
                outcome = await Navigator.of(context).push<FakeOutcome>(
                  MaterialPageRoute<FakeOutcome>(
                    builder: (_) => const CertificatesScreen(),
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

  return outcome;
}

void main() {
  testWidgets('shows the fake identity', (tester) async {
    await _open(tester);

    expect(find.textContaining('Jozko Mrkvicka'), findsOneWidget);
    expect(find.textContaining('Bratislava'), findsOneWidget);
    expect(find.textContaining('FAKE eID SDK'), findsOneWidget);
  });

  testWidgets('return certificate yields FakeProceed', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Return certificate'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('cancel yields FakeCancel', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('return error opens the picker and propagates the choice', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('Return error'));
    await tester.pumpAndSettle();
    expect(find.text('Return error'), findsWidgets);

    await tester.tap(find.text(FakeErrorCase.certificatesNotIssued.label));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });
}
