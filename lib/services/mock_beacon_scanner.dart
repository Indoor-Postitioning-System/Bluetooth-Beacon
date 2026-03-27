import 'dart:async';
import 'dart:math';
import '../models/beacon_model.dart';
import '../models/position_model.dart';
import 'beacon_scanner.dart';

class MockBeaconScanner implements BeaconScanner {
  final _controller = StreamController<List<BeaconData>>.broadcast();
  Timer? _timer;
  final Random _random = Random();
  // Die virtuelle Position des Benutzers (vom UI aus veränderbar)
  static Position simulatedUserPosition = Position(x: 5.0, y: 5.0);
  
  // Feste Koordinaten der virtuellen Beacons
  static final Position beacon1Pos = Position(x: 2.0, y: 2.0);
  static final Position beacon2Pos = Position(x: 8.0, y: 2.0);
  static final Position beacon3Pos = Position(x: 5.0, y: 8.0);

  int _calculateRssi(Position user, Position beacon) {
    double dx = user.x - beacon.x;
    double dy = user.y - beacon.y;
    double dist = sqrt(dx*dx + dy*dy);
    if (dist < 0.1) dist = 0.1;
    
    // Path Loss Modell (RSSI bei 1m = -50, n = 2.5)
    int rssi = (-50 - 10 * 2.5 * log(dist) / ln10).round();
    
    // Für eine ruhige Diplomarbeits-Präsentation deaktivieren wir das Rauschen
    // rssi += _random.nextInt(5) - 2;
    return rssi;
  }

  @override
  Stream<List<BeaconData>> get scanResults => _controller.stream;

  @override
  void startScan() {
    print('Starting Mock BLE Scanner (Interactive Interactive Mode)...');
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_controller.isClosed) return;
      
      // Simuliere exakt 3 Beacons wie vom User gewünscht
      final mockData = [
        BeaconData(
          uuid: 'SIM-BEACON-1',
          major: 1,
          minor: 1,
          rssi: _calculateRssi(simulatedUserPosition, beacon1Pos),
        ),
        BeaconData(
          uuid: 'SIM-BEACON-2',
          major: 1,
          minor: 2,
          rssi: _calculateRssi(simulatedUserPosition, beacon2Pos),
        ),
        BeaconData(
          uuid: 'SIM-BEACON-3',
          major: 1,
          minor: 3,
          rssi: _calculateRssi(simulatedUserPosition, beacon3Pos),
        ),
      ];

      _controller.add(mockData);
    });
  }

  @override
  void stopScan() {
    print('Stopping Mock BLE Scanner...');
    _timer?.cancel();
  }
}
