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
      body: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: _buildContent(context)),
              ),
            ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Data to sign',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: colors.surfaceContainerHighest,
            child: Text(
              dataPreview,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        Text(
          'certIndex: $certIndex\nscheme: $signatureScheme',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FakeScaffold.buttonSpacing,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(const FakeProceed()),
              child: const Text('Sign'),
            ),
            ElevatedButton(
              onPressed: () async {
                final picked = await Navigator.of(context).push<FakeErrorCase>(
                  MaterialPageRoute<FakeErrorCase>(
                    builder: (_) => const ErrorPickerScreen(),
                    fullscreenDialog: true,
                  ),
                );
                if (picked != null && context.mounted) {
                  Navigator.of(context).pop(FakeError(picked));
                }
              },
              child: const Text('Return error'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(const FakeCancel()),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
