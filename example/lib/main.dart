import 'dart:convert';

import 'package:eidmsdk/eidmsdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      );
}

class HomePage extends StatelessWidget {
  final _eidmsdkPlugin = Eidmsdk();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eIDmSDK Example'),
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              spacing: 12,
              children: [
                const _FakeSdkBanner(),
                ...EIDLogLevel.values.map((e) => ElevatedButton(
                      child: Text('setLogLevel(logLevel: ${e.name})'),
                      onPressed: () => _run(
                        context,
                        () => _eidmsdkPlugin.setLogLevel(logLevel: e),
                      ),
                    )),
                ElevatedButton(
                  child: const Text('showTutorial()'),
                  onPressed: () => _run(
                    context,
                    () => _eidmsdkPlugin.showTutorial(),
                    showSuccess: false,
                  ),
                ),
                ...EIDCertificateIndex.values.map(
                  (e) => ElevatedButton(
                    child: Text('getCertificates(type: ${e.name})'),
                    onPressed: () => _run(context, () async {
                      final result =
                          await _eidmsdkPlugin.getCertificates(type: e);

                      return jsonEncode(result?.toJson());
                    }),
                  ),
                ),
                ElevatedButton(
                  child: const Text('signData("hello world")'),
                  onPressed: () => _run(
                    context,
                    () => _eidmsdkPlugin.signData(
                      certIndex: 1,
                      signatureScheme: "1.2.840.113549.1.1.11",
                      dataToSign: "hello world",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Runs [action] and surfaces whatever comes back -- including thrown
  /// [EidmsdkException]s, which is how errors picked on the fake's
  /// error-picker screen are reported.
  Future<void> _run(
    BuildContext context,
    Future<dynamic> Function() action, {
    bool showSuccess = true,
  }) async {
    dynamic outcome;
    try {
      final result = await action();
      if (!showSuccess) return;
      outcome = result;
    } catch (e) {
      outcome = e;
    }

    debugPrint(outcome.toString());
    if (!context.mounted) return;

    showResult(context, outcome);
  }

  void showResult(BuildContext context, dynamic content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Result"),
        content: SingleChildScrollView(
          child: Text(content.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content.toString()));
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

/// Shown only when the fake implementation is standing in for the real SDK, so
/// that a canned certificate is never mistaken for one read off a real card.
class _FakeSdkBanner extends StatelessWidget {
  const _FakeSdkBanner();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Eidmsdk.isUsingFake(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: Colors.orange.shade100,
          padding: const EdgeInsets.all(12),
          child: Text(
            'Simulator detected: using the FAKE eID SDK.\n'
            'Certificates and signatures are real crypto from a public, '
            'worthless key — never trust them.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange.shade900),
          ),
        );
      },
    );
  }
}
