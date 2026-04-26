import '../models/position_model.dart';

class KalmanFilter2D {
  // Prozessrauschen (Q) und Messrauschen (R)
  // In der Diplomarbeit: Dynamische Anpassung dieser Werte moeglich
  double q;
  double r; 

  double _p = 1.0; 

  double? _x; 
  double? _y; 

  KalmanFilter2D({this.q = 0.05, this.r = 0.5});

  /// Vorhersage-Schritt (Prediction): Nutzt die Sensordaten (Koppelnavigation)
  /// velocity: Vektor aus Beschleunigungssensor und Kompass
  /// dt: Zeit seit der letzten Messung (z.B. 1.0 Sekunde)
  void predict(Position velocity, {double dt = 1.0}) {
    if (_x == null || _y == null) return;

    // Zustands-Vorhersage: x = x + v * dt
    _x = _x! + (velocity.x * dt);
    _y = _y! + (velocity.y * dt);

    // Fehler-Kovarianz Vorhersage
    _p = _p + q;
  }

  /// Korrektur-Schritt (Update): Nutzt die Bluetooth-Messung (WKNN Ergebnis)
  Position update(Position measuredPosition) {
    if (_x == null || _y == null) {
      _x = measuredPosition.x;
      _y = measuredPosition.y;
      return Position(x: _x!, y: _y!);
    }

    // Adaptive Tuning (Punkt 2): Wenn die Messung stark abweicht, erhoehen wir R
    // double innovation = (measuredPosition.x - _x!).abs() + (measuredPosition.y - _y!).abs();
    // double adaptiveR = (innovation > 2.0) ? r * 2 : r;

    // Kalman-Gain berechnen
    double k = _p / (_p + r); 

    // Zustand korrigieren
    _x = _x! + k * (measuredPosition.x - _x!);
    _y = _y! + k * (measuredPosition.y - _y!);

    // Fehler-Kovarianz korrigieren
    _p = (1 - k) * _p;

    return Position(x: _x!, y: _y!);
  }

  // Kompatibilitaets-Methode fuer alten Code
  Position filter(Position measuredPosition) {
    return update(measuredPosition);
  }
}
