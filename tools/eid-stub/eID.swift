//
//  eID.swift — SIMULATOR STUB
//
//  This is NOT the real eID mSDK. It is a hand-written stand-in that exists only
//  so that the `eidmsdk` plugin can be compiled and linked for the iOS Simulator,
//  where the real, device-only `eID.framework` cannot be used (it ships a single
//  arm64-apple-ios slice and requires NFC hardware).
//
//  It declares exactly the subset of the real SDK's public API that
//  `ios/Classes/EidmsdkPlugin.swift` references — no more. Keeping it minimal is
//  deliberate: if the plugin starts using another SDK symbol, the simulator build
//  fails immediately, which is the signal we want.
//
//  At runtime these methods are never reached: `SimulatorEidmsdk` (Dart) intercepts
//  every call before it can reach the method channel. They still fail honestly,
//  with `.nfcNotSupported`, in case that ever changes.
//
//  Regenerate the framework with: tools/build_eid_stub.sh
//  Case names and raw values are copied verbatim from the real SDK's
//  arm64-apple-ios.swiftinterface so that `String(describing:)` error codes and
//  enum raw values stay identical to the device build.
//

import Foundation
import UIKit

public enum eIDLogLevel: Int, CaseIterable {
    case verbose
    case debug
    case info
    case warning
    case error
    case none
}

public enum eIDCertificateIndex: Int, Codable, CaseIterable {
    case QES
    case ES
    case Encryption
}

@frozen public enum eIDEnvironment {
    case minvTest
    case minvProd
}

public enum eIDError: Swift.Error, Swift.Equatable {
    case unknownTag
    case unsupportedCardType
    case nfcNotSupported
    case jailbreakDetected
    case certificatesNotIssued
    case qrNotSupported
    case usedTCTokenQRCode
    case deeplinkNotSupported
    case invalidClientIdOrSecret
    case unsupportedSignatureScheme
    case invalidCertificateIndex
    case unsupportedSigningCertificate
    case unsupportedDecryptionCertificate
    case unsupportedSDKVersion
    case tagConnectionLost
    case cancelledByUser
    case sessionTimeout
    case certificateReadFailed
    case userDataReadFailed
    case signingFailed
    case decryptionFailed
    case authInitFailed
    case authCompletionFailed
    case unableToReadCodeStates
    case networkError(Swift.String)
    case bokInvalid
    case bokSuspended
    case bokBlocked
    case bokNotActivated
    case canInvalid
    case mrzInvalid
    case kepPinInvalid
    case kepPinSuspended
    case kepPinBlocked
    case kepPinNotActivated
}

public class eIDHandler {
    public init() {}

    public func setLogLevel(_ logLevel: eIDLogLevel) {
        // no-op
    }

    public func showTutorial(
        from viewController: UIViewController,
        environment: eIDEnvironment,
        completion: (() -> ())? = nil
    ) {
        NSLog("[eID STUB] showTutorial is not available on the simulator.")
        completion?()
    }

    public func getCertificates(
        from viewController: UIViewController,
        types: [eIDCertificateIndex],
        completion: @escaping (Swift.Result<Swift.String, eIDError>) -> ()
    ) {
        NSLog("[eID STUB] getCertificates is not available on the simulator.")
        completion(.failure(.nfcNotSupported))
    }

    public func signData(
        from viewController: UIViewController,
        certIndex: Swift.Int,
        signatureScheme: Swift.String,
        dataToSign: Swift.String,
        completion: @escaping (Swift.Result<Swift.String, eIDError>) -> ()
    ) {
        NSLog("[eID STUB] signData is not available on the simulator.")
        completion(.failure(.nfcNotSupported))
    }
}
