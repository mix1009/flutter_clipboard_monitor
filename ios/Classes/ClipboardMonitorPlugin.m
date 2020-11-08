#import "ClipboardMonitorPlugin.h"
#if __has_include(<clipboard_monitor/clipboard_monitor-Swift.h>)
#import <clipboard_monitor/clipboard_monitor-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "clipboard_monitor-Swift.h"
#endif

@implementation ClipboardMonitorPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftClipboardMonitorPlugin registerWithRegistrar:registrar];
}
@end
