package com.lifeline.lifeline_ai

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var powerButtonPlugin: PowerButtonPlugin? = null
    private var volumeButtonPlugin: VolumeButtonPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        powerButtonPlugin = PowerButtonPlugin(this).also { it.register(flutterEngine) }
        volumeButtonPlugin = VolumeButtonPlugin().also {
            VolumeButtonPlugin.instance = it
            it.register(flutterEngine)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val consumed = VolumeButtonPlugin.instance?.onVolumeKeyPressed() == true
            if (consumed) return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        powerButtonPlugin?.dispose()
        volumeButtonPlugin?.dispose()
        VolumeButtonPlugin.instance = null
        super.onDestroy()
    }
}
