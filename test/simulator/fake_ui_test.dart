import 'package:eidmsdk/errors.dart';
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/fake_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    FakeUi.autoRespond = null;
    FakeUi.navigatorKey = null;
  });

  testWidgets('finds the host app root navigator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    expect(FakeUi.findRootNavigator(), isNotNull);
  });

  testWidgets('pushes a screen and returns the outcome it pops', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    final result = FakeUi.presentOutcome(
      (context) => Scaffold(
        body: TextButton(
          onPressed:
              () => Navigator.of(
                context,
              ).pop(const FakeError(FakeErrorCase.signingFailed)),
          child: const Text('fail'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('fail'));
    await tester.pumpAndSettle();

    expect(await result, isA<FakeError>());
  });

  testWidgets('treats a dismissed screen as cancellation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    final result = FakeUi.presentOutcome(
      (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('back'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    expect(await result, isA<FakeCancel>());
  });

  testWidgets('autoRespond short-circuits without rendering', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    FakeUi.autoRespond = const FakeProceed();

    final result = await FakeUi.presentOutcome(
      (context) => const Scaffold(body: Text('should not appear')),
    );
    await tester.pump();

    expect(result, isA<FakeProceed>());
    expect(find.text('should not appear'), findsNothing);
  });

  testWidgets('autoRespond also short-circuits the tutorial', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    FakeUi.autoRespond = const FakeProceed();

    await FakeUi.presentTutorial(
      (context) => const Scaffold(body: Text('should not appear')),
    );
    await tester.pump();

    expect(find.text('should not appear'), findsNothing);
  });

  testWidgets(
    'autoRespond short-circuits presentOutcome even with no navigator in the tree',
    (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('no navigator here'),
        ),
      );
      FakeUi.autoRespond = const FakeProceed();

      final result = await FakeUi.presentOutcome(
        (context) => const Placeholder(),
      );

      expect(result, isA<FakeProceed>());
    },
  );

  testWidgets(
    'autoRespond short-circuits presentTutorial even with no navigator in the tree',
    (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('no navigator here'),
        ),
      );
      FakeUi.autoRespond = const FakeProceed();

      await expectLater(
        FakeUi.presentTutorial((context) => const Placeholder()),
        completes,
      );
    },
  );

  testWidgets('throws a helpful error when there is no navigator to use', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('no navigator here'),
      ),
    );

    await expectLater(
      FakeUi.presentOutcome((context) => const Placeholder()),
      throwsA(
        isA<EidmsdkException>().having(
          (e) => e.message,
          'message',
          contains('navigatorKey'),
        ),
      ),
    );
  });
}
