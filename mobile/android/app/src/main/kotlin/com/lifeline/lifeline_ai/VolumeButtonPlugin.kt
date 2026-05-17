package com.lifeline.lifeline_ai

import android.os.SystemClock
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Detects rapid volume-up / volume-down presses (3x) while the app activity is active.
 */
class VolumeButtonPlugin {
    private val methodChannelName = "lifeline/volume_button"
    private val eventChannelName = "lifeline/volume_button_events"

    private var eventSink: EventChannel.EventSink? = null
    private var requiredPresses = 3
    private var windowMs = 2500L
    private var pressCount = 0
    private var lastPressAt = 0L
    private var listening = false

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        requiredPresses = call.argument<Int>("requiredPresses") ?: 3
                        windowMs = (call.argument<Int>("windowMs") ?: 2500).toLong()
                        listening = true
                        pressCount = 0
                        result.success(null)
                    }
                    "stopListening" -> {
                        listening = false
                        pressCount = 0
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    fun onVolumeKeyPressed(): Boolean {
        if (!listening) return false

        val now = SystemClock.elapsedRealtime()
        if (now - lastPressAt > windowMs) {
            pressCount = 0
        }
        pressCount += 1
        lastPressAt = now
        eventSink?.success(pressCount)

        if (pressCount >= requiredPresses) {
            pressCount = 0
            return true
        }
        return true
    }

    fun dispose() {
        listening = false
        eventSink = null
    }

    companion object {
        @Volatile
        var instance: VolumeButtonPlugin? = null
    }
}
