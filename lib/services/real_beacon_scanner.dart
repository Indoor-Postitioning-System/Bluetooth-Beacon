import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/beacon_model.dart';
import '../models/position_model.dart';
import 'beacon_scanner.dart';
import 'mock_beacon_scanner.dart';

class RealBeaconScanner implements BeaconScanner {
  final _controller = StreamController<List<BeaconData>>.broadcast();
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  final Map<String, BeaconData> _activeBeacons = {};
  Timer? _emitTimer;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;

  @override
  Stream<List<BeaconData>> get scanResults => _controller.stream;

  @override
  void startScan() async {
    print('Starting Real BLE Scanner...');
    
    _activeBeacons.clear();

    // Punkt 3: Auf Bluetooth Status hören (Nur Handy)
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        print("BLE Adapter is ON - starting scan");
        _performActualScan();
      } else {
        print("BLE Adapter is OFF - stopping scan");
        FlutterBluePlus.stopScan();
      }
    });

    _performActualScan();
  }

  void _performActualScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {

        String id = r.device.remoteId.str;
        
        _activeBeacons[id] = BeaconData(
          uuid: id,
          major: 0,
          minor: 0, 
          rssi: r.rssi,
        );
      }
    });

    // Timer VOR dem Scan-Start initiieren, damit die simulierten Beacons immer sofort da sind
    _emitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.isClosed) return;
      
      var list = _activeBeacons.values.toList();
      
      // HACK: Simulierter zweiter und dritter Beacon, da einer kaputt ist (Diplomarbeit-Rettung)
      // Wir nutzen das Log-Distance Path Loss Model für die Simulation
      list.add(BeaconData(
        uuid: 'SIM-BEACON-2-1-2',
        major: 1,
        minor: 2,
        rssi: _calculatePathLossRSSI(MockBeaconScanner.simulatedUserPosition, Position(x: 8.0, y: 2.0)),
      ));
      list.add(BeaconData(
        uuid: 'SIM-BEACON-3-1-3',
        major: 1,
        minor: 3,
        rssi: _calculatePathLossRSSI(MockBeaconScanner.simulatedUserPosition, Position(x: 5.0, y: 8.0)),
      ));

      _controller.add(list);
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: null,
        continuousUpdates: true,
      );
    } catch (e) {
      print("Real BLE Scan Error: \$e");
    }
  }

  // Log-Distance Path Loss Model (Wissenschaftliche Grundlage für die Diplomarbeit)
  int _calculatePathLossRSSI(Position user, Position beacon) {
    double dx = user.x - beacon.x;
    double dy = user.y - beacon.y;
    double dist = sqrt(dx*dx + dy*dy);
    if (dist < 0.1) dist = 0.1;
    
    // Formel: RSSI = A - 10 * n * log10(d)
    // A = RSSI bei 1m (-50 dBm), n = Pfadverlustexponent (2.5 für Innenräume)
    double rssi = -50 - 10 * 2.5 * log(dist) / ln10;
    
    // ±3 dBm Rauschen hinzufügen (Realismus-Anforderung aus Punkt 4)
    rssi += (Random().nextDouble() * 6) - 3;
    
    return rssi.round();
  }

  @override
  void stopScan() async {
    print('Stopping Real BLE Scanner...');
    _emitTimer?.cancel();
    _scanSubscription?.cancel();
    _adapterSub?.cancel();
    await FlutterBluePlus.stopScan();
  }
}
