import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/position_model.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription? _accelSub;
  StreamSubscription? _magnetSub;

  double _currentSpeed = 0.0;
  double _currentHeading = 0.0; // In Radiant

  // Hilfsvariablen für die Berechnung
  double _lastAccelMag = 0.0;
  
  void start() {
    // 1. Accelerometer für die Geschwindigkeits-Schätzung (Einfacher Pedometer-Ersatz)
    _accelSub = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      double mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Wenn die Beschleunigung einen Schwellenwert überschreitet, gehen wir von Bewegung aus
      if (mag > 1.2) {
        _currentSpeed = 1.2; // Durchschnittliche Gehgeschwindigkeit ca. 1.2 m/s
      } else {
        _currentSpeed *= 0.9; // Sanftes Abbremsen
        if (_currentSpeed < 0.1) _currentSpeed = 0.0;
      }
      _lastAccelMag = mag;
    });

    // 2. Magnetometer für die Blickrichtung (Kompass)
    _magnetSub = magnetometerEvents.listen((MagnetometerEvent event) {
      // Berechnung des Winkels (Heading) in der XY-Ebene
      _currentHeading = atan2(event.y, event.x);
    });
  }

  // Gibt den Bewegungs-Vektor zurück (für die Kalman-Vorhersage)
  Position getVelocityVector() {
    return Position(
      x: _currentSpeed * cos(_currentHeading),
      y: _currentSpeed * sin(_currentHeading),
    );
  }

  void stop() {
    _accelSub?.cancel();
    _magnetSub?.cancel();
  }
}
