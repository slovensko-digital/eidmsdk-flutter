import Flutter
import UIKit
import eID

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
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  public func setLogLevel(args: [AnyHashable: Any], result: @escaping FlutterResult) {
    guard let rawLogLevel = args["logLevel"] as? Int else {
      print("\(String(describing: args["logLevel"])) couldn't be converted to logLevel")
      return
    }
    
    eidHandler.setLogLevel(eIDLogLevel(rawValue: rawLogLevel + 1)!)
    
    result(true)
  }
  
  public func showTutorial(result: @escaping FlutterResult) {
    eidHandler.showTutorial(from: findViewController()) {
      result(nil)
    }
  }
  
  public func getCertificates(args: [AnyHashable: Any], result: @escaping FlutterResult) {
    guard let rawTypes = args["types"] as? [Int] else {
      print("\(String(describing: args["types"])) couldn't be converted to types")
      return
    }
    
    let rootViewController = findViewController()
    
    let types: [eIDCertificateIndex] = rawTypes.map { type in
      eIDCertificateIndex(rawValue: type + 1)
    }.compactMap { $0 }
    
    eidHandler.getCertificates(from: rootViewController, types: types) { res in
      switch res {
      case .success(let certificatesJSONString):
        result(certificatesJSONString)
      case .failure(let error):
        result(FlutterError(code: "ERROR_READ_CERTIFICATE",
                            message: "Chyba pri načítaní podpisového certifikátu.",
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
