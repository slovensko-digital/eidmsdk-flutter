import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = SimulatorEidmsdk();

  tearDown(() {
    SimulatorEidmsdk.autoRespond = null;
    SimulatorEidmsdk.debugAssumeSimulator = null;
  });

  test('refuses to run on real hardware', () async {
    SimulatorEidmsdk.debugAssumeSimulator = false;
    SimulatorEidmsdk.autoRespond = const FakeProceed();

    await expectLater(
      platform.signData(
        certIndex: 1,
        signatureScheme: '1.2.840.113549.1.1.11',
        dataToSign: 'hello world',
      ),
      throwsA(
        isA<EidmsdkException>().having(
          (e) => e.message,
          'message',
          contains('real hardware'),
        ),
      ),
    );
  });

  test('runs when the host is simulated', () async {
    SimulatorEidmsdk.debugAssumeSimulator = true;
    SimulatorEidmsdk.autoRespond = const FakeProceed();

    expect(
      await platform.signData(
        certIndex: 1,
        signatureScheme: '1.2.840.113549.1.1.11',
        dataToSign: 'hello world',
      ),
      isNotNull,
    );
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
