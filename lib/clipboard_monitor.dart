import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

// typedef OnClipboardTextFunction = void Function(String text);

class ClipboardMonitor {
  static const MethodChannel _channel = const MethodChannel('clipboard_monitor');

  static var _monitoring = false;

  static final _callbacks = List<Function(String)>();

  static Future<void> _startMonitoring() async {
    _monitoring = true;
    _channel.setMethodCallHandler(_handleMethodCall);
    await _channel.invokeMethod('monitorClipboard');
  }

  static Future<void> _stopMonitoring() async {
    _monitoring = false;
    await _channel.invokeMethod('stopMonitoringClipboard');
  }

  static void registerCallback(Function(String) func) {
    if (!_monitoring) {
      _startMonitoring();
    }
    _callbacks.add(func);
  }

  static void unregisterCallback(Function(String) func) {
    _callbacks.remove(func);

    if (Platform.isAndroid && _callbacks.isEmpty) {
      // remove the listener since there are no callbacks registered.
      // nb: Not implemented on iOS yet so this will only affect android
      _stopMonitoring();
    }
  }

  static void unregisterAllCallbacks() {
    _callbacks.clear();

    if (Platform.isAndroid) {
      _stopMonitoring();
    }
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    final args = call.arguments as String;

    if (call.method == 'cliptext') {
      _callbacks.forEach((cb) => cb(args));
    }
  }
}
