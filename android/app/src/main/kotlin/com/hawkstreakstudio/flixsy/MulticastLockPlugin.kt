package com.hawkstreakstudio.flixsy

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Holds a Wi-Fi [WifiManager.MulticastLock] for the duration of LAN device
 * discovery.
 *
 * Android drops inbound multicast / broadcast packets to the app by default to
 * save power. The pure-Dart channels rely on those packets — mDNS replies for
 * Android TV and SSDP `M-SEARCH` responses — so discovery needs this lock held.
 *
 * The Dart [com.hawkstreakstudio.flixsy] channel layer drives `acquire` / `release` in
 * balanced pairs around discovery. The underlying lock is reference-counted so
 * nested acquire/release calls remain safe.
 */
class MulticastLockPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val METHOD_CHANNEL = "com.flixsy.app/multicast_lock"
        private const val TAG = "MulticastLockPlugin"
        private const val LOCK_TAG = "flixsy_discovery"
    }

    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "acquire" -> {
                acquire()
                result.success(null)
            }
            "release" -> {
                release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun acquire() {
        val lock = multicastLock ?: run {
            val wifiManager = context.applicationContext
                .getSystemService(Context.WIFI_SERVICE) as WifiManager
            wifiManager.createMulticastLock(LOCK_TAG)
                .apply { setReferenceCounted(true) }
                .also { multicastLock = it }
        }
        lock.acquire()
        Log.d(TAG, "multicast lock acquired; held=${lock.isHeld}")
    }

    private fun release() {
        val lock = multicastLock
        // Guard against an unbalanced release — release() on a count of 0
        // throws. The Dart side keeps calls balanced, but stay defensive.
        if (lock != null && lock.isHeld) {
            lock.release()
            Log.d(TAG, "multicast lock released; held=${lock.isHeld}")
        }
    }
}
