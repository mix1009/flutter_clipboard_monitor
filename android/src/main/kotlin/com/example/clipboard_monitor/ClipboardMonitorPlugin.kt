package com.example.clipboard_monitor

import android.content.ClipboardManager
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** ClipboardMonitorPlugin */
class ClipboardMonitorPlugin : FlutterPlugin, MethodCallHandler {


    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var mContext: Context
    private lateinit var clipboard: ClipboardManager
    private lateinit var clipBoardCallback: () -> Unit

    private val CHANNEL_NAME = "clipboard_monitor"

    private fun setupChannel(messenger: BinaryMessenger, context: Context) {
        channel = MethodChannel(messenger, CHANNEL_NAME)
        mContext = context
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        setupChannel(binding.binaryMessenger, binding.applicationContext);
        clipboard = mContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        // store reference to callback so it can be removed later
        clipBoardCallback = {
            val text = clipboard.primaryClip?.getItemAt(0)?.text
            if (!text.isNullOrBlank()) {
                channel.invokeMethod("cliptext", text.toString())
            }
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
      when (call.method) {
          "monitorClipboard" -> {
            clipboard.addPrimaryClipChangedListener(clipBoardCallback)
            result.success(true)
          }
          "stopMonitoringClipboard" -> {
            clipboard.removePrimaryClipChangedListener(clipBoardCallback)
            result.success(true)
          }
          else -> {
            result.notImplemented()
          }
      }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
