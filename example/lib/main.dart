import 'dart:convert';

import 'package:eidmsdk/eidmsdk_platform_interface.dart';
import 'package:flutter/material.dart';

import 'package:eidmsdk/eidmsdk.dart';
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
              children: [
                ...EIDLogLevel.values.map((e) => ElevatedButton(
                      child: Text('setLogLevel(logLevel: ${e.name})'),
                      onPressed: () async {
                        final result =
                            await _eidmsdkPlugin.setLogLevel(logLevel: e);
                        print(result);
                        if (!context.mounted) return;
                        showResult(context, result);
                      },
                    )),
                ElevatedButton(
                  child: const Text('showTutorial()'),
                  onPressed: () async {
                    await _eidmsdkPlugin.showTutorial();
                  },
                ),
                ...EIDCertificateIndex.values.map(
                  (e) => ElevatedButton(
                    child: Text('getCertificates(types: [${e.name}])'),
                    onPressed: () async {
                      final result =
                          await _eidmsdkPlugin.getCertificates(types: [e]);
                      print(result);
                      if (!context.mounted) return;
                      showResult(context, jsonEncode(result));
                    },
                  ),
                ),
                ElevatedButton(
                  child: const Text(
                      'signData(certIndex: 1, dataToSign: "hello world")'),
                  onPressed: () async {
                    final result = await _eidmsdkPlugin.signData(
                        certIndex: 1,
                        signatureScheme: "1.2.840.113549.1.1.11",
                        dataToSign: "hello world");
                    print(result);
                    if (!context.mounted) return;

                    showResult(context, result);
                  },
                ),
                ElevatedButton(
                  child: const Text('showResult'),
                  onPressed: () async {
                    showResult(context, 'hello world');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
