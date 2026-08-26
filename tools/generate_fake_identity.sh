#!/usr/bin/env bash
#
# Generates the fake signing identity used by SimulatorEidmsdk and writes it to
# lib/src/simulator/fake_identity.dart.
#
# This is a THROWAWAY, PUBLISHED keypair. It exists so that a developer without
# a card can produce signatures that actually verify. It is self-signed, trusted
# by nobody, and its private key is committed to this repository on purpose.
#
# Re-run only if the identity must change; the output is committed, so a normal
# checkout never needs to run this.
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO/lib/src/simulator/fake_identity.dart"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A wide, fixed validity window: a certificate that expires would start failing
# tests years from now, and the failure would be hard to attribute.
openssl req -x509 -newkey rsa:2048 \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -nodes -sha256 \
  -subj "/C=SK/L=Bratislava/CN=Jozko Mrkvicka" \
  -addext "keyUsage=critical,digitalSignature,nonRepudiation" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -not_before 20200101000000Z -not_after 20400101000000Z

openssl x509 -in "$TMP/cert.pem" -outform DER -out "$TMP/cert.der"

mkdir -p "$(dirname "$OUT")"

OUT="$OUT" python3 - "$TMP" <<'PY'
import base64, os, pathlib, re, subprocess, sys

tmp = pathlib.Path(sys.argv[1])
text = subprocess.run(
    ['openssl', 'rsa', '-in', str(tmp / 'key.pem'), '-text', '-noout'],
    capture_output=True, text=True, check=True).stdout


def component(label):
    match = re.search(rf'^{label}:\n((?:\s+[0-9a-f:]+\n)+)', text, re.M)
    if not match:
        raise SystemExit(f'could not parse {label} from openssl output')
    return re.sub(r'[^0-9a-f]', '', match.group(1))


def wrap(hex_digits):
    # 4-space continuation indent matches what `dart format` produces for a
    # wrapped function-call argument, so the generated file is format-stable.
    chunks = [hex_digits[i:i + 64] for i in range(0, len(hex_digits), 64)]
    return "\n    '".join(f"{c}'" for c in chunks)


der = (tmp / 'cert.der').read_bytes()
cert_b64 = base64.b64encode(der).decode()
cert_lines = "\n      '".join(
    f"{cert_b64[i:i + 64]}'" for i in range(0, len(cert_b64), 64))

pathlib.Path(os.environ['OUT']).write_text(f'''// GENERATED FILE - DO NOT EDIT BY HAND.
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
class FakeIdentity {{
  FakeIdentity._();

  static const String subjectCommonName = 'Jozko Mrkvicka';
  static const String subjectLocality = 'Bratislava';
  static const String subjectCountry = 'SK';

  static final BigInt modulus = BigInt.parse(
    '{wrap(component('modulus'))},
    radix: 16,
  );

  static final BigInt privateExponent = BigInt.parse(
    '{wrap(component('privateExponent'))},
    radix: 16,
  );

  static final BigInt prime1 = BigInt.parse(
    '{wrap(component('prime1'))},
    radix: 16,
  );

  static final BigInt prime2 = BigInt.parse(
    '{wrap(component('prime2'))},
    radix: 16,
  );

  static final BigInt publicExponent = BigInt.from(65537);

  /// The certificate, DER-encoded and base64-wrapped. Returned verbatim as
  /// `Certificate.certData`, exactly as the real SDK returns a certificate.
  static const String certificateBase64 =
      '{cert_lines};

  static Uint8List get certificateDer =>
      Uint8List.fromList(base64Decode(certificateBase64));
}}
''')
print('wrote', os.environ['OUT'])
PY
