import 'dart:async';

import 'package:flutter/services.dart';

// typedef OnClipboardTextFunction = void Function(String text);

class ClipboardMonitor {
  static const MethodChannel _channel =
      const MethodChannel('clipboard_monitor');

  static bool _initialized = false;

  static final _callbacks = List<Function(String)>();

  static void _init() async {
    if (_initialized) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _initialized = true;

    await _channel.invokeMethod('monitorClipboard');
  }

  static void registerCallback(Function(String) func) {
    if (!_initialized) {
      _init();
    }
    _callbacks.add(func);
  }

  static void unregisterCallback(Function(String) func) {
    _callbacks.remove(func);
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    // print('_handleMethodCall: ' + call.method);
    // print(call.arguments);
    var args = call.arguments as String;

    if (call.method == 'cliptext') {
      _callbacks.forEach((cb) => cb(args));
    }
  }
}
