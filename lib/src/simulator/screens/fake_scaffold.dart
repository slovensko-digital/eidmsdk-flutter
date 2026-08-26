import 'package:flutter/material.dart';

/// Shared chrome for every fake screen: white background, a title, and a
/// permanent banner so a screenshot of one can never be mistaken for the real
/// SDK's UI.
///
/// The fake screens are pushed onto the *host app's* [Navigator], so they
/// inherit the host's [ThemeData] — a dark or heavily branded host would
/// otherwise repaint them into something that looks native to that app. So this
/// imposes [_fakeTheme] on the whole subtree rather than reading the ambient
/// theme. Screens below can then use plain [ElevatedButton] and unstyled [Text]
/// and still come out looking the same in every host.
class FakeScaffold extends StatelessWidget {
  const FakeScaffold({super.key, required this.title, required this.body});

  /// The fake's fixed look, deliberately built from scratch rather than with
  /// `Theme.of(context).copyWith(...)`: copying would let every color this
  /// does not name explicitly leak in from the host app.
  ///
  /// Static so it is built once rather than per rebuild. [Theme] is an
  /// [InheritedWidget], so a fresh-but-equal instance each build would pay both
  /// the construction and a field-by-field `ThemeData ==` in
  /// `updateShouldNotify`; one shared instance is `identical` and short-circuits
  /// that. It cannot be `const` — [ThemeData]'s constructor is not.
  static final ThemeData _fakeTheme = ThemeData(
    // Pinned, not left to Flutter's shifting default, so the fake does not
    // change appearance under the host on an SDK upgrade.
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.black,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      onSurfaceVariant: Colors.black54,
      surfaceContainerHighest: Color(0xFFF2F2F2),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: const RoundedRectangleBorder(),
      ),
    ),
  );

  /// Gap between stacked buttons, so the screens space them consistently
  /// without each one picking its own number.
  static const double buttonSpacing = 12;

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Deliberately not themed. This banner is the marker that keeps a
        // screenshot from passing as the real SDK, so it must not be one
        // edit to _fakeTheme away from becoming invisible.
        Container(
          width: double.infinity,
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: const Text(
            'SIMULATOR — FAKE eID SDK',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Padding(padding: const EdgeInsets.all(24), child: body),
        ),
      ],
    );

    return Theme(
      data: _fakeTheme,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(child: content),
      ),
    );
  }
}
