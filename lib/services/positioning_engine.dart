import 'dart:math';
import '../models/beacon_model.dart';
import '../models/fingerprint_model.dart';
import '../models/position_model.dart';
import 'kalman_filter.dart';
import 'sensor_service.dart';

class PositioningEngine {
  // Nun leer, da wir im Kalibrierungs-Modus echte Messdaten abspeichern
  List<Fingerprint> radioMap = [];
  
  // Der Sensorfusions-Filter
  final KalmanFilter2D kalmanFilter = KalmanFilter2D(q: 0.05, r: 0.5);
  final SensorService sensorService = SensorService();

  // Ergebnisse speichern, damit die UI sie abrufen kann
  Position? currentRawPosition;
  Position? currentFilteredPosition;

  PositioningEngine();

  // Generiert automatisch ein verstecktes 10x10 Meter Referenz-Raster für perfekte Netzabdeckung
  void autoCalibrateSimulatedEnvironment() {
    print("Auto-calibrating hidden 10x10 grid for full WKNN coverage...");
    radioMap.clear();
    
    Position b1 = Position(x: 2.0, y: 2.0);
    Position b2 = Position(x: 8.0, y: 2.0);
    Position b3 = Position(x: 5.0, y: 8.0);

    // Wir MÜSSEN den kompletten Raum kalibrieren, da k-NN mathematisch niemals
    // den Raum verlassen könnte, der von den Fingerprints aufgespannt wird!
    for (double x = 0; x <= 10; x += 1.0) {
      for (double y = 0; y <= 10; y += 1.0) {
        Position p = Position(x: x, y: y);
        radioMap.add(Fingerprint(
          position: p, 
          rssiValues: {
            'SIM-BEACON-1-1-1': _calcTheoreticalRSSI(p, b1),
            'SIM-BEACON-2-1-2': _calcTheoreticalRSSI(p, b2),
            'SIM-BEACON-3-1-3': _calcTheoreticalRSSI(p, b3),
          }
        ));
      }
    }
  }

  int _calcTheoreticalRSSI(Position user, Position beacon) {
    double dx = user.x - beacon.x;
    double dy = user.y - beacon.y;
    double dist = sqrt(dx*dx + dy*dy);
    if (dist < 0.1) dist = 0.1;
    return (-50 - 10 * 2.5 * log(dist) / ln10).round();
  }

  void saveFingerprint(Position targetPosition, List<BeaconData> aktuelleMessung) {
    if (aktuelleMessung.isEmpty) return;

    var rssiWerte = <String, int>{};
    for (var b in aktuelleMessung) {
      rssiWerte[b.id] = b.rssi; 
    }

    radioMap.add(Fingerprint(
      position: targetPosition,
      rssiValues: rssiWerte,
    ));

    print("Fingerprint gespeichert bei X:${targetPosition.x.toStringAsFixed(1)}, Y:${targetPosition.y.toStringAsFixed(1)} mit ${rssiWerte.length} Beacons.");
  }

  // Der Algorithmus: Wo bin ich?
  void calculatePosition(List<BeaconData> aktuelleMessung) {
    if (aktuelleMessung.isEmpty || radioMap.isEmpty) {
      currentRawPosition = null;
      currentFilteredPosition = null;
      return;
    }

    var messungMap = <String, int>{};
    for (var b in aktuelleMessung) {
      messungMap[b.id] = b.rssi;
    }

    var abstaende = <_AbstansHelper>[];
    
    for (var fingerabdruck in radioMap) {
      double dist = berechneAbstand(messungMap, fingerabdruck.rssiValues);
      abstaende.add(_AbstansHelper(fingerabdruck, dist));
    }

    abstaende.sort((a, b) => a.abstand.compareTo(b.abstand));

    int k = min(3, abstaende.length);
    var besteTreffer = abstaende.take(k).toList();
    
    if (besteTreffer.isEmpty) {
      currentRawPosition = null;
      currentFilteredPosition = null;
      return;
    }

    // WKNN: Gewichte errechnen (je kleiner der Abstand, desto höher das Gewicht)
    double summeX = 0;
    double summeY = 0;
    double gewichtSumme = 0;
    
    for (var treffer in besteTreffer) {
      // Inverse Distanz Wichtung (WKNN)
      double weight = 1.0 / (pow(treffer.abstand, 2) + 0.1); 
      summeX += treffer.fingerprint.position.x * weight;
      summeY += treffer.fingerprint.position.y * weight;
      gewichtSumme += weight;
    }

    currentRawPosition = Position(
      x: summeX / gewichtSumme,
      y: summeY / gewichtSumme,
    );

    // SENSOR FUSION (Punkt 1 & 2):
    // 1. Vorhersage basierend auf Sensoren (Dead Reckoning)
    kalmanFilter.predict(sensorService.getVelocityVector(), dt: 1.0);

    // 2. Korrektur basierend auf Bluetooth (WKNN)
    currentFilteredPosition = kalmanFilter.update(currentRawPosition!);
  }

  // Berechnet wie unähnlich zwei Signale sind (Euklidische Distanz)
  double berechneAbstand(Map<String, int> messung, Map<String, int> datenbank) {
    double summe = 0;
    
    datenbank.forEach((id, dbWert) {
      // Wenn wir den in der Datenbank gespeicherten Beacon JETZT nicht messen, 
      // nehmen wir einen sehr schlechten Wert an (-100 dBm, sehr weit weg)
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
