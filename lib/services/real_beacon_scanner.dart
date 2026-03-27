import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/beacon_model.dart';
import 'beacon_scanner.dart';

class RealBeaconScanner implements BeaconScanner {
  final _controller = StreamController<List<BeaconData>>.broadcast();
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  final Map<String, BeaconData> _activeBeacons = {};
  Timer? _emitTimer;

  @override
  Stream<List<BeaconData>> get scanResults => _controller.stream;

  @override
  void startScan() async {
    print('Starting Real BLE Scanner...');
    

    _activeBeacons.clear();

    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }


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
      list.add(BeaconData(
        uuid: 'SIM-BEACON-2',
        major: 1,
        minor: 2,
        rssi: -65, // Fester RSSI-Wert (-65dBm -> ca. 3 Meter)
      ));
      list.add(BeaconData(
        uuid: 'SIM-BEACON-3',
        major: 1,
        minor: 3,
        rssi: -65, // Fester RSSI-Wert (-65dBm -> ca. 3 Meter)
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

  @override
  void stopScan() async {
    print('Stopping Real BLE Scanner...');
    _emitTimer?.cancel();
    _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
  }
}
