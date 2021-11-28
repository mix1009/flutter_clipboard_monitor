import Cocoa
import FlutterMacOS

// Inspiration:
// https://stackoverflow.com/questions/5033266/can-i-receive-a-callback-whenever-an-nspasteboard-is-written-to
// https://gist.github.com/Daemon-Devarshi/13efd24f027a775ee862
// https://github.com/p0deje/Maccy/blob/master/Maccy/Clipboard.swift
// https://learnappmaking.com/timer-swift-how-to/

public class ClipboardMonitorPlugin: NSObject, FlutterPlugin {
  private let pasteboard = NSPasteboard.general
  private let timerInterval = 0.5
  private var timer = Timer()
  private var changeCount: Int
    
  static var channel: FlutterMethodChannel?

  private var sourceApp: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }
  
  override init() {
    changeCount = pasteboard.changeCount
    super.init()
  }
  
  func monitorClipboard() {
    timer = Timer.scheduledTimer(timeInterval: timerInterval,
                         target: self,
                         selector: #selector(checkForChangesInPasteboard),
                         userInfo: nil,
                         repeats: true)
    timer.tolerance = 0.2 * timerInterval
  }

  func stopMonitoringClipboard() {
    timer.invalidate()
  }
  
  @objc
  func checkForChangesInPasteboard() {
    guard pasteboard.changeCount != changeCount else {
      return
    }
    
    // Some applications add 2 items to pasteboard when copying:
    //   1. The proper meaningful string.
    //   2. The empty item with no data and types.
    // An example of such application is BBEdit.
    // To handle such cases, handle all new pasteboard items,
    // not only the last one.
    // See https://github.com/p0deje/Maccy/issues/78.
    pasteboard.pasteboardItems?.forEach({ item in
      let types = Set(item.types)
      if (types.contains(.string) && !isEmptyString(item)) {
        ClipboardMonitorPlugin.channel?.invokeMethod("cliptext", arguments: item.string(forType: .string)!)
      }
    })
    
    changeCount = pasteboard.changeCount
  }

  private func isEmptyString(_ item: NSPasteboardItem) -> Bool {
    guard let string = item.string(forType: .string) else {
      return true
    }

    return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "clipboard_monitor", binaryMessenger: registrar.messenger)
    let instance = ClipboardMonitorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel!)
  }
  
//  @objc func pasteboardChanged(sender: NSNotification) {
//      let pasteboardString: String? = UIPasteboard.general.string
//      if let theString = pasteboardString {
//          channel.invokeMethod("cliptext", arguments: theString)
//      }
//  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "monitorClipboard":
      monitorClipboard()
    case "stopMonitoringClipboard":
      stopMonitoringClipboard()
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
