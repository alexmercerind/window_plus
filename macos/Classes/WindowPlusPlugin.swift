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
    static let kGetIsMaximizedMethodName = "getMaximized"
    static let kMaximizeMethodName = "maximize"
    static let kRestoreMethodName = "restore"
    
    static let kGetCaptionHeight = "getCaptionHeight"
    
    // HACK: Save NSView as static variable to access in C linking.
    static var view: NSView?
    static var hideUntilReadyInvoked = false
    
    var channel: FlutterMethodChannel
    var view: NSView
    var urls: [String]?
    
    var destroyInvoked = false
    
    init(channel: FlutterMethodChannel, view: NSView) {
        WindowPlusPlugin.view = view
        
        self.channel = channel
        self.view = view
        super.init()
        
        NSApplication.shared.delegate = self
        view.window?.delegate = self
        
        // There's a race condition... add a bit of delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.urls != nil {
                self.channel.invokeMethod(
                    WindowPlusPlugin.kSingleInstanceDataReceivedMethodName,
                    arguments: self.urls
                )
            }
        }
    }
    
    public static func hideUntilReady() {
        if !hideUntilReadyInvoked {
            hideUntilReadyInvoked = true
            NSApplication.shared.windows.forEach { $0.setIsVisible(false) }
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
            view.window?.makeKeyAndOrderFront(self)
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
        case WindowPlusPlugin.kGetIsMaximizedMethodName:
            result(view.window?.isZoomed ?? false)
        case WindowPlusPlugin.kMaximizeMethodName:
            if view.window?.isZoomed == false {
                view.window?.zoom(nil)
            }
            result(nil)
        case WindowPlusPlugin.kRestoreMethodName:
            if view.window?.isZoomed == true {
                view.window?.zoom(nil)
            }
            result(nil)
        case WindowPlusPlugin.kGetCaptionHeight:
            result((view.window?.contentView?.frame.height ?? 0) - (view.window?.contentLayoutRect.height ?? 0))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func application(_ application: NSApplication, open urls: [URL]) {
        self.urls = urls.map { url in url.absoluteString }
        self.channel.invokeMethod(
            WindowPlusPlugin.kSingleInstanceDataReceivedMethodName,
            arguments: self.urls
        )
        view.window?.makeKeyAndOrderFront(self)
        NSApplication.shared.activate(ignoringOtherApps: true)
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

// --------------------------------------------------

@_cdecl("getCaptionHeight")
public func getCaptionHeight() -> Float {
    let view = WindowPlusPlugin.view
    return Float((view?.window?.contentView?.frame.height ?? 0) - (view?.window?.contentLayoutRect.height ?? 0))
}

// --------------------------------------------------
