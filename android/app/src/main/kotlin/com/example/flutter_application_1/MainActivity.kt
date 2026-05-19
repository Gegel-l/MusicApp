package com.example.flutter_application_1

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "app.link_opener"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "openChooser") {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("bad-args", "url is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        val chooser = Intent.createChooser(intent, "Открыть через")
                        chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("open-failed", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
