import 'package:flutter/material.dart';

/// Shared chrome for every fake screen: white background, a title, and a
/// permanent banner so a screenshot of one can never be mistaken for the real
/// SDK's UI.
class FakeScaffold extends StatelessWidget {
  const FakeScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(title),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
        ),
      ),
    );
  }
}

/// A black filled button with a white label, per the agreed styling.
Widget fakeButton({required String label, required VoidCallback onPressed}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    ),
  );
}
