# Checkliste: Erweiterung des Indoor-Positioning-Systems

## Sprint 6: Sensorik & Core-Logik (Punkte 1, 2, 3 & 4) - ✅ ERLEDIGT

- [x] **1. Beschleunigungssensor und Kompass (Gyro) einbauen (Echte Sensorfusion)**
  - [x] Package `sensors_plus` in die `pubspec.yaml` einfügen.
  - [x] Stream-Listener für den Pedometer (Schrittzähler) oder Beschleunigungsmesser (Accelerometer) bauen, um echte physikalische Vorwärtsbewegung des Nutzers zu erfassen.
  - [x] Kompass-Werte (Magnetometer) abgreifen, um die Blickrichtung zu bestimmen.
  - [x] Berechnung der sogenannten Koppelnavigation (Dead Reckoning).
  - *📸 Screenshot-Tipp: `lib/services/sensor_service.dart` (Zeilen 15-45: Sensor-Listener & Vektor-Berechnung)*

- [x] **2. Sensorfusions-Algorithmus (Kalman Filter) grundlegend verbessern**
  - [x] Die `KalmanFilter2D` Klasse umbauen, sodass sie nun Bewegungsdaten aus Punkt 1 verarbeiten kann.
  - [x] **Dynamisches "Adaptive Kalman" Tuning:** Filtermatrizen (Messrauschen `R` und Prozessrauschen `Q`) zur Laufzeit dynamisch anpassen.
  - [x] Filter-Logik mit Bluetooth WKNN-Rückgabewerten verschmelzen.
  - *📸 Screenshot-Tipp: `lib/services/kalman_filter.dart` (Zeilen 18-30: Vorhersage-Schritt `predict`)*

- [x] **3. Robustes Error-Handling implementieren (Nur Mobile)**
  - [x] In `real_beacon_scanner.dart` permanent auf den `FlutterBluePlus.adapterState` hören.
  - [x] UI State-Management anpassen: Wenn der Status auf `off` springt, Scan stoppen.
  - [x] Visuelles Alarm/Overlay-Widget auf der `HomePage` bauen.
  - [x] Recovery-Logik: Sobald Bluetooth wieder auf `on` wechselt, Scans sanft wieder aufnehmen.
  - *📸 Screenshot-Tipp: `lib/ui/home_page.dart` (Zeilen 180-200: Bluetooth Error-Overlay Code)*

- [x] **4. Angleichung von Code & Diplomarbeit-Inhalt (Softwaresimulation)**
  - [x] Den fest gecodeten `-65` RSSI-Wert in `real_beacon_scanner.dart` entfernen.
  - [x] Die dynamische RSSI-Berechnung basierend auf dem Log-Distanz-Pfadverlustmodell (inkl. ±3 dBm Rauschen) einfügen.
  - *📸 Screenshot-Tipp: `lib/services/real_beacon_scanner.dart` (Zeilen 75-90: Methode `_calculatePathLossRSSI` mit der physikalischen Formel)*

---

## Sprint 7: Visualisierung & Deployment (Punkte 5 & 6)

- [ ] **5. Heatmap & Signalqualitäts-Visualisierung (Admin UI)**
  - [ ] Heatmap-Overlay über der Raster-Map implementieren.
  - [ ] Farbliche Visualisierung (Rot/Gelb/Grün) für Signalstärke und Deadzones einbauen.
  - [ ] Schalter zum Ein-/Ausblenden der Heatmap zwecks Screenshots für die Diplomarbeit integrieren.

- [ ] **6. Android Bluetooth Fix & Dynamische Beacon-Initialisierung**
  - [ ] **Android Berechtigungen fixen:** Das Nicht-Scannen am Android-Handy beheben (Fehlende `BLUETOOTH_SCAN` / `LOCATION` Berechtigungsabfragen via `permission_handler` in Dart & AndroidManifest sauber implementieren).
  - [ ] **Setup-Phase (App-Start) einbauen:** App blockiert beim Start das UI, wartet auf das erste Signal des echten Beacons und berechnet dessen Distanz via Pfadverlustmodell.
  - [ ] **Dynamische Positionierung der Simulation:** Die 2 simulierten Beacons mathematisch (Trigonometrie/Kreisgleichung) in etwa demselben Radius auf der lokalen Radio-Map platzieren.
  - [ ] `PositioningEngine` erst nach diesem erfolgreichem Setup starten.
