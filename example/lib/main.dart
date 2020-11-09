import 'package:flutter/material.dart';
import 'package:clipboard_monitor/clipboard_monitor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _clipboardText = '';
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = 'Copy some text from here.\n1234 5678';
    ClipboardMonitor.registerCallback(onClipboardText);
  }

  @override
  void dispose() {
    ClipboardMonitor.unregisterCallback(onClipboardText);
    super.dispose();
  }

  void onClipboardText(String text) {
    print("clipboard changed: $text");
    setState(() {
      _clipboardText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('clipboard_monitor example app'),
        ),
        body: Center(
          child: Column(
            children: [
              SizedBox(height: 10),
              Text('Clipboard text: $_clipboardText\n'),
              SizedBox(height: 30),
              TextField(maxLines: 5, controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
