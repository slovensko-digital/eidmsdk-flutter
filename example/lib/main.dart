import 'dart:convert';

import 'package:eidmsdk/eidmsdk_platform_interface.dart';
import 'package:flutter/material.dart';

import 'package:eidmsdk/eidmsdk.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});

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
                      child: Text('setLogLevel(${e.name})'),
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
                    child: Text('getCertificates(${e.name})'),
                    onPressed: () async {
                      final result =
                          await _eidmsdkPlugin.getCertificates(types: [e]);
                      print(result);
                      if (!context.mounted) return;
                      showResult(context, result);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showResult(BuildContext context, dynamic result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Result"),
        content: Text(jsonEncode(result)),
      ),
    );
  }
}
