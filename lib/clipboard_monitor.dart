import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardMonitor {
  static const MethodChannel _channel =
      const MethodChannel('clipboard_monitor');

  static var _monitoring = false;

  static final _callbacks = List<Function(String)>.empty(growable: true);

  static Future<void> _startMonitoring() async {
    _monitoring = true;
    _channel.setMethodCallHandler(_handleMethodCall);
    await _channel.invokeMethod('monitorClipboard');
  }

  static Future<void> _stopMonitoring() async {
    _monitoring = false;
    await _channel.invokeMethod('stopMonitoringClipboard');
  }

  /// register callback for monitoring clipboard
  static void registerCallback(Function(String) func) {
    if (!_monitoring) {
      _startMonitoring();
    }
    _callbacks.add(func);
  }

  /// unregister callback for monitoring
  static void unregisterCallback(Function(String) func) {
    _callbacks.remove(func);

    if (_callbacks.isEmpty) {
      _stopMonitoring();
    }
  }

  /// unregister all callbacks
  static void unregisterAllCallbacks() {
    _callbacks.clear();

    _stopMonitoring();
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    final args = call.arguments as String;

    if (call.method == 'cliptext') {
      _callbacks.forEach((cb) => cb(args));
    }
  }
}
