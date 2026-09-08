import Flutter
import UIKit
import eID
import CryptoKit

public class EidmsdkPlugin: NSObject, FlutterPlugin {
  private var eidHandler: eIDHandler

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "eidmsdk", binaryMessenger: registrar.messenger())
    let instance = EidmsdkPlugin(handler: eIDHandler())
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  init(handler: eIDHandler) {
    self.eidHandler = handler
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Answered before the argument check below, because it takes no arguments.
    // This is a compile-time answer, so it can never report true on real hardware.
    if call.method == "isSimulator" {
      #if targetEnvironment(simulator)
        result(true)
      #else
        result(false)
      #endif
      return
    }

    guard let args = call.arguments as? [AnyHashable: Any] else {
      result(FlutterError(code: "ERROR_PARSE_ARGUMENTS", message: "Error parsing arguments", details: call.arguments.debugDescription))
      return
    }

    switch call.method {
    case "setLogLevel":
      setLogLevel(args: args, result: result)
    case "showTutorial":
      showTutorial(result: result)
    case "getCertificates":
      getCertificates(args: args, result: result)
    case "signData":
      signData(args: args, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func setLogLevel(args: [AnyHashable: Any], result: @escaping FlutterResult) {
    guard let rawLogLevel = args["logLevel"] as? Int else {
      print("\(String(describing: args["logLevel"])) couldn't be converted to logLevel")
      return
    }

    // eIDLogLevel is 0-based (verbose = 0 ... none = 5) and EIDLogLevel on the
    // Dart side has the same members in the same order, so the index maps
    // straight across. It previously added 1 here, which shifted every level by
    // one and made `none` produce rawValue 6 -- nil, then a force-unwrap crash.
    guard let logLevel = eIDLogLevel(rawValue: rawLogLevel) else {
      result(FlutterError(code: "ERROR_INVALID_LOG_LEVEL",
                          message: "Unknown log level",
                          details: rawLogLevel))
      return
    }

    eidHandler.setLogLevel(logLevel)

    result(true)
  }

  public func showTutorial(result: @escaping FlutterResult) {
    eidHandler.showTutorial(from: findViewController(), environment: .minvProd) {
      result(nil)
    }
  }

  public func getCertificates(args: [AnyHashable: Any], result: @escaping FlutterResult) {
    guard let rawType = args["type"] as? Int else {
      result(FlutterError(code: "ERROR_PARSE_ARGUMENTS",
                          message: "Error parsing arguments",
                          details: "type"))
      return
    }

    // eIDCertificateIndex is 0-based (QES = 0, ES = 1, Encryption = 2) and
    // matches EIDCertificateIndex on the Dart side member for member, so the
    // index maps straight across. It previously added 1 here, which asked for ES
    // when the caller wanted QES and silently dropped Encryption altogether.
    guard let type = eIDCertificateIndex(rawValue: rawType) else {
      result(FlutterError(code: "ERROR_INVALID_CERTIFICATE_TYPE",
                          message: "Unknown certificate type",
                          details: rawType))
      return
    }

    eidHandler.getCertificates(from: findViewController(), types: [type]) { res in
      switch res {
      case .success(let certificatesJSONString):
        result(certificatesJSONString)
      case .failure(let error):
        result(FlutterError(code: String(describing: error),
                            message: "Chyba pri načítaní podpisového certifikátu.",
                            details: error.localizedDescription))
      }
    }
  }

  public func signData(args: [AnyHashable: Any], result: @escaping FlutterResult) {
    guard let certIndex = args["certIndex"] as? Int else {
      print("\(String(describing: args["certIndex"])) couldn't be converted to certIndex")
      return
    }

    guard let signatureScheme = args["signatureScheme"] as? String else {
      print("\(String(describing: args["signatureScheme"])) couldn't be converted to signatureScheme")
      return
    }

    guard let rawDataToSign = args["dataToSign"] as? String else {
      print("\(String(describing: args["dataToSign"])) couldn't be converted to dataToSign")
      return
    }

    guard let isBase64Encoded = args["isBase64Encoded"] as? Bool else {
      print("\(String(describing: args["isBase64Encoded"])) couldn't be converted to isBase64Encoded")
      return
    }

    lazy var rawData: Data = {
      if (isBase64Encoded) {
        return Data(base64Encoded: rawDataToSign.data(using: .utf8)!)!
      } else {
        return Data(rawDataToSign.utf8)
      }
    }()

    let dataToSign = Data(Array(SHA256.hash(data: rawData)))

    eidHandler.signData(from: findViewController(), certIndex: certIndex, signatureScheme: signatureScheme, dataToSign: dataToSign.base64EncodedString()) { res in
      switch res {
      case .success(let dataBase64):
        result(dataBase64)
      case .failure(let error):
        result(FlutterError(code: String(describing: error),
                            message: "Chyba pri podpisovaní.",
                            details: error.localizedDescription))
      }
    }
  }

  private func findViewController() -> UIViewController {
    return UIApplication.shared.windows.filter({ (w) -> Bool in
      return w.isHidden == false
    }).first!.rootViewController!
  }
}
