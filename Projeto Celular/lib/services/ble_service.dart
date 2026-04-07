import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/telemetry_packet.dart';

/// Connection state for the BLE service.
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// Service responsible for managing BLE connection to the ESP32-S3.
///
/// Handles scanning, connecting, subscribing to telemetry notifications,
/// and automatic reconnection on connection loss.
class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _telemetryCharacteristic;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  final _stateController = StreamController<BleConnectionState>.broadcast();
  final _packetController = StreamController<TelemetryPacket>.broadcast();

  /// Stream of connection state changes.
  Stream<BleConnectionState> get stateStream => _stateController.stream;

  /// Stream of parsed telemetry packets from the ESP.
  Stream<TelemetryPacket> get packetStream => _packetController.stream;

  /// Current connection state.
  BleConnectionState _currentState = BleConnectionState.disconnected;
  BleConnectionState get currentState => _currentState;

  void _setState(BleConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Start scanning for the ESP32-S3 and connect automatically.
  Future<void> startScanAndConnect() async {
    if (_currentState == BleConnectionState.scanning ||
        _currentState == BleConnectionState.connecting) {
      return;
    }

    _setState(BleConnectionState.scanning);
    _reconnectAttempts = 0;

    try {
      // Stop any ongoing scan
      await FlutterBluePlus.stopScan();

      // Start scanning with service filter
      await FlutterBluePlus.startScan(
        withServices: [Guid(AppConstants.bleServiceUuid)],
        timeout: Duration(seconds: AppConstants.bleScanTimeoutSeconds),
      );

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) async {
        if (results.isNotEmpty) {
          await FlutterBluePlus.stopScan();
          await _connectToDevice(results.first.device);
        }
      });
    } catch (e) {
      _setState(BleConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// Connect to a discovered BLE device.
  Future<void> _connectToDevice(BluetoothDevice device) async {
    _setState(BleConnectionState.connecting);
    _device = device;

    try {
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 10),
      );

      // Monitor connection state for dropouts
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _setState(BleConnectionState.disconnected);
          _cleanup();
          _scheduleReconnect();
        }
      });

      // Discover services and subscribe to telemetry
      await _discoverAndSubscribe(device);

      _reconnectAttempts = 0;
      _setState(BleConnectionState.connected);
    } catch (e) {
      _setState(BleConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// Discover BLE services and subscribe to telemetry characteristic.
  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.toString() == AppConstants.bleServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString() ==
              AppConstants.bleCharacteristicUuid) {
            _telemetryCharacteristic = characteristic;

            // Enable notifications
            await characteristic.setNotifyValue(true);

            // Listen to incoming data
            _notifySubscription =
                characteristic.lastValueStream.listen(_onDataReceived);
            return;
          }
        }
      }
    }

    throw Exception('Telemetry characteristic not found on ESP32-S3');
  }

  /// Parse incoming BLE data and emit as TelemetryPacket.
  void _onDataReceived(List<int> bytes) {
    if (bytes.isEmpty) return;

    final packet = TelemetryPacket.fromBytes(bytes);
    _packetController.add(packet);
  }

  /// Schedule automatic reconnection with exponential backoff.
  void _scheduleReconnect() {
    if (_reconnectAttempts >= AppConstants.bleMaxReconnectAttempts) {
      _setState(BleConnectionState.error);
      return;
    }

    _reconnectAttempts++;
    final delay = AppConstants.bleReconnectDelayMs * _reconnectAttempts;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      startScanAndConnect();
    });
  }

  /// Manually disconnect from the device.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _cleanup();
    await _device?.disconnect();
    _device = null;
    _setState(BleConnectionState.disconnected);
  }

  /// Clean up subscriptions.
  Future<void> _cleanup() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _telemetryCharacteristic = null;
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
  }
}

/// Riverpod provider for the BLE service (singleton).
final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
});
