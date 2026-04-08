package com.neurogate.neurogate

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class NeuroGateAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "NeuroGateA11y"
        // Track last intercepted to prevent rapid re-triggering
        private var lastInterceptedPackage: String? = null
        private var lastInterceptedTime: Long = 0
        private const val INTERCEPT_COOLDOWN_MS = 3000L // 3 second cooldown
    }

    private lateinit var prefs: SharedPreferences
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "NeuroGate AccessibilityService connected")

        prefs = getSharedPreferences("neurogate_prefs", Context.MODE_PRIVATE)

        // Reload blocked apps from SharedPreferences
        val savedApps = prefs.getStringSet("blocked_apps", emptySet()) ?: emptySet()
        AppBlockerMethodChannel.blockedApps.set(savedApps)
        Log.d(TAG, "Loaded ${savedApps.size} blocked apps: $savedApps")

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Skip our own package and system UI
        if (packageName == applicationContext.packageName) return
        if (packageName == "com.android.systemui") return
        if (packageName == "com.android.launcher") return
        if (packageName.startsWith("com.android.launcher")) return
        if (packageName == "com.google.android.apps.nexuslauncher") return

        val blockedSet = AppBlockerMethodChannel.blockedApps.get()
        if (!blockedSet.contains(packageName)) return

        // Check for active session
        val expiry = AppBlockerMethodChannel.sessionExpiry[packageName]
        if (expiry != null && System.currentTimeMillis() < expiry) {
            Log.d(TAG, "Session active for $packageName, allowing access")
            return
        }

        // Prevent rapid re-triggering for the same package
        val now = System.currentTimeMillis()
        if (packageName == lastInterceptedPackage && 
            (now - lastInterceptedTime) < INTERCEPT_COOLDOWN_MS) {
            return
        }
        lastInterceptedPackage = packageName
        lastInterceptedTime = now

        Log.d(TAG, "BLOCKED APP DETECTED: $packageName — launching NeuroGate challenge")

        // 1. Bring NeuroGate to the foreground with the blocked package info
        val launchIntent = Intent(applicationContext, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("blocked_package", packageName)
        }
        applicationContext.startActivity(launchIntent)

        // 2. Fire event to Flutter (with slight delay to ensure app is foregrounded)
        mainHandler.postDelayed({
            Log.d(TAG, "Firing event to Flutter for $packageName, eventSink=${AppBlockerMethodChannel.eventSink != null}")
            AppBlockerMethodChannel.eventSink?.success(packageName)
        }, 500)
    }

    override fun onInterrupt() {
        Log.d(TAG, "NeuroGate AccessibilityService interrupted")
    }
}
