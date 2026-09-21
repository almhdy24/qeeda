package com.elmahdi.qeeda

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channel = "com.elmahdi.qeeda/share"
    private var pendingShareData: Map<String, Any?>? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedData" -> {
                    result.success(pendingShareData)
                    pendingShareData = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
        pendingShareData?.let { data ->
            methodChannel?.invokeMethod("onNewShare", data)
        }
    }

    private fun handleIntent(intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SEND -> {
                when {
                    intent.type == "text/plain" -> {
                        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                        if (!text.isNullOrBlank()) {
                            pendingShareData = mapOf("type" to "text", "text" to text)
                        }
                    }
                    intent.type?.startsWith("image/") == true -> {
                        @Suppress("DEPRECATION")
                        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                        if (uri != null) {
                            val filePath = copyUriToCache(uri)
                            if (filePath != null) {
                                pendingShareData = mapOf("type" to "image", "path" to filePath)
                            }
                        }
                    }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                @Suppress("DEPRECATION")
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                if (!uris.isNullOrEmpty()) {
                    val filePath = copyUriToCache(uris[0])
                    if (filePath != null) {
                        pendingShareData = mapOf("type" to "image", "path" to filePath)
                    }
                }
            }
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val ext = contentResolver.getType(uri)?.let { mime ->
                when {
                    mime.contains("png") -> ".png"
                    mime.contains("webp") -> ".webp"
                    else -> ".jpg"
                }
            } ?: ".jpg"
            val tempFile = File(cacheDir, "qeeda_import_${System.currentTimeMillis()}$ext")
            tempFile.outputStream().use { output -> inputStream.use { it.copyTo(output) } }
            tempFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
