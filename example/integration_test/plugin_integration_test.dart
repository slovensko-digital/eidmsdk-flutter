// End-to-end test of the simulator fake, run against a real iOS Simulator or
// Android emulator. Unlike the unit tests it does not mock the method channel,
// so it also covers the native `isSimulator` implementations.
//
//   flutter test integration_test -d <simulator-or-emulator-id>

import 'dart:convert';

import 'package:eidmsdk/eidmsdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final plugin = Eidmsdk();

  testWidgets('the fake is selected automatically on a simulated host',
      (WidgetTester tester) async {
    expect(
      await Eidmsdk.isUsingFake(),
      isTrue,
      reason: 'run this against a simulator or emulator, not a real device',
    );
  });

  testWidgets('getCertificates returns the canned payload',
      (WidgetTester tester) async {
    // Without autoRespond the fake would present a blocking screen and this
    // test would hang until it timed out waiting for a tap that never comes.
    SimulatorEidmsdk.autoRespond = const FakeProceed();
    addTearDown(() => SimulatorEidmsdk.autoRespond = null);

    final result =
        await plugin.getCertificates(types: [EIDCertificateIndex.qes]);

    expect(result, isNotNull);
    expect(result!.cardType, contains('SIMULATOR'));
    expect(result.certificates.single.slot, 'QES');
  });

  testWidgets('signData returns a real signature', (WidgetTester tester) async {
    // Same reasoning as above: signData also presents a blocking screen
    // unless a response is pre-selected.
    SimulatorEidmsdk.autoRespond = const FakeProceed();
    addTearDown(() => SimulatorEidmsdk.autoRespond = null);

    final signature = await plugin.signData(
      certIndex: 1,
      signatureScheme: '1.2.840.113549.1.1.11',
      dataToSign: 'hello world',
    );

    // 2048-bit RSA signature, base64-encoded.
    expect(signature, isNotNull);
    expect(base64Decode(signature!).length, 256);
  });
}
