import 'dart:async';
import 'dart:math';
import 'beacon_scanner.dart';
import '../models/beacon_model.dart';

class MockBeaconScanner implements BeaconScanner {
  // Der "Stream" schickt die Daten an die App
  final _controller = StreamController<List<BeaconData>>.broadcast();
  Timer? _timer;
  
  // Fake Position vom User (um Bewegung zu simulieren)
  double userX = 0;
  double userY = 0;
  double angle = 0; // Winkel für die Kreisbewegung

  @override
  Stream<List<BeaconData>> get scanResults => _controller.stream;

  @override
  void startScan() {
    print('Starte Mock Scanner...');
    // Jede Sekunde neue Daten generieren
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bewegeUserImKreis();
      var beacons = erstelleBeacons();
      _controller.add(beacons);
    });
  }

  @override
  void stopScan() {
    _timer?.cancel();
  }
  
  // Simuliert, dass der User im Kreis läuft
  void bewegeUserImKreis() {
    // Einfache Mathe für einen Kreis
    userX = 5.0 + 3.0 * cos(angle);
    userY = 5.0 + 3.0 * sin(angle);
    
    // Winkel erhöhen damit er sich weiterdreht
    angle += 0.1;
  }

  List<BeaconData> erstelleBeacons() {
    var liste = <BeaconData>[];
    
    // Wir tun so, als gäbe es 3 Beacons im Raum
    // Beacon 1 oben links (0,0)
    liste.add(baueBeacon(1, 0, 0));
    
    // Beacon 2 oben rechts (10,0)
    liste.add(baueBeacon(2, 10, 0));
    
    // Beacon 3 unten mitte (5,10)
    liste.add(baueBeacon(3, 5, 10));
    
    return liste;
  }
  
  BeaconData baueBeacon(int nummer, double beaconX, double beaconY) {
    // Abstand berechnen (Satz des Pythagoras)
    double abstand = sqrt(pow(beaconX - userX, 2) + pow(beaconY - userY, 2));
    
    // Signalstärke berechnen (je weiter weg, desto schwächer)
    // Wir nehmen an: 1 Meter = -60 dBm
    double signal = -60 - (20 * log(abstand + 0.1) / ln10);
    
    // Ein bisschen Zufall hinzufügen ("Rauschen"), damit es echt wirkt
    var zufall = Random().nextInt(6) - 3; // Zahl zwischen -3 und +3
    
    return BeaconData(
      uuid: '0000-0000', // Fake ID
      major: nummer, 
      minor: 1,
      rssi: (signal + zufall).round(),
    );
  }
}
