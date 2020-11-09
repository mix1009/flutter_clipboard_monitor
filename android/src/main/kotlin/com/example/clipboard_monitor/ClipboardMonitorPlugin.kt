package com.example.clipboard_monitor

import android.content.ClipboardManager
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger




/** ClipboardMonitorPlugin */
class ClipboardMonitorPlugin: FlutterPlugin, MethodCallHandler {


  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var mContext : Context

  private val CHANNEL_NAME = "clipboard_monitor"

  private fun setupChannel(messenger: BinaryMessenger, context: Context) {
    channel = MethodChannel(messenger, CHANNEL_NAME)
    mContext = context
    channel.setMethodCallHandler(this)
  }

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    setupChannel(binding.binaryMessenger, binding.applicationContext);
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")

    } else if (call.method == "monitorClipboard") {

      val clipboard = mContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

      clipboard.addPrimaryClipChangedListener {
        val clip = clipboard.primaryClip
        if (clip?.itemCount == 1) {
          val text = clip.getItemAt(0).text
          if (text.isNotEmpty()) {
            channel.invokeMethod("cliptext", text)
          }
        }
      }

      result.success(true)

    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
