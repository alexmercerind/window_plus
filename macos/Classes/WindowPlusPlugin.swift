import Cocoa
import FlutterMacOS

public class WindowPlusPlugin: NSObject, FlutterPlugin, NSApplicationDelegate, NSWindowDelegate {
    static let kMethodChannelName = "com.alexmercerind/window_plus"
    static let kSingleInstanceNotificationNamePrefix = "com.alexmercerind/window_plus/single_instance/"
    
    static let kEnsureInitializedMethodName = "ensureInitialized"
    static let kSetMinimumSizeMethodName = "setMinimumSize"
    static let kWindowCloseReceivedMethodName = "windowCloseReceived"
    static let kNotifyFirstFrameRasterizedMethodName = "notifyFirstFrameRasterized"
    static let kSingleInstanceDataReceivedMethodName = "singleInstanceDataReceived"
    static let kGetIsFullscreenMethodName = "getIsFullscreen"
    static let kSetIsFullscreenMethodName = "setIsFullscreen"
    static let kCloseMethodName = "close"
    static let kDestroyMethodName = "destroy"
    
    static let kGetCaptionHeight = "getCaptionHeight"
    
    static var hideUntilReadyInvoked = false
    
    var channel: FlutterMethodChannel
    var view: NSView
    
    var destroyInvoked = false
    
    init(channel: FlutterMethodChannel, view: NSView) {
        self.channel = channel
        self.view = view
        super.init()
        
        NSApplication.shared.delegate = self
        view.window?.delegate = self
        
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(WindowPlusPlugin.kSingleInstanceNotificationNamePrefix + Bundle.main.bundleIdentifier!),
            object: nil,
            queue: nil
        ) { notification in
            self.channel.invokeMethod(WindowPlusPlugin.kSingleInstanceDataReceivedMethodName, arguments: [notification.object])
        }
    }
    
    public static func hideUntilReady() {
        if !hideUntilReadyInvoked {
            hideUntilReadyInvoked = true
            NSApplication.shared.windows.forEach { $0.setIsVisible(false) }
        }
    }
    
    public static func handleSingleInstance() {
        let arguments = CommandLine.arguments
        let application = NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
            .first { $0.processIdentifier != getpid() }
        let object = arguments.count <= 1 ? nil : arguments[1]
        if let application = application {
            DistributedNotificationCenter.default().post(
                name: Notification.Name(kSingleInstanceNotificationNamePrefix + Bundle.main.bundleIdentifier!),
                object: object,
                userInfo: nil
            )
            _ = try? NSWorkspace.shared.launchApplication(at: application.bundleURL!,
                                                          options: .default,
                                                          configuration: [:])
            NSApplication.shared.terminate(self)
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: WindowPlusPlugin.kMethodChannelName, binaryMessenger: registrar.messenger)
        let view = registrar.view
        let instance = WindowPlusPlugin(channel: channel, view: view!)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case WindowPlusPlugin.kEnsureInitializedMethodName:
            // NO/OP
            result(Int(bitPattern: Unmanaged.passUnretained(view.window!).toOpaque()))
        case WindowPlusPlugin.kNotifyFirstFrameRasterizedMethodName:
            view.window?.setIsVisible(true)
            NSApplication.shared.activate(ignoringOtherApps: true)
            result(nil)
        case WindowPlusPlugin.kGetIsFullscreenMethodName:
            result(view.window?.styleMask.contains(.fullScreen) ?? false)
        case WindowPlusPlugin.kSetIsFullscreenMethodName:
            let arguments = call.arguments as! Dictionary<String, Any>
            let enabled = arguments["enabled"] as! Bool
            if (view.window?.styleMask.contains(.fullScreen) ?? false) != enabled {
                view.window?.toggleFullScreen(self)
            }
            result(nil)
        case WindowPlusPlugin.kSetMinimumSizeMethodName:
            let arguments = call.arguments as! Dictionary<String, Any>
            let width = arguments["width"] as! NSNumber
            let height = arguments["height"] as! NSNumber
            view.window?.contentMinSize = NSSize(width: width.doubleValue, height: height.doubleValue)
            result(nil)
        case WindowPlusPlugin.kCloseMethodName:
            view.window?.close()
            result(nil)
        case WindowPlusPlugin.kDestroyMethodName:
            destroyInvoked = true
            NSApplication.shared.terminate(self)
            result(nil)
        case WindowPlusPlugin.kGetCaptionHeight:
            result((view.window?.contentView?.frame.height ?? 0) - (view.window?.contentLayoutRect.height ?? 0))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        channel.invokeMethod(WindowPlusPlugin.kWindowCloseReceivedMethodName, arguments: nil)
        return false
    }
    
    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        channel.invokeMethod(WindowPlusPlugin.kWindowCloseReceivedMethodName, arguments: nil)
        return destroyInvoked ? .terminateNow : .terminateCancel
    }
}