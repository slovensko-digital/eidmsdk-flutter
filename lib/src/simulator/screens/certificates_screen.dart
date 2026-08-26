import 'package:flutter/material.dart';

import '../fake_errors.dart';
import '../fake_identity.dart';
import '../fake_outcome.dart';
import 'error_picker_screen.dart';
import 'fake_scaffold.dart';

/// Stands in for the real SDK's certificate-reading flow.
class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FakeScaffold(
      title: 'Certificates',
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: _buildContent(context)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '${FakeIdentity.subjectCommonName}\n'
          '${FakeIdentity.subjectLocality}, '
          '${FakeIdentity.subjectCountry}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'One qualified signing certificate (QES). Self-signed '
            'and trusted by nobody.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FakeScaffold.buttonSpacing,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(const FakeProceed()),
              child: const Text('Return certificate'),
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
