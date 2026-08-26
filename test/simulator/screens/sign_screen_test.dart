import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/screens/sign_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Holds the outcome popped by the pushed [SignScreen], updated whenever the
/// push future resolves -- which may be well after [_open] itself returns,
/// once the test taps a button on the pushed screen.
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
                    builder:
                        (_) => const SignScreen(
                          dataPreview: 'hello world',
                          certIndex: 1,
                          signatureScheme: '1.2.840.113549.1.1.11',
                        ),
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
  testWidgets('shows what is being signed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignScreen(
          dataPreview: 'hello world',
          certIndex: 1,
          signatureScheme: '1.2.840.113549.1.1.11',
        ),
      ),
    );

    expect(find.textContaining('hello world'), findsOneWidget);
    expect(find.textContaining('1.2.840.113549.1.1.11'), findsOneWidget);
    expect(find.textContaining('FAKE eID SDK'), findsOneWidget);
    expect(find.text('Sign'), findsOneWidget);
    expect(find.text('Return error'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('sign pops FakeProceed', (tester) async {
    final push = await _open(tester);

    await tester.tap(find.text('Sign'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(push.outcome, isA<FakeProceed>());
  });

  testWidgets('cancel pops FakeCancel', (tester) async {
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

    await tester.tap(find.text(FakeErrorCase.signingFailed.label));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(push.outcome, isA<FakeError>());
    expect((push.outcome as FakeError).error, FakeErrorCase.signingFailed);
  });
}
