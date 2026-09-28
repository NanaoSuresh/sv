package com.vplayer.vplayer

import android.graphics.Bitmap
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class RifePlugin : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "RifePlugin"
        private const val CHANNEL = "com.vplayer.rife"

        private var nativeAvailable = false

        init {
            try {
                System.loadLibrary("rife_plugin")
                nativeAvailable = true
                Log.i(TAG, "rife_plugin native library loaded")
            } catch (e: UnsatisfiedLinkError) {
                nativeAvailable = false
                Log.w(TAG, "rife_plugin native library not available: ${e.message}")
            }
        }

        fun registerWith(flutterEngine: FlutterEngine) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(RifePlugin())
        }
    }

    private var nativeHandle: Long = 0

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> {
                result.success(nativeAvailable)
            }
            "init" -> {
                if (!nativeAvailable) {
                    result.error("UNAVAILABLE", "RIFE native library not loaded", null)
                    return
                }
                val modelPath = call.argument<String>("modelPath") ?: ""
                val gpuId = call.argument<Int>("gpuId") ?: 0
                val useVulkan = call.argument<Boolean>("useVulkan") ?: true

                nativeHandle = nativeInit(modelPath, gpuId, useVulkan)
                if (nativeHandle == 0L) {
                    result.error("INIT_FAILED", "Failed to initialize RIFE model", null)
                } else {
                    result.success(true)
                }
            }
            "destroy" -> {
                if (nativeHandle != 0L) {
                    nativeDestroy(nativeHandle)
                    nativeHandle = 0
                }
                result.success(true)
            }
            "getGpuCount" -> {
                // This would need ncnn::get_gpu_count() exposed via JNI
                result.success(if (nativeAvailable) 1 else 0)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // Native JNI methods
    private external fun nativeInit(modelPath: String, gpuId: Int, useVulkan: Boolean): Long
    private external fun nativeProcess(
        handle: Long,
        inputBitmap0: Bitmap, inputBitmap1: Bitmap,
        timestep: Float,
        outputBitmap: Bitmap
    ): Boolean
    private external fun nativeDestroy(handle: Long)
}
