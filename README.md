# clipboard_monitor

Flutter plugin for monitoring system clipboard on Android and iOS.

## Usage
```
import 'package:clipboard_monitor/clipboard_monitor.dart';

void startClipboardMonitor()  {
    ClipboardMonitor.registerCallback(onClipboardText);
}

void stopClipboardMonitor()  {
    ClipboardMonitor.unregisterCallback(onClipboardText);
}

void onClipboardText(String text) {
    print("clipboard changed: $text");
}

void stopAllClipboardMonitoring() {
    ClipboardMonitor.unregisterAllCallbacks();
}

```

## Limitations

Clipboard monitoring will not work when app is not running.
Also Android 10 (API level 29) and above restricts access to clipboard when app is not in focus.

## Contributors

[jinyus](https://github.com/jinyus)