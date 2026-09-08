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
          const Expanded(
            child: Center(
              child: Text(
                'The real tutorial explains how to hold the card against the '
                'phone for NFC reading. There is no NFC on a simulator, so this '
                'screen only stands in for it.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
