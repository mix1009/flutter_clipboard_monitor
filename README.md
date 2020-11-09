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

```

