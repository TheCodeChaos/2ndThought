import Flutter
import UIKit
import FamilyControls

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private let channelName = "com.neurogate.app/blocker"
    private let eventChannelName = "com.neurogate.app/blocker_events"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        
        // Use the applicationRegistrar's messenger to set up channels
        let binaryMessenger = engineBridge.applicationRegistrar.messenger()
        
        let methodChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: binaryMessenger
        )
        
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "requestAuthorization":
                self?.requestScreenTimeAuthorization(result: result)
                
            case "checkAuthorizationStatus":
                self?.checkScreenTimeStatus(result: result)
                
            case "syncBlockedApps":
                // Would trigger FamilyActivityPicker on real device with entitlement
                result(nil)
                
            case "grantSession":
                // Would clear ManagedSettingsStore shields temporarily
                result(nil)
                
            case "checkAccessibilityEnabled":
                // Not applicable on iOS, return false
                result(false)
                
            case "openAccessibilitySettings":
                // Not applicable on iOS
                result(nil)
                
            case "goToLauncher":
                // iOS doesn't support programmatic "go to home"
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        let eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: binaryMessenger
        )
        eventChannel.setStreamHandler(BlockerEventStreamHandler())
    }
    
    private func requestScreenTimeAuthorization(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            Task {
                do {
                    // NOTE: Full Family Controls implementation requires:
                    // 1. com.apple.developer.family-controls entitlement in Xcode
                    // 2. FamilyActivitySelection configuration
                    // For simulator/basic testing, return true after a delay to simulate user approval
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                    DispatchQueue.main.async {
                        result(true)
                    }
                } catch {
                    print("Authorization request error: \(error)")
                    DispatchQueue.main.async {
                        result(false)
                    }
                }
            }
        } else {
            result(false)
        }
    }
    
    private func checkScreenTimeStatus(result: @escaping FlutterResult) {
        // For simulator/testing without Family Controls entitlements, return false
        // On real device with proper entitlements:
        // if #available(iOS 16.0, *) {
        //     let status = AuthorizationCenter.shared.authorizationStatus
        //     result(status == .approved)
        // } else {
        result(false)
        // }
    }
}

class BlockerEventStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Store event sink for later use when a blocked app is detected
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}
