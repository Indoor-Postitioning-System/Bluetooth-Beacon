import 'dart:math';
import '../models/beacon_model.dart';
import '../models/fingerprint_model.dart';
import '../models/position_model.dart';

class PositioningEngine {
  List<Fingerprint> radioMap = [];

  PositioningEngine() {
    ladeRadioMap();
  }

  // Hier speichern wir unsere "Fingerabdrücke"
  // Das sind Punkte im Raum, wo wir wissen, wie stark das Signal sein sollte.
  void ladeRadioMap() {
    // IDs von den Beacons (muss zur MockBeaconScanner passen)
    String b1 = '0000-0000-1-1';
    String b2 = '0000-0000-2-1';
    String b3 = '0000-0000-3-1';

    // Punkt 1: Oben Links (Nahe B1)
    radioMap.add(Fingerprint(
      position: const Position(x: 1, y: 1),
      rssiValues: {b1: -60, b2: -80, b3: -85}, 
    ));

    // Punkt 2: Oben Rechts (Nahe B2)
    radioMap.add(Fingerprint(
      position: const Position(x: 9, y: 1),
      rssiValues: {b1: -80, b2: -60, b3: -85}, 
    ));

    // Punkt 3: Unten Mitte (Nahe B3)
    radioMap.add(Fingerprint(
      position: const Position(x: 5, y: 9),
      rssiValues: {b1: -85, b2: -85, b3: -60}, 
    ));
    
    // Punkt 4: Mitte
    radioMap.add(Fingerprint(
      position: const Position(x: 5, y: 5),
      rssiValues: {b1: -70, b2: -70, b3: -70}, 
    ));
  }

  // Der Algorithmus: Wo bin ich?
  Position? calculatePosition(List<BeaconData> aktuelleMessung) {
    if (aktuelleMessung.isEmpty) return null;

    // 1. Messung vorbereiten (in eine Liste umwandeln)
    var messungMap = <String, int>{};
    for (var b in aktuelleMessung) {
      messungMap[b.id] = b.rssi;
    }

    // 2. Abstände zu allen bekannten Punkten berechnen
    var abstaende = <_AbstansHelper>[];
    
    for (var fingerabdruck in radioMap) {
      double dist = berechneAbstand(messungMap, fingerabdruck.rssiValues);
      abstaende.add(_AbstansHelper(fingerabdruck, dist));
    }

    // 3. Sortieren: Die kleinsten Abstände zuerst
    abstaende.sort((a, b) => a.abstand.compareTo(b.abstand));

    // 4. Die 3 besten nehmen ("k-Nearest Neighbors")
    var besteTreffer = abstaende.take(3).toList();
    if (besteTreffer.isEmpty) return null;

    // 5. Mittelwert berechnen
    double summeX = 0;
    double summeY = 0;
    
    for (var treffer in besteTreffer) {
      summeX += treffer.fingerprint.position.x;
      summeY += treffer.fingerprint.position.y;
    }

    return Position(
      x: summeX / besteTreffer.length,
      y: summeY / besteTreffer.length,
    );
  }

  // Berechnet wie unähnlich zwei Signale sind (Euklidische Distanz)
  double berechneAbstand(Map<String, int> messung, Map<String, int> datenbank) {
    double summe = 0;
    
    datenbank.forEach((id, dbWert) {
      // Wenn wir den Beacon nicht messen, nehmen wir einen schlechten Wert an (-100)
      int gemessenerWert = messung[id] ?? -100;
      
      double diff = (gemessenerWert - dbWert).toDouble();
      summe += diff * diff; // Quadrat
    });

    return sqrt(summe);
  }
}

// Kleine Hilfsklasse um Abstand zu speichern
class _AbstansHelper {
  final Fingerprint fingerprint;
  final double abstand;

  _AbstansHelper(this.fingerprint, this.abstand);
}
