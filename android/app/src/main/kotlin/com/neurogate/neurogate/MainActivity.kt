package com.neurogate.neurogate

import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "NeuroGateMain"
    }

    private lateinit var appBlockerMethodChannel: AppBlockerMethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appBlockerMethodChannel = AppBlockerMethodChannel(this, flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // When the accessibility service launches us with a blocked_package extra,
        // forward it to Flutter via the event channel
        val blockedPackage = intent.getStringExtra("blocked_package")
        if (blockedPackage != null) {
            Log.d(TAG, "onNewIntent received blocked_package: $blockedPackage")
            AppBlockerMethodChannel.eventSink?.success(blockedPackage)
        }
    }
}
