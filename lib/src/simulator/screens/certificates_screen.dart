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
        builder:
            (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '${FakeIdentity.subjectCommonName}\n'
                        '${FakeIdentity.subjectLocality}, '
                        '${FakeIdentity.subjectCountry}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'One qualified signing certificate (QES). Self-signed '
                          'and trusted by nobody.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      const Spacer(),
                      fakeButton(
                        label: 'Return certificate',
                        onPressed:
                            () =>
                                Navigator.of(context).pop(const FakeProceed()),
                      ),
                      fakeButton(
                        label: 'Return error',
                        onPressed: () async {
                          final picked = await Navigator.of(
                            context,
                          ).push<FakeErrorCase>(
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
                        onPressed:
                            () => Navigator.of(context).pop(const FakeCancel()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
