import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/screens/certificates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Holds the outcome popped by the pushed [CertificatesScreen], updated
/// whenever the push future resolves -- which may be well after [_open]
/// itself returns, once the test taps a button on the pushed screen.
class _Push {
  FakeOutcome? outcome;
}

Future<_Push> _open(WidgetTester tester) async {
  final push = _Push();

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder:
            (context) => TextButton(
              onPressed: () async {
                push.outcome = await Navigator.of(context).push<FakeOutcome>(
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

  return push;
}

void main() {
  testWidgets('shows the fake identity', (tester) async {
    await _open(tester);

    expect(find.textContaining('Jozko Mrkvicka'), findsOneWidget);
    expect(find.textContaining('Bratislava'), findsOneWidget);
    expect(find.textContaining('FAKE eID SDK'), findsOneWidget);
  });

  testWidgets('return certificate yields FakeProceed', (tester) async {
    final push = await _open(tester);

    await tester.tap(find.text('Return certificate'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(push.outcome, isA<FakeProceed>());
  });

  testWidgets('cancel yields FakeCancel', (tester) async {
    final push = await _open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(push.outcome, isA<FakeCancel>());
  });

  testWidgets('return error opens the picker and propagates the choice', (
    tester,
  ) async {
    final push = await _open(tester);

    await tester.tap(find.text('Return error'));
    await tester.pumpAndSettle();
    expect(find.text('Return error'), findsWidgets);

    await tester.tap(find.text(FakeErrorCase.certificatesNotIssued.label));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(push.outcome, isA<FakeError>());
    expect(
      (push.outcome as FakeError).error,
      FakeErrorCase.certificatesNotIssued,
    );
  });
}
