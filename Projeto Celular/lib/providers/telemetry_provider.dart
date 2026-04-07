import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/telemetry_packet.dart';
import '../services/ble_service.dart';
import '../services/mqtt_service.dart';

/// Central provider that bridges BLE input to MQTT output and UI state.
///
/// Listens to BLE packets, updates UI state, and forwards to MQTT gateway.
class TelemetryNotifier extends StateNotifier<TelemetryState> {
  final BleService _bleService;
  final MqttService _mqttService;
  StreamSubscription<TelemetryPacket>? _packetSub;
  StreamSubscription<BleConnectionState>? _bleStateSub;
  StreamSubscription<MqttConnectionState>? _mqttStateSub;
  Timer? _timeoutTimer;

  TelemetryNotifier(this._bleService, this._mqttService)
      : super(TelemetryState.initial()) {
    _listenToStreams();
  }

  void _listenToStreams() {
    // Listen to BLE packets
    _packetSub = _bleService.packetStream.listen(_onPacketReceived);

    // Listen to BLE connection state
    _bleStateSub = _bleService.stateStream.listen((bleState) {
      state = state.copyWith(bleState: bleState);
    });

    // Listen to MQTT connection state
    _mqttStateSub = _mqttService.stateStream.listen((mqttState) {
      state = state.copyWith(mqttState: mqttState);
    });
  }

  void _onPacketReceived(TelemetryPacket packet) {
    // Detect session change (lap change)
    final sessionChanged = packet.sessionNumber != state.packet.sessionNumber &&
        state.packet.sessionNumber > 0;

    // Update state
    state = state.copyWith(
      packet: packet,
      lastUpdateTime: DateTime.now(),
      isReceiving: true,
      sessionJustChanged: sessionChanged,
    );

    // Forward to MQTT gateway
    _mqttService.publish(packet);

    // Reset session change flag after a short delay
    if (sessionChanged) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(sessionJustChanged: false);
        }
      });
    }

    // Reset timeout timer
    _resetTimeout();
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(milliseconds: 3000), () {
      state = state.copyWith(isReceiving: false);
    });
  }

  /// Start BLE scanning and connect.
  Future<void> startConnection() async {
    await _bleService.startScanAndConnect();
  }

  /// Set MQTT broker IP and connect.
  Future<void> connectMqtt(String brokerIp) async {
    await _mqttService.connect(brokerIp: brokerIp);
  }

  /// Disconnect everything.
  Future<void> disconnectAll() async {
    _timeoutTimer?.cancel();
    await _bleService.disconnect();
    await _mqttService.disconnect();
  }

  bool get mounted => true; // Simplified check

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _packetSub?.cancel();
    _bleStateSub?.cancel();
    _mqttStateSub?.cancel();
    super.dispose();
  }
}

/// Immutable state for the telemetry system.
class TelemetryState {
  final TelemetryPacket packet;
  final BleConnectionState bleState;
  final MqttConnectionState mqttState;
  final DateTime? lastUpdateTime;
  final bool isReceiving;
  final bool sessionJustChanged;

  const TelemetryState({
    required this.packet,
    required this.bleState,
    required this.mqttState,
    this.lastUpdateTime,
    this.isReceiving = false,
    this.sessionJustChanged = false,
  });

  factory TelemetryState.initial() {
    return TelemetryState(
      packet: TelemetryPacket.empty(),
      bleState: BleConnectionState.disconnected,
      mqttState: MqttConnectionState.disconnected,
    );
  }

  TelemetryState copyWith({
    TelemetryPacket? packet,
    BleConnectionState? bleState,
    MqttConnectionState? mqttState,
    DateTime? lastUpdateTime,
    bool? isReceiving,
    bool? sessionJustChanged,
  }) {
    return TelemetryState(
      packet: packet ?? this.packet,
      bleState: bleState ?? this.bleState,
      mqttState: mqttState ?? this.mqttState,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isReceiving: isReceiving ?? this.isReceiving,
      sessionJustChanged: sessionJustChanged ?? this.sessionJustChanged,
    );
  }
}

/// Main telemetry provider — the single source of truth for the entire app.
final telemetryProvider =
    StateNotifierProvider<TelemetryNotifier, TelemetryState>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  final mqttService = ref.watch(mqttServiceProvider);
  return TelemetryNotifier(bleService, mqttService);
});
