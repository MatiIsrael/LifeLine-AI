package com.lifeline.lifeline_ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Detects rapid screen-off events as a proxy for multi-press power button patterns.
 * Works best while Lifeline foreground/background protection service is active.
 */
class PowerButtonPlugin(private val context: Context) {
    private val methodChannelName = "lifeline/power_button"
    private val eventChannelName = "lifeline/power_button_events"

    private var receiver: BroadcastReceiver? = null
    private var eventSink: EventChannel.EventSink? = null
    private var requiredPresses = 3
    private var windowMs = 2500L
    private var pressCount = 0
    private var lastPressAt = 0L

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        requiredPresses = call.argument<Int>("requiredPresses") ?: 3
                        windowMs = (call.argument<Int>("windowMs") ?: 2500).toLong()
                        registerReceiver()
                        result.success(null)
                    }
                    "stopListening" -> {
                        unregisterReceiver()
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

    private fun registerReceiver() {
        unregisterReceiver()
        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                if (intent?.action != Intent.ACTION_SCREEN_OFF) return
                val now = System.currentTimeMillis()
                if (now - lastPressAt > windowMs) {
                    pressCount = 0
                }
                pressCount += 1
                lastPressAt = now
                eventSink?.success(pressCount)
                if (pressCount >= requiredPresses) {
                    pressCount = 0
                }
            }
        }

        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
    }

    private fun unregisterReceiver() {
        receiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        receiver = null
        pressCount = 0
    }

    fun dispose() {
        unregisterReceiver()
        eventSink = null
    }
}
