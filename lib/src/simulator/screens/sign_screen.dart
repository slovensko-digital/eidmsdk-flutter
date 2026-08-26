import 'package:flutter/material.dart';

import '../fake_errors.dart';
import '../fake_outcome.dart';
import 'error_picker_screen.dart';
import 'fake_scaffold.dart';

/// Stands in for the real SDK's PIN-and-sign flow. Signing here is real
/// cryptography with a throwaway key, so the result verifies — it just proves
/// nothing about who signed it.
class SignScreen extends StatelessWidget {
  const SignScreen({
    super.key,
    required this.dataPreview,
    required this.certIndex,
    required this.signatureScheme,
  });

  final String dataPreview;
  final int certIndex;
  final String signatureScheme;

  @override
  Widget build(BuildContext context) {
    return FakeScaffold(
      title: 'Sign data',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Data to sign',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF2F2F2),
              child: Text(
                dataPreview,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          Text(
            'certIndex: $certIndex\nscheme: $signatureScheme',
            style: const TextStyle(color: Colors.black54),
          ),
          const Spacer(),
          fakeButton(
            label: 'Sign',
            onPressed: () => Navigator.of(context).pop(const FakeProceed()),
          ),
          fakeButton(
            label: 'Return error',
            onPressed: () async {
              final picked = await Navigator.of(context).push<FakeErrorCase>(
                MaterialPageRoute<FakeErrorCase>(
                  builder: (_) => const ErrorPickerScreen(),
                ),
              );
              if (picked != null && context.mounted) {
                Navigator.of(context).pop(FakeError(picked));
              }
            },
          ),
          fakeButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(const FakeCancel()),
          ),
        ],
      ),
    );
  }
}
