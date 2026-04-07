import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/telemetry_packet.dart';

/// Connection state for the MQTT gateway.
enum MqttConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Service responsible for publishing telemetry data to the base dashboard
/// via MQTT over the mobile network (4G/5G).
///
/// Acts as a gateway: receives TelemetryPacket from BLE, serializes to
/// compact JSON, and publishes to the MQTT broker running on the base notebook.
class MqttService {
  MqttServerClient? _client;
  Timer? _reconnectTimer;

  final _stateController = StreamController<MqttConnectionState>.broadcast();

  /// Stream of MQTT connection state changes.
  Stream<MqttConnectionState> get stateStream => _stateController.stream;

  MqttConnectionState _currentState = MqttConnectionState.disconnected;
  MqttConnectionState get currentState => _currentState;

  /// The broker IP address (notebook's public or VPN IP).
  String _brokerIp = '';

  /// The broker port.
  int _brokerPort = AppConstants.mqttDefaultPort;

  void _setState(MqttConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Connect to the MQTT broker at the given IP.
  ///
  /// [brokerIp] — The IP address of the notebook running Mosquitto.
  /// [port] — Broker port (default: 1883).
  Future<void> connect({
    required String brokerIp,
    int port = AppConstants.mqttDefaultPort,
  }) async {
    _brokerIp = brokerIp;
    _brokerPort = port;

    if (_currentState == MqttConnectionState.connecting) return;
    _setState(MqttConnectionState.connecting);

    _client = MqttServerClient(_brokerIp, AppConstants.mqttClientId)
      ..port = _brokerPort
      ..keepAlivePeriod = AppConstants.mqttKeepAliveSeconds
      ..autoReconnect = true
      ..onAutoReconnect = _onAutoReconnect
      ..onAutoReconnected = _onAutoReconnected
      ..onDisconnected = _onDisconnected
      ..onConnected = _onConnected
      ..logging(on: false);

    // Connection message
    final connMsg = MqttConnectMessage()
        .withClientIdentifier(AppConstants.mqttClientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMsg;

    try {
      await _client!.connect();
    } catch (e) {
      _setState(MqttConnectionState.error);
      _client?.disconnect();
      _scheduleReconnect();
    }
  }

  /// Publish a telemetry packet to the MQTT topic.
  ///
  /// Returns `true` if published successfully, `false` if buffered or failed.
  bool publish(TelemetryPacket packet) {
    if (_client == null ||
        _client!.connectionStatus?.state != MqttConnectionState.connected) {
      return false;
    }

    try {
      final jsonStr = jsonEncode(packet.toJson());
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonStr);

      _client!.publishMessage(
        AppConstants.mqttTelemetryTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  void _onConnected() {
    _setState(MqttConnectionState.connected);
  }

  void _onDisconnected() {
    _setState(MqttConnectionState.disconnected);
  }

  void _onAutoReconnect() {
    _setState(MqttConnectionState.connecting);
  }

  void _onAutoReconnected() {
    _setState(MqttConnectionState.connected);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(seconds: 5),
      () => connect(brokerIp: _brokerIp, port: _brokerPort),
    );
  }

  /// Disconnect from the broker.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _client?.disconnect();
    _client = null;
    _setState(MqttConnectionState.disconnected);
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
  }
}

/// Riverpod provider for the MQTT service (singleton).
final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(() => service.dispose());
  return service;
});
