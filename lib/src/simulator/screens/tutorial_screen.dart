import 'package:flutter/material.dart';

import 'fake_scaffold.dart';

/// Stands in for the real SDK's NFC tutorial, which cannot run on a simulator.
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FakeScaffold(
      title: 'Tutorial',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'The real tutorial explains how to hold the card against the '
            'phone for NFC reading. There is no NFC on a simulator, so this '
            'screen only stands in for it.',
            style: TextStyle(color: Colors.black),
          ),
          const Spacer(),
          fakeButton(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
