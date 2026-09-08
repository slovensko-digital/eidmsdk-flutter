import 'package:eidmsdk/src/simulator/screens/fake_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A host app whose theme is as unlike the fake's as possible: dark, branded,
/// and with a non-white scaffold. Nothing of it may reach the fake screens.
final _hostileHostTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF00AA),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF120018),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF00AA),
      foregroundColor: const Color(0xFF00FF00),
    ),
  ),
);

Future<ThemeData> _pumpInHost(WidgetTester tester, ThemeData hostTheme) async {
  late ThemeData seen;
  // Tear the tree down first. Pumping a second MaterialApp straight over the
  // first reuses the elements, so the Builder below never rebuilds and `seen`
  // would silently keep the previous host's value — making any comparison
  // between two hosts pass vacuously.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: hostTheme,
      home: FakeScaffold(
        title: 'Probe',
        body: Builder(
          builder: (context) {
            seen = Theme.of(context);
            return ElevatedButton(onPressed: () {}, child: const Text('Go'));
          },
        ),
      ),
    ),
  );
  return seen;
}

void main() {
  testWidgets('imposes its own theme instead of inheriting the host app\'s', (
    tester,
  ) async {
    final seen = await _pumpInHost(tester, _hostileHostTheme);

    expect(seen.brightness, Brightness.light);
    expect(seen.colorScheme.surface, Colors.white);
    expect(seen.colorScheme.onSurface, Colors.black);
    expect(seen.scaffoldBackgroundColor, Colors.white);
    // The host's brand color must not appear anywhere in the fake's scheme.
    expect(seen.colorScheme.primary, isNot(const Color(0xFFFF00AA)));
  });

  testWidgets('buttons are themed black-on-white whatever the host says', (
    tester,
  ) async {
    await _pumpInHost(tester, _hostileHostTheme);

    // Read what actually got painted, not what the theme declares: the
    // ElevatedButton carries no style of its own, so the Material it renders
    // proves the imposed theme won over the host's elevatedButtonTheme.
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, Colors.black);
    expect(material.textStyle?.color, Colors.white);

    final label = tester.widget<Text>(find.text('Go'));
    expect(label.style?.color ?? material.textStyle?.color, Colors.white);
  });

  testWidgets('renders identically under a light and a dark host', (
    tester,
  ) async {
    final underDark = await _pumpInHost(tester, _hostileHostTheme);
    final underLight = await _pumpInHost(tester, ThemeData.light());

    expect(underDark.colorScheme.surface, underLight.colorScheme.surface);
    expect(underDark.colorScheme.onSurface, underLight.colorScheme.onSurface);
    expect(underDark.brightness, underLight.brightness);
  });

  testWidgets('the fake banner is always shown', (tester) async {
    await _pumpInHost(tester, _hostileHostTheme);
    expect(find.text('SIMULATOR — FAKE eID SDK'), findsOneWidget);
  });
}
