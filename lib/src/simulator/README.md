# `lib/src/simulator/` — the fake eID SDK

Everything here is private to the package. The only public entry point is
`SimulatorEidmsdk` in `lib/eidmsdk_simulator.dart`; nothing in this folder is
exported.

**Read `CLAUDE.md` at the repo root before editing.** Its "Why the simulator
machinery exists" and "Two design rules worth preserving" sections cover the
things that are easy to break here: the committed-on-purpose keypair, why errors
reuse `Eidmsdk.decodeNativeError` instead of a second mapping table, the one
unsupported API in `fake_ui.dart`, and why tests must set
`SimulatorEidmsdk.autoRespond`.

## Layout

| File | Role |
| --- | --- |
| `fake_ui.dart` | Presents the screens with no help from the host app. Also holds `autoRespond`. |
| `fake_outcome.dart` | Sealed `FakeProceed` / `FakeError` / `FakeCancel` — what the user picked. |
| `fake_errors.dart` | Catalogue of real eID error codes the fake can raise. |
| `fake_identity.dart` | **Generated** by `tools/generate_fake_identity.sh` — the throwaway RSA-2048 keypair and certificate. Do not hand-edit. |
| `fake_signer.dart` | RSA PKCS#1 v1.5 over SHA-256, mirroring what the real SDK is asked to do. |
| `fake_platform.dart` | Which platform the fake pretends to be, so both cancellation behaviours are testable anywhere. |
| `screens/` | The four screens — certificates, sign, tutorial, error picker — all wrapped in `fake_scaffold.dart`'s banner chrome. |

Tests live in `test/simulator/`, mirroring this layout, with one widget test per
screen.
