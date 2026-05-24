package com.hawkstreakstudio.flixsy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val plugin = ConnectSdkPlugin(this)

        MethodChannel(messenger, ConnectSdkPlugin.METHOD_CHANNEL)
            .setMethodCallHandler(plugin)

        EventChannel(messenger, ConnectSdkPlugin.EVENT_CHANNEL)
            .setStreamHandler(plugin)

        // Wi-Fi multicast lock for the pure-Dart discovery channels (mDNS / SSDP).
        MethodChannel(messenger, MulticastLockPlugin.METHOD_CHANNEL)
            .setMethodCallHandler(MulticastLockPlugin(this))
    }
}
