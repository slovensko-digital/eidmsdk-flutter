import 'package:eidmsdk/src/simulator/screens/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a title, the fake warning and a close button', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.textContaining('FAKE eID SDK'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('close pops the screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => TextButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TutorialScreen(),
                      ),
                    ),
                child: const Text('open'),
              ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Tutorial'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Tutorial'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
