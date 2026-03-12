package com.tickety.tickety

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val channelName = "com.tickety/pkpass"
    private var pendingFilePath: String? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPendingFile" -> {
                        result.success(pendingFilePath)
                        pendingFilePath = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent, warm = true)
    }

    override fun onStart() {
        super.onStart()
        handleIntent(intent, warm = false)
    }

    private fun handleIntent(intent: Intent?, warm: Boolean) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        try {
            val tempFile = File(cacheDir, "incoming_${UUID.randomUUID()}.pkpass")
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(tempFile).use { output -> input.copyTo(output) }
            }
            val path = tempFile.absolutePath
            if (warm) {
                channel?.invokeMethod("openFile", path)
            } else {
                pendingFilePath = path
            }
        } catch (_: Exception) {}
    }
}
