// GENERATED FILE - DO NOT EDIT BY HAND.
//
// Regenerate with: tools/generate_fake_identity.sh
//
// This is a THROWAWAY, PUBLISHED keypair used only by SimulatorEidmsdk on
// simulators and emulators. It is self-signed, trusted by nobody, and its
// private key is committed on purpose so that fake signatures actually verify.
// Never treat a signature made with it as evidence of anything.

import 'dart:convert';
import 'dart:typed_data';

/// The fake signing identity: a self-signed RSA-2048 certificate for
/// `CN=Jozko Mrkvicka, L=Bratislava, C=SK`, plus its private key components.
class FakeIdentity {
  FakeIdentity._();

  static const String subjectCommonName = 'Jozko Mrkvicka';
  static const String subjectLocality = 'Bratislava';
  static const String subjectCountry = 'SK';

  static final BigInt modulus = BigInt.parse(
    '00ae494a1a161d1f28998829aecc5c877a0e548d2235919bfbc512188b1e1f84'
    '39f4bdb30a9985ffc8d9a62e39594d7cc6f470aed422558aea233ca53f5d05a8'
    '76c1fa3eb6ef92d698969fa542eb5e85a2d2f14da4a9752936cee75035a9fed1'
    '4ae8e94028b7cdcc9bdb2f5e58ca612713e003fff633095930dde280069eb706'
    '4816b6a431d1255d2b58204988aa3509231258d5ce7559407fdf1c2ba001f217'
    '2948d2321c0b880487cedb6f6e91c69b661c48903acbb3b1df1880a4ce816ddf'
    '64e8ca2502d4f8d62ffc34629f3fa31bcc0519910041555918dad8fd3d083755'
    '4eb6055d7d4c8e835e76d7e20a8fb6ed9f6d24ae94b6ed9fa69460863772eabc'
    'd5',
    radix: 16,
  );

  static final BigInt privateExponent = BigInt.parse(
    '041d4dd1b4d64629deb4af6090342fac957c5b2d44bcd06fb954cbddde3daf3b'
    '9bb2ae1b361ef58d67cf5105b5e7d590c58232d666386fc446f05914585d5854'
    '9ebab4d2a6703dd45cb09dd053c9d24cd2e9b3196138c2057db7f495a26840c7'
    'a1c7a93b422f951629840243055ac021eb7c1cb052bf1f4069e9e8222a8ab696'
    'b60c6aadc86880ddb0af6f826c8c42a8d5540384ccaa3c80671bc7e61707298e'
    '5fcf7c8a5b8d78c0136f9ed50f59343278c50b1e57ecd3075357a9ad5b580018'
    'c456a7526e62987e0182bb13a1a50d5ec513f7faa33567af78740ce9993ea7cc'
    '5c3292c11e78c58217d1950d9a01fd73b0f8a79cf14af2ee04e9f2c4f2fe9d47',
    radix: 16,
  );

  static final BigInt prime1 = BigInt.parse(
    '00ed08b2644a071fdef6f51f94d16ea98776fae738cf800ba48d2214b4547b5a'
    '895ac749f2436af16ac35883ef88924290fb37dce2750b954c7bf8556c1d859a'
    '3f962e94f027cc0dcbcb4590aaa4b184a464334e061950c694f03a2b5387a97e'
    '6f85f92205d344edac1de3978264a3e415eb52a64559adcc0f498d55a3182410'
    'c3',
    radix: 16,
  );

  static final BigInt prime2 = BigInt.parse(
    '00bc3b4bb30a090ad3d4ab488809a3906e8523299a7187463c2748d24d574546'
    'dd173d112b3a56e1b6f35949f948a4ccb5f8e901fc94e600b1e0bba7e06a3f02'
    'b20861fb800383d646056782f11808103fa11bb26d50cc31bd564756e48a310f'
    'ed39a7dbe12aee4ea703a801882f8de69822c268e5ad1372071dd2fe7600e422'
    '87',
    radix: 16,
  );

  static final BigInt publicExponent = BigInt.from(65537);

  /// The certificate, DER-encoded and base64-wrapped. Returned verbatim as
  /// `Certificate.certData`, exactly as the real SDK returns a certificate.
  static const String certificateBase64 =
      'MIIDZDCCAkygAwIBAgIUU3EiqY2iql/sApkRp18UoQYzFjwwDQYJKoZIhvcNAQEL'
      'BQAwOzELMAkGA1UEBhMCU0sxEzARBgNVBAcMCkJyYXRpc2xhdmExFzAVBgNVBAMM'
      'DkpvemtvIE1ya3ZpY2thMB4XDTIwMDEwMTAwMDAwMFoXDTQwMDEwMTAwMDAwMFow'
      'OzELMAkGA1UEBhMCU0sxEzARBgNVBAcMCkJyYXRpc2xhdmExFzAVBgNVBAMMDkpv'
      'emtvIE1ya3ZpY2thMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArklK'
      'GhYdHyiZiCmuzFyHeg5UjSI1kZv7xRIYix4fhDn0vbMKmYX/yNmmLjlZTXzG9HCu'
      '1CJViuojPKU/XQWodsH6PrbvktaYlp+lQutehaLS8U2kqXUpNs7nUDWp/tFK6OlA'
      'KLfNzJvbL15YymEnE+AD//YzCVkw3eKABp63BkgWtqQx0SVdK1ggSYiqNQkjEljV'
      'znVZQH/fHCugAfIXKUjSMhwLiASHzttvbpHGm2YcSJA6y7Ox3xiApM6Bbd9k6Mol'
      'AtT41i/8NGKfP6MbzAUZkQBBVVkY2tj9PQg3VU62BV19TI6DXnbX4gqPtu2fbSSu'
      'lLbtn6aUYIY3cuq81QIDAQABo2AwXjAdBgNVHQ4EFgQUPIJVTHIBHVPKzTooWDkF'
      '0fvlHiYwHwYDVR0jBBgwFoAUPIJVTHIBHVPKzTooWDkF0fvlHiYwDgYDVR0PAQH/'
      'BAQDAgbAMAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggEBABENg5zIQxl0'
      'wXlqEcfkcCKsHfg8ADZRxuBUZwwD7XZKeH7tv0KLmmrZAklvMrzmCM54QCq9RdJA'
      'dWIsrMGQfg1f9TW0riqj/EI7Mxb9/s8tJYGI/Xz/u96L3KhguUvQ+l3J/4QDEBgr'
      'YfRamStZmeOjqMpbJ4mhT+egN0rUFB6VPjkcFiptlqjTjCwfXuaNxfTVyZV+wGwP'
      '7VfEaK47LLRvK9b9V34wroxNJn/rbTi7VjM6GjrR/a3lV53mqael1Rn7gEH05c0F'
      'L3i4BRLR3toA+Ed1+DsmgxjsH2f76L/CzRQex2/umlzT1ZJ5uyl9VlcwA9JaPHwX'
      'UymJZ8b2AcE=';

  static Uint8List get certificateDer =>
      Uint8List.fromList(base64Decode(certificateBase64));
}
