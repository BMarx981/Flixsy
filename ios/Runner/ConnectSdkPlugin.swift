import Flutter
import UIKit
import ConnectSDK

class ConnectSdkPlugin: NSObject {

    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?

    private var discoveredDevices: [String: ConnectableDevice] = [:]
    private var connectedDevice: ConnectableDevice?

    init(binaryMessenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "com.flixsy.app/connect_sdk",
            binaryMessenger: binaryMessenger
        )
        eventChannel = FlutterEventChannel(
            name: "com.flixsy.app/connect_sdk_events",
            binaryMessenger: binaryMessenger
        )
        super.init()
        methodChannel.setMethodCallHandler(handle)
        eventChannel.setStreamHandler(self)
    }

    // MARK: - Method call handler

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startDiscovery":
            startDiscovery(result: result)
        case "stopDiscovery":
            stopDiscovery(result: result)
        case "connectToDevice":
            guard let args = call.arguments as? [String: Any],
                  let deviceId = args["deviceId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "deviceId required", details: nil))
                return
            }
            connectToDevice(deviceId: deviceId, result: result)
        case "disconnect":
            disconnect(result: result)
        case "sendKeyCommand":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "key required", details: nil))
                return
            }
            sendKeyCommand(key: key, result: result)
        case "getDiscoveredDevices":
            getDiscoveredDevices(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Discovery

    private func startDiscovery(result: @escaping FlutterResult) {
        NSLog("[ConnectSdkPlugin] startDiscovery invoked")
        guard let manager = DiscoveryManager.shared() else {
            NSLog("[ConnectSdkPlugin] DiscoveryManager.shared() returned nil")
            result(FlutterError(code: "DISCOVERY_ERROR", message: "DiscoveryManager unavailable", details: nil))
            return
        }
        manager.delegate = self
        manager.pairingLevel = DeviceServicePairingLevelOn
        manager.startDiscovery()
        NSLog("[ConnectSdkPlugin] DiscoveryManager.startDiscovery() called; delegate=self pairingLevel=ON")

        result(nil)
    }

    private func stopDiscovery(result: @escaping FlutterResult) {
        DiscoveryManager.shared()?.stopDiscovery()
        result(nil)
    }

    // MARK: - Connection

    private func connectToDevice(deviceId: String, result: @escaping FlutterResult) {
        guard let device = discoveredDevices[deviceId] else {
            result(FlutterError(code: "CONNECTION_ERROR", message: "Device not found: \(deviceId)", details: nil))
            return
        }
        device.delegate = self
        device.connect()
        connectedDevice = device
        // Connection result comes asynchronously via ConnectableDeviceDelegate; ack here.
        result(nil)
    }

    private func disconnect(result: @escaping FlutterResult) {
        connectedDevice?.disconnect()
        connectedDevice = nil
        result(nil)
    }

    // MARK: - Commands

    private func sendKeyCommand(key: String, result: @escaping FlutterResult) {
        guard let device = connectedDevice else {
            result(FlutterError(code: "COMMAND_ERROR", message: "No device connected", details: nil))
            return
        }

        let success: SuccessBlock = { _ in DispatchQueue.main.async { result(nil) } }
        let failure: FailureBlock = { error in
            DispatchQueue.main.async {
                result(FlutterError(
                    code: "COMMAND_ERROR",
                    message: error?.localizedDescription ?? "Key command failed",
                    details: nil
                ))
            }
        }

        switch key {
        case "up":
            device.keyControl()?.up(success: success, failure: failure)
        case "down":
            device.keyControl()?.down(success: success, failure: failure)
        case "left":
            device.keyControl()?.left(success: success, failure: failure)
        case "right":
            device.keyControl()?.right(success: success, failure: failure)
        case "ok", "select":
            device.keyControl()?.ok(success: success, failure: failure)
        case "back":
            device.keyControl()?.back(success: success, failure: failure)
        case "home":
            device.keyControl()?.home(success: success, failure: failure)
        case "menu":
            result(FlutterError(code: "COMMAND_ERROR", message: "menu key not supported by ConnectSDK KeyControl", details: nil))
        case "volumeUp":
            device.volumeControl()?.volumeUp(success: success, failure: failure)
        case "volumeDown":
            device.volumeControl()?.volumeDown(success: success, failure: failure)
        case "mute":
            device.volumeControl()?.setMute(true, success: success, failure: failure)
        case "channelUp":
            device.tvControl()?.channelUp(success: success, failure: failure)
        case "channelDown":
            device.tvControl()?.channelDown(success: success, failure: failure)
        case "play":
            device.mediaControl()?.play(success: success, failure: failure)
        case "pause":
            device.mediaControl()?.pause(success: success, failure: failure)
        case "stop":
            device.mediaControl()?.stop(success: success, failure: failure)
        case "rewind":
            device.mediaControl()?.rewind(success: success, failure: failure)
        case "fastForward":
            device.mediaControl()?.fastForward(success: success, failure: failure)
        default:
            result(FlutterError(code: "COMMAND_ERROR", message: "Unknown key: \(key)", details: nil))
        }
    }

    private func getDiscoveredDevices(result: @escaping FlutterResult) {
        let devices = discoveredDevices.values.map { deviceToMap($0) }
        result(Array(devices))
    }

    // MARK: - Helpers

    private func deviceToMap(_ device: ConnectableDevice) -> [String: Any] {
        return [
            "id": device.id ?? "",
            "name": device.friendlyName ?? "Unknown",
            "ipAddress": device.address ?? "",
            "connected": device.connected,
        ]
    }

    private func sendEvent(_ payload: [String: Any]) {
        DispatchQueue.main.async {
            if self.eventSink == nil {
                NSLog("[ConnectSdkPlugin] WARNING: sendEvent with no eventSink — Dart isn't listening yet. payload=\(payload)")
            }
            self.eventSink?(payload)
        }
    }
}

// MARK: - FlutterStreamHandler

extension ConnectSdkPlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NSLog("[ConnectSdkPlugin] EventChannel onListen — Dart attached")
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NSLog("[ConnectSdkPlugin] EventChannel onCancel — Dart detached")
        eventSink = nil
        return nil
    }
}

// MARK: - DiscoveryManagerDelegate

extension ConnectSdkPlugin: DiscoveryManagerDelegate {
    func discoveryManager(_ manager: DiscoveryManager!, didFind device: ConnectableDevice!) {
        guard let device = device, let id = device.id else {
            NSLog("[ConnectSdkPlugin] didFind called with nil device/id")
            return
        }
        NSLog("[ConnectSdkPlugin] didFind: id=\(id) name=\(device.friendlyName ?? "?") addr=\(device.address ?? "?") services=\(device.services?.count ?? 0)")
        discoveredDevices[id] = device
        sendEvent(["type": "deviceFound", "device": deviceToMap(device)])
    }

    func discoveryManager(_ manager: DiscoveryManager!, didLose device: ConnectableDevice!) {
        guard let device = device, let id = device.id else { return }
        NSLog("[ConnectSdkPlugin] didLose: id=\(id) name=\(device.friendlyName ?? "?")")
        discoveredDevices.removeValue(forKey: id)
        sendEvent(["type": "deviceLost", "deviceId": id])
    }

    func discoveryManager(_ manager: DiscoveryManager!, didFailWithError error: Error!) {
        NSLog("[ConnectSdkPlugin] didFailWithError: \(error?.localizedDescription ?? "nil")")
        sendEvent(["type": "discoveryError", "message": error?.localizedDescription ?? "Unknown error"])
    }
}

// MARK: - ConnectableDeviceDelegate

extension ConnectSdkPlugin: ConnectableDeviceDelegate {
    func connectableDeviceReady(_ device: ConnectableDevice!) {
        guard let device = device else { return }
        sendEvent(["type": "deviceConnected", "device": deviceToMap(device)])
    }

    func connectableDeviceDisconnected(_ device: ConnectableDevice!, withError error: Error!) {
        guard let device = device else { return }
        sendEvent([
            "type": "deviceDisconnected",
            "deviceId": device.id ?? "",
            "message": error?.localizedDescription ?? "",
        ])
        if connectedDevice?.id == device.id {
            connectedDevice = nil
        }
    }

    func connectableDevice(
        _ device: ConnectableDevice!,
        service: DeviceService!,
        pairingRequiredOfType pairingType: Int32,
        withData pairingData: Any!
    ) {
        sendEvent(["type": "pairingRequired", "deviceId": device?.id ?? ""])
    }

    func connectableDevice(
        _ device: ConnectableDevice!,
        service: DeviceService!,
        pairingSucceededWithCode pairingCode: String!
    ) {
        sendEvent(["type": "pairingSucceeded", "deviceId": device?.id ?? ""])
    }

    func connectableDevice(
        _ device: ConnectableDevice!,
        service: DeviceService!,
        pairingFailedWithError error: Error!
    ) {
        sendEvent([
            "type": "pairingFailed",
            "deviceId": device?.id ?? "",
            "message": error?.localizedDescription ?? "",
        ])
    }

    func connectableDeviceConnectionSuccess(_ device: ConnectableDevice!, for service: DeviceService!) {
        // Individual service connected — no action needed; deviceReady fires when all services are ready.
    }

    func connectableDevice(_ device: ConnectableDevice!, connectionFailedWithError error: Error!) {
        sendEvent([
            "type": "connectionFailed",
            "deviceId": device?.id ?? "",
            "message": error?.localizedDescription ?? "",
        ])
    }
}
