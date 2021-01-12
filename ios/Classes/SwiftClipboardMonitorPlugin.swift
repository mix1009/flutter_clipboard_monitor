import Flutter
import UIKit

public class SwiftClipboardMonitorPlugin: NSObject, FlutterPlugin {
    private  var channel: FlutterMethodChannel!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftClipboardMonitorPlugin()
        instance.channel = FlutterMethodChannel(name: "clipboard_monitor", binaryMessenger: registrar.messenger())

        registrar.addMethodCallDelegate(instance, channel: instance.channel)
    }

    @objc func pasteboardChanged(sender: NSNotification) {
        let pasteboardString: String? = UIPasteboard.general.string
        if let theString = pasteboardString {
            channel.invokeMethod("cliptext", arguments: theString)
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "monitorClipboard" {
            NotificationCenter.default.addObserver(self, selector: #selector(self.pasteboardChanged),
                                                   name: UIPasteboard.changedNotification, object: nil)
        } else if call.method == "stopMonitoringClipboard" {
            NotificationCenter.default.removeObserver(self, name: UIPasteboard.changedNotification, object: nil)
        }
    }
}
