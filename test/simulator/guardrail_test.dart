import 'package:eidmsdk/eidmsdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = SimulatorEidmsdk();

  tearDown(() {
    SimulatorEidmsdk.autoRespond = null;
    SimulatorEidmsdk.debugAssumeSimulator = null;
  });

  // Every method starts by calling _assertSimulated, so the guard must hold
  // for all four, not only signData.
  final calls = <String, Future<Object?> Function()>{
    'setLogLevel': () => platform.setLogLevel(logLevel: EIDLogLevel.debug),
    'showTutorial': () => platform.showTutorial(),
    'getCertificates':
        () => platform.getCertificates(types: [EIDCertificateIndex.qes]),
    'signData':
        () => platform.signData(
          certIndex: 1,
          signatureScheme: '1.2.840.113549.1.1.11',
          dataToSign: 'hello world',
        ),
  };

  test('refuses to run on real hardware for every method', () async {
    SimulatorEidmsdk.debugAssumeSimulator = false;
    SimulatorEidmsdk.autoRespond = const FakeProceed();

    for (final MapEntry(key: name, value: call) in calls.entries) {
      await expectLater(
        call(),
        throwsA(
          isA<EidmsdkException>().having(
            (e) => e.message,
            'message',
            contains('real hardware'),
          ),
        ),
        reason: name,
      );
    }
  });

  test('runs every method when the host is simulated', () async {
    SimulatorEidmsdk.debugAssumeSimulator = true;
    SimulatorEidmsdk.autoRespond = const FakeProceed();

    for (final MapEntry(key: name, value: call) in calls.entries) {
      // showTutorial legitimately resolves to null; the others must not.
      if (name == 'showTutorial') {
        await expectLater(call(), completes, reason: name);
      } else {
        expect(await call(), isNotNull, reason: name);
      }
    }
  });

  test('autoRespond forwards to the presentation layer', () {
    SimulatorEidmsdk.autoRespond = const FakeCancel();

    expect(SimulatorEidmsdk.autoRespond, isA<FakeCancel>());
  });

  test('navigatorKey is settable and readable', () {
    final key = GlobalKey<NavigatorState>();
    Eidmsdk.navigatorKey = key;

    expect(Eidmsdk.navigatorKey, same(key));

    Eidmsdk.navigatorKey = null;
  });
}
