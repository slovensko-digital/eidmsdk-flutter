import 'package:flutter/material.dart';

import '../fake_errors.dart';
import 'fake_scaffold.dart';

/// Lets the developer choose which real eID error the fake should raise, so
/// every error branch in a host app is reachable on demand.
class ErrorPickerScreen extends StatelessWidget {
  const ErrorPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FakeScaffold(
      title: 'Return error',
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'The chosen code is reported exactly as the native SDK would '
              'report it, so it maps to the same exception a real device '
              'produces.',
              style: TextStyle(color: Colors.black),
            ),
          ),
          for (final errorCase in FakeErrorCase.values)
            fakeButton(
              label: errorCase.label,
              onPressed: () => Navigator.of(context).pop(errorCase),
            ),
        ],
      ),
    );
  }
}
