class BeaconData {
  final String uuid;
  final int major;
  final int minor;
  final int rssi; // Signalstärke

  const BeaconData({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.rssi,
  });

  // Eine ID um den Beacon eindeutig zu erkennen
  String get id => '$uuid-$major-$minor';
}
