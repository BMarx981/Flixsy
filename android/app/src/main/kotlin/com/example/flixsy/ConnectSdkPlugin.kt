package com.example.flixsy

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import com.connectsdk.device.ConnectableDevice
import com.connectsdk.device.ConnectableDeviceListener
import com.connectsdk.discovery.DiscoveryManager
import com.connectsdk.discovery.DiscoveryManagerListener
import com.connectsdk.service.DeviceService
import com.connectsdk.service.command.ServiceCommandError
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class ConnectSdkPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    DiscoveryManagerListener {

    companion object {
        const val METHOD_CHANNEL = "com.flixsy.app/connect_sdk"
        const val EVENT_CHANNEL = "com.flixsy.app/connect_sdk_events"
        private const val TAG = "ConnectSdkPlugin"
    }

    private var eventSink: EventChannel.EventSink? = null
    private val discoveredDevices = mutableMapOf<String, ConnectableDevice>()
    private var connectedDevice: ConnectableDevice? = null
    private var multicastLock: WifiManager.MulticastLock? = null

    // MARK: - MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startDiscovery" -> startDiscovery(result)
            "stopDiscovery" -> stopDiscovery(result)
            "connectToDevice" -> {
                val deviceId = call.argument<String>("deviceId")
                    ?: return result.error("INVALID_ARGS", "deviceId required", null)
                connectToDevice(deviceId, result)
            }
            "disconnect" -> disconnect(result)
            "sendKeyCommand" -> {
                val key = call.argument<String>("key")
                    ?: return result.error("INVALID_ARGS", "key required", null)
                sendKeyCommand(key, result)
            }
            "getDiscoveredDevices" -> getDiscoveredDevices(result)
            else -> result.notImplemented()
        }
    }

    // MARK: - Discovery

    private fun startDiscovery(result: Result) {
        Log.d(TAG, "startDiscovery invoked")
        acquireMulticastLock()
        DiscoveryManager.init(context.applicationContext)
        val manager = DiscoveryManager.getInstance()
        manager.pairingLevel = DiscoveryManager.PairingLevel.ON
        manager.addListener(this)
        manager.start()
        Log.d(TAG, "DiscoveryManager.start() called; listener added, multicast lock held=${multicastLock?.isHeld}")
        result.success(null)
    }

    private fun stopDiscovery(result: Result) {
        DiscoveryManager.getInstance()?.apply {
            removeListener(this@ConnectSdkPlugin)
            stop()
        }
        releaseMulticastLock()
        result.success(null)
    }

    // MARK: - Connection

    private fun connectToDevice(deviceId: String, result: Result) {
        val device = discoveredDevices[deviceId]
            ?: return result.error("CONNECTION_ERROR", "Device not found: $deviceId", null)
        device.addListener(makeDeviceListener())
        device.connect()
        connectedDevice = device
        // Connection completes asynchronously; ack the call here.
        result.success(null)
    }

    private fun disconnect(result: Result) {
        connectedDevice?.disconnect()
        connectedDevice = null
        result.success(null)
    }

    // MARK: - Commands

    private fun sendKeyCommand(key: String, result: Result) {
        val device = connectedDevice
            ?: return result.error("COMMAND_ERROR", "No device connected", null)

        val success = com.connectsdk.service.capability.listeners.ResponseListener<Any> { result.success(null) }
        val failure = com.connectsdk.service.capability.listeners.ResponseListener<ServiceCommandError> {
            result.error("COMMAND_ERROR", it?.message ?: "Key command failed", null)
        }

        // Reuse to avoid repetition in the when block
        fun keyControl() = device.getCapability(com.connectsdk.service.capability.KeyControl::class.java)
        fun volumeControl() = device.getCapability(com.connectsdk.service.capability.VolumeControl::class.java)
        fun tvControl() = device.getCapability(com.connectsdk.service.capability.TVControl::class.java)
        fun mediaControl() = device.getCapability(com.connectsdk.service.capability.MediaControl::class.java)

        when (key) {
            "up" -> keyControl()?.up(success)
            "down" -> keyControl()?.down(success)
            "left" -> keyControl()?.left(success)
            "right" -> keyControl()?.right(success)
            "ok", "select" -> keyControl()?.ok(success)
            "back" -> keyControl()?.back(success)
            "home" -> keyControl()?.home(success)
            "menu" -> tvControl()?.showMenu(success)
            "volumeUp" -> volumeControl()?.volumeUp(success)
            "volumeDown" -> volumeControl()?.volumeDown(success)
            "mute" -> volumeControl()?.setMute(true, success)
            "channelUp" -> tvControl()?.channelUp(success)
            "channelDown" -> tvControl()?.channelDown(success)
            "play" -> mediaControl()?.play(success)
            "pause" -> mediaControl()?.pause(success)
            "stop" -> mediaControl()?.stop(success)
            "rewind" -> mediaControl()?.rewind(success)
            "fastForward" -> mediaControl()?.fastForward(success)
            else -> result.error("COMMAND_ERROR", "Unknown key: $key", null)
        }
    }

    private fun getDiscoveredDevices(result: Result) {
        val devices = discoveredDevices.values.map { deviceToMap(it) }
        result.success(devices)
    }

    // MARK: - DiscoveryManagerListener

    override fun onDeviceAdded(manager: DiscoveryManager, device: ConnectableDevice) {
        Log.d(TAG, "onDeviceAdded: id=${device.id} name=${device.friendlyName} ip=${device.ipAddress} services=${device.services?.size}")
        discoveredDevices[device.id] = device
        sendEvent(mapOf("type" to "deviceFound", "device" to deviceToMap(device)))
    }

    override fun onDeviceUpdated(manager: DiscoveryManager, device: ConnectableDevice) {
        Log.d(TAG, "onDeviceUpdated: id=${device.id} name=${device.friendlyName}")
        discoveredDevices[device.id] = device
        sendEvent(mapOf("type" to "deviceUpdated", "device" to deviceToMap(device)))
    }

    override fun onDeviceRemoved(manager: DiscoveryManager, device: ConnectableDevice) {
        Log.d(TAG, "onDeviceRemoved: id=${device.id}")
        discoveredDevices.remove(device.id)
        sendEvent(mapOf("type" to "deviceLost", "deviceId" to (device.id ?: "")))
    }

    override fun onDiscoveryFailed(manager: DiscoveryManager, error: ServiceCommandError) {
        Log.e(TAG, "onDiscoveryFailed: ${error.message}")
        sendEvent(mapOf("type" to "discoveryError", "message" to (error.message ?: "Unknown error")))
    }

    // MARK: - StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        Log.d(TAG, "EventChannel onListen — Dart attached")
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "EventChannel onCancel — Dart detached")
        eventSink = null
    }

    // MARK: - Device listener factory

    private fun makeDeviceListener() = object : ConnectableDeviceListener {
        override fun onDeviceReady(device: ConnectableDevice) {
            sendEvent(mapOf("type" to "deviceConnected", "device" to deviceToMap(device)))
        }

        override fun onDeviceDisconnected(device: ConnectableDevice) {
            sendEvent(mapOf(
                "type" to "deviceDisconnected",
                "deviceId" to (device.id ?: ""),
                "message" to "",
            ))
            if (connectedDevice?.id == device.id) connectedDevice = null
        }

        override fun onPairingRequired(
            device: ConnectableDevice,
            service: DeviceService,
            pairingType: DeviceService.PairingType,
        ) {
            sendEvent(mapOf("type" to "pairingRequired", "deviceId" to (device.id ?: "")))
        }

        override fun onCapabilityUpdated(
            device: ConnectableDevice,
            added: MutableList<String>,
            removed: MutableList<String>,
        ) {
            // No action needed.
        }

        override fun onConnectionFailed(device: ConnectableDevice, error: ServiceCommandError) {
            sendEvent(mapOf(
                "type" to "connectionFailed",
                "deviceId" to (device.id ?: ""),
                "message" to (error.message ?: ""),
            ))
        }
    }

    // MARK: - Helpers

    private fun deviceToMap(device: ConnectableDevice): Map<String, Any> = mapOf(
        "id" to (device.id ?: ""),
        "name" to (device.friendlyName ?: "Unknown"),
        "ipAddress" to (device.ipAddress ?: ""),
        "connected" to device.isConnected,
    )

    private fun sendEvent(payload: Map<String, Any>) {
        if (eventSink == null) {
            Log.w(TAG, "sendEvent with no eventSink — Dart isn't listening yet. payload=$payload")
        }
        eventSink?.success(payload)
    }

    // MARK: - Multicast lock (required for device discovery on Android)

    private fun acquireMulticastLock() {
        if (multicastLock == null) {
            val wifiManager = context.applicationContext
                .getSystemService(Context.WIFI_SERVICE) as WifiManager
            multicastLock = wifiManager.createMulticastLock("flixsy_connectsdk").apply {
                setReferenceCounted(true)
                acquire()
            }
        }
    }

    private fun releaseMulticastLock() {
        multicastLock?.let {
            if (it.isHeld) it.release()
        }
        multicastLock = null
    }
}
