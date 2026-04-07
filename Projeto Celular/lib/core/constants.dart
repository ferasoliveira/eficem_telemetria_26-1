/// Application-wide constants for the EFICEM Pilot app.
class AppConstants {
  AppConstants._();

  // --- BLE ---
  /// The BLE service UUID exposed by the ESP32-S3.
  /// Must match the UUID defined in the ESP firmware.
  static const String bleServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

  /// The BLE characteristic UUID for the telemetry data packet.
  static const String bleCharacteristicUuid =
      'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  /// Maximum time to wait for a BLE scan result before retrying (seconds).
  static const int bleScanTimeoutSeconds = 10;

  /// Delay between reconnection attempts (milliseconds).
  static const int bleReconnectDelayMs = 2000;

  /// Maximum number of consecutive reconnection attempts.
  static const int bleMaxReconnectAttempts = 10;

  // --- MQTT ---
  /// Default MQTT broker port.
  static const int mqttDefaultPort = 1883;

  /// MQTT topic for publishing telemetry data.
  static const String mqttTelemetryTopic = 'eficem/telemetry';

  /// MQTT client identifier.
  static const String mqttClientId = 'eficem_pilot_app';

  /// MQTT keep-alive interval (seconds).
  static const int mqttKeepAliveSeconds = 30;

  /// MQTT QoS level: 1 = at least once delivery.
  static const int mqttQos = 1;

  // --- Sampling ---
  /// Expected telemetry packet rate from ESP (Hz).
  static const int expectedPacketRateHz = 10;

  /// Timeout to consider ESP disconnected if no packet received (ms).
  static const int telemetryTimeoutMs = 3000;

  // --- UI ---
  /// Speed unit label.
  static const String speedUnit = 'km/h';

  /// Power consumption unit label.
  static const String powerUnit = 'W';

  /// Energy consumption unit label.
  static const String energyUnit = 'Wh';
}
