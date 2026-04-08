package com.neurogate.neurogate

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicReference

class AppBlockerMethodChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) {
    companion object {
        private const val CHANNEL = "com.neurogate.app/blocker"
        private const val EVENT_CHANNEL = "com.neurogate.app/blocker_events"
        private const val PREFS_NAME = "neurogate_prefs"
        private const val BLOCKED_APPS_KEY = "blocked_apps"

        // Shared state accessible by AccessibilityService
        val blockedApps = AtomicReference<Set<String>>(emptySet())
        val sessionExpiry = ConcurrentHashMap<String, Long>()
        var eventSink: EventChannel.EventSink? = null
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    init {
        // Load persisted block list
        val savedApps = prefs.getStringSet(BLOCKED_APPS_KEY, emptySet()) ?: emptySet()
        blockedApps.set(savedApps)

        // Setup MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncBlockedApps" -> {
                        val packageNames = call.argument<List<String>>("packageNames")
                        if (packageNames != null) {
                            val appSet = packageNames.toSet()
                            blockedApps.set(appSet)
                            prefs.edit()
                                .putStringSet(BLOCKED_APPS_KEY, appSet)
                                .apply()
                            result.success(null)
                        } else {
                            result.error("INVALID_ARG", "packageNames required", null)
                        }
                    }
                    "grantSession" -> {
                        val packageName = call.argument<String>("packageName")
                        val durationMinutes = call.argument<Int>("durationMinutes")
                        if (packageName != null && durationMinutes != null) {
                            val expiryTime = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)
                            sessionExpiry[packageName] = expiryTime
                            result.success(null)
                        } else {
                            result.error("INVALID_ARG", "packageName and durationMinutes required", null)
                        }
                    }
                    "checkAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        context.startActivity(intent)
                        result.success(null)
                    }
                    "goToLauncher" -> {
                        val intent = Intent(Intent.ACTION_MAIN)
                        intent.addCategory(Intent.CATEGORY_HOME)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        context.startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Setup EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedServiceSuffix = "com.neurogate.neurogate/com.neurogate.neurogate.NeuroGateAccessibilityService"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.split(":").any { service ->
            service.trim() == expectedServiceSuffix ||
            service.trim().endsWith(".NeuroGateAccessibilityService")
        }
    }
}
