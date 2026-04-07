/// Represents a single telemetry data packet received from the ESP32-S3.
///
/// This is the primary data structure exchanged between:
/// - ESP32-S3 → (BLE) → App (this model)
/// - App → (MQTT/JSON) → Dashboard
class TelemetryPacket {
  /// Timestamp from the ESP32 in milliseconds since boot.
  final int timestampMs;

  /// Current speed in km/h (calculated from encoder by the ESP).
  final double speedKmh;

  /// Instantaneous power consumption in Watts (V × I).
  final double powerW;

  /// Average power consumption over the last 1-second window (W).
  final double avgPowerW;

  /// Accumulated energy consumption in Wh for the current session.
  final double energyWh;

  /// Local X coordinate in meters (odometry — sensor fusion).
  final double posX;

  /// Local Y coordinate in meters (odometry — sensor fusion).
  final double posY;

  /// Heading angle (yaw) in radians from the gyroscope.
  final double headingRad;

  /// Total distance traveled in the current session (meters).
  final double distanceM;

  /// Current session/lap number.
  final int sessionNumber;

  /// Battery voltage (V).
  final double batteryV;

  /// Battery current (A).
  final double currentA;

  const TelemetryPacket({
    required this.timestampMs,
    required this.speedKmh,
    required this.powerW,
    required this.avgPowerW,
    required this.energyWh,
    required this.posX,
    required this.posY,
    required this.headingRad,
    required this.distanceM,
    required this.sessionNumber,
    required this.batteryV,
    required this.currentA,
  });

  /// Creates an empty packet with all values zeroed. Used as initial state.
  factory TelemetryPacket.empty() {
    return const TelemetryPacket(
      timestampMs: 0,
      speedKmh: 0.0,
      powerW: 0.0,
      avgPowerW: 0.0,
      energyWh: 0.0,
      posX: 0.0,
      posY: 0.0,
      headingRad: 0.0,
      distanceM: 0.0,
      sessionNumber: 1,
      batteryV: 0.0,
      currentA: 0.0,
    );
  }

  /// Parse from JSON map (received via BLE or used for MQTT serialization).
  factory TelemetryPacket.fromJson(Map<String, dynamic> json) {
    return TelemetryPacket(
      timestampMs: (json['ts'] as num?)?.toInt() ?? 0,
      speedKmh: (json['spd'] as num?)?.toDouble() ?? 0.0,
      powerW: (json['pwr'] as num?)?.toDouble() ?? 0.0,
      avgPowerW: (json['apwr'] as num?)?.toDouble() ?? 0.0,
      energyWh: (json['nrg'] as num?)?.toDouble() ?? 0.0,
      posX: (json['px'] as num?)?.toDouble() ?? 0.0,
      posY: (json['py'] as num?)?.toDouble() ?? 0.0,
      headingRad: (json['hd'] as num?)?.toDouble() ?? 0.0,
      distanceM: (json['dst'] as num?)?.toDouble() ?? 0.0,
      sessionNumber: (json['ses'] as num?)?.toInt() ?? 1,
      batteryV: (json['bv'] as num?)?.toDouble() ?? 0.0,
      currentA: (json['ba'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Serialize to compact JSON map for MQTT publishing.
  /// Keys are abbreviated to minimize payload size over 4G.
  Map<String, dynamic> toJson() {
    return {
      'ts': timestampMs,
      'spd': speedKmh,
      'pwr': powerW,
      'apwr': avgPowerW,
      'nrg': energyWh,
      'px': posX,
      'py': posY,
      'hd': headingRad,
      'dst': distanceM,
      'ses': sessionNumber,
      'bv': batteryV,
      'ba': currentA,
    };
  }

  /// Parse from raw BLE bytes (binary struct from ESP32).
  ///
  /// Expected byte layout (little-endian, 48 bytes total):
  /// [0-3]   uint32  timestampMs
  /// [4-7]   float32 speedKmh
  /// [8-11]  float32 powerW
  /// [12-15] float32 avgPowerW
  /// [16-19] float32 energyWh
  /// [20-23] float32 posX
  /// [24-27] float32 posY
  /// [28-31] float32 headingRad
  /// [32-35] float32 distanceM
  /// [36-39] uint32  sessionNumber
  /// [40-43] float32 batteryV
  /// [44-47] float32 currentA
  factory TelemetryPacket.fromBytes(List<int> bytes) {
    if (bytes.length < 48) {
      return TelemetryPacket.empty();
    }

    final data = ByteData.sublistView(Uint8List.fromList(bytes));

    return TelemetryPacket(
      timestampMs: data.getUint32(0, Endian.little),
      speedKmh: data.getFloat32(4, Endian.little),
      powerW: data.getFloat32(8, Endian.little),
      avgPowerW: data.getFloat32(12, Endian.little),
      energyWh: data.getFloat32(16, Endian.little),
      posX: data.getFloat32(20, Endian.little),
      posY: data.getFloat32(24, Endian.little),
      headingRad: data.getFloat32(28, Endian.little),
      distanceM: data.getFloat32(32, Endian.little),
      sessionNumber: data.getUint32(36, Endian.little),
      batteryV: data.getFloat32(40, Endian.little),
      currentA: data.getFloat32(44, Endian.little),
    );
  }
}
