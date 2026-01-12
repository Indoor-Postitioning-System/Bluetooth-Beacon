import 'position_model.dart';

class Fingerprint {
  final Position position; // Wo wurde gemessen?
  final Map<String, int> rssiValues; // Welche Signalstärken waren da?

  const Fingerprint({
    required this.position,
    required this.rssiValues,
  });
}
