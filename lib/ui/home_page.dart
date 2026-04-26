import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/beacon_model.dart';
import '../models/position_model.dart';
import '../models/fingerprint_model.dart';
import '../services/real_beacon_scanner.dart';
import '../services/positioning_engine.dart';

import '../services/mock_beacon_scanner.dart';
import '../services/beacon_scanner.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Echte Scanner und Engine
  late final BeaconScanner scanner;
  final engine = PositioningEngine();
  
  List<BeaconData> currentBeacons = [];
  Position? rawPosition;
  Position? filteredPosition;
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  
  // Modus: false = Tracking, true = Kalibrierung (Fingerings anlegen)
  bool isCalibrationMode = false;

  // Schalter für die Diplomarbeits-Prüfung: Simulator immer an auf dem Handy anzeigen
  bool forceSimulator = true;

  @override
  void initState() {
    super.initState();
    // Use Mock on Desktop/Web, oder wenn forceSimulator aktiv ist (für das Handy)
    if (forceSimulator || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      scanner = MockBeaconScanner();
      engine.autoCalibrateSimulatedEnvironment();
    } else {
      scanner = RealBeaconScanner();
      // Punkt 3: Auf Bluetooth Status hören für UI Overlay
      FlutterBluePlus.adapterState.listen((state) {
        if (mounted) {
          setState(() {
            _bluetoothState = state;
          });
        }
      });
    }
    engine.sensorService.start(); // Punkt 1: Sensoren für Dead Reckoning aktivieren
    _requestPermissionsAndStart();
  }

  Future<void> _requestPermissionsAndStart() async {
    if (scanner is MockBeaconScanner) {
      _startScanning();
      return;
    }

    // Bluetooth & Location Permissions anfragen
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (allGranted) {
      _startScanning();
    } else {
      // Wenn abgelehnt (Vereinfachtes Fehlerhandling für Dipl-Arbeit)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte Berechtigungen in den Einstellungen erlauben!')),
        );
      }
    }
  }

  void _startScanning() {
    scanner.startScan();
    scanner.scanResults.listen((data) {
      if (mounted) {
        setState(() {
          currentBeacons = data;
          
          if (!isCalibrationMode) {
             // Nur Position berechnen, wenn mindestens 3 Beacons gefunden wurden (1 echter + 2 simulierte)
             if (data.length >= 3) {
               engine.calculatePosition(data);
               rawPosition = engine.currentRawPosition;
               filteredPosition = engine.currentFilteredPosition;
             } else {
               rawPosition = null;
               filteredPosition = null;
             }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    scanner.stopScan();
    super.dispose();
  }

  void _handleMapTap(TapUpDetails details, Size mapSize) {
    if (!isCalibrationMode) return;

    // 10 Meter Skalierung: Wo hat der Nutzer hingeklickt?
    double scale = mapSize.width / 10.0;
    
    // Relative Klick-Position in Metern umrechnen
    double tapX = details.localPosition.dx / scale;
    double tapY = details.localPosition.dy / scale;

    Position targetPos = Position(x: tapX, y: tapY);

    // Fingerprint speichern (Aktuelle Messwerte -> Angeklickte Position)
    engine.saveFingerprint(targetPos, currentBeacons);
    
    // UI Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fingerprint gespeichert! Beacons: ${currentBeacons.length}'),
        duration: const Duration(seconds: 1),
      ),
    );

    setState(() {}); // Karte neu zeichnen um den neuen Fingerprint anzuzeigen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Deep dark tech blue
      body: SafeArea(
        child: Column(
          children: [
            // Custom Sci-Fi Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IPS ENGINE', style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('LIVE TRACKING', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("CALIBRATE", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      Switch(
                        activeColor: Colors.cyanAccent,
                        value: isCalibrationMode,
                        onChanged: (val) {
                          setState(() {
                            isCalibrationMode = val;
                            if (val) {
                              rawPosition = null;
                              filteredPosition = null;
                            }
                          });
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          // INFO-Banner für den aktuellen Modus
          if (isCalibrationMode)
            Container(
              color: Colors.orange.shade200,
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: const Center(
                child: Text("Tippe auf die Karte, um aktuelle Messung als Fingerprint zu speichern"),
              ),
            ),
            
          // Punkt 3: Visuelles Alarm/Overlay wenn Bluetooth aus ist (Nur Handy)
          if (scanner is RealBeaconScanner && _bluetoothState == BluetoothAdapterState.off)
            Container(
              color: Colors.red,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth_disabled, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "BLUETOOTH DEAKTIVIERT - BITTE EINSCHALTEN!", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
          // Warnung wenn zu wenige Beacons
          if (!isCalibrationMode && currentBeacons.length < 3)
            Container(
              color: Colors.red.shade100,
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: const Center(
                child: Text(
                  "Warte auf Bluetooth Signale (Mindestens 3 Beacons benötigt: 1 physischer + 2 simulierte)", 
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Der große Karten-Bereich
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Mache die Karte quadratisch, so groß wie möglich
                double size = constraints.maxWidth < constraints.maxHeight 
                    ? constraints.maxWidth - 40 
                    : constraints.maxHeight - 40;
                
                return Center(
                  child: GestureDetector(
                    onTapUp: (details) => _handleMapTap(details, Size(size, size)),
                    onPanUpdate: (details) {
                      if (scanner is MockBeaconScanner && !isCalibrationMode) {
                        double scale = size / 10.0;
                        double tapX = details.localPosition.dx / scale;
                        double tapY = details.localPosition.dy / scale;
                        setState(() {
                          MockBeaconScanner.simulatedUserPosition = Position(
                            x: tapX.clamp(0.0, 10.0), 
                            y: tapY.clamp(0.0, 10.0)
                          );
                        });
                      }
                    },
                    child: Container(
                      height: size,
                      width: size,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24, width: 1.5),
                        color: const Color(0xFF101010), // Map background (almost black)
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.05), // White Glow
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                          const BoxShadow(
                            color: Colors.black54, 
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 10),
                          ),
                        ]
                      ),
                      child: CustomPaint(
                        painter: ModernMapPainter(
                          rawPos: rawPosition,
                          filteredPos: filteredPosition,
                          fingerprints: engine.radioMap, // Zeigt wo wir schon Daten haben
                          isSimulator: scanner is MockBeaconScanner,
                          simulatedUserPos: scanner is MockBeaconScanner ? MockBeaconScanner.simulatedUserPosition : null,
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
          
          // Legende unten an der Karte
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, color: Colors.white54, size: 12),
                const Text(" RAW   ", style: TextStyle(color: Colors.white70, fontSize: 11)),
                const Icon(Icons.circle, color: Colors.white, size: 12),
                const Text(" FILTERED   ", style: TextStyle(color: Colors.white70, fontSize: 11)),
                if (scanner is MockBeaconScanner) ...[
                  const Icon(Icons.circle, color: Colors.grey, size: 12),
                  const Text(" VIRTUAL USER   ", style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const Icon(Icons.circle_outlined, color: Colors.white, size: 12),
                  const Text(" BEACONS", style: TextStyle(color: Colors.white70, fontSize: 11)),
                ]
              ],
            ),
          ),

          const SizedBox(height: 10),
          // Liste der Beacons unten (Glassmorphism)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ]
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                ]
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ACTIVATED SIGNALS", 
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.cyanAccent)
                        ),
                        Icon(Icons.wifi_tethering, color: Colors.cyanAccent, size: 20),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: currentBeacons.isEmpty 
                      ? const Center(child: Text("Suche nach BLE Signalen..."))
                      : ListView.builder(
                          itemCount: currentBeacons.length,
                          itemBuilder: (context, index) {
                            var beacon = currentBeacons[index];
                            return ListTile(
                              leading: const Icon(Icons.bluetooth, color: Colors.blue),
                              title: Text("ID: ${beacon.id}"), // UUID / Mac
                              subtitle: Text("Empfangsstärke (RSSI)"),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getColorForRssi(beacon.rssi).withOpacity(0.8),
                                      _getColorForRssi(beacon.rssi),
                                    ]
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getColorForRssi(beacon.rssi).withOpacity(0.4),
                                      blurRadius: 8,
                                    )
                                  ]
                                ),
                                child: Text("${beacon.rssi} dBm", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // Hilfsfunktion: Je stärker das Signal, desto grüner
  Color _getColorForRssi(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }
}

class ModernMapPainter extends CustomPainter {
  final Position? rawPos;
  final Position? filteredPos;
  final List<Fingerprint> fingerprints;
  final bool isSimulator;
  final Position? simulatedUserPos;

  ModernMapPainter({
    this.rawPos, 
    this.filteredPos, 
    required this.fingerprints,
    this.isSimulator = false,
    this.simulatedUserPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scale = size.width / 10.0; // Raum ist 10x10 Meter künstlich skaliert

    // 1. Black & White Floorplan (Blueprint Style)
    var wallPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var roomPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.fill;

    // Raum-Füllungen
    canvas.drawRect(Rect.fromLTRB(1 * scale, 1 * scale, 5 * scale, 6 * scale), roomPaint); 
    canvas.drawRect(Rect.fromLTRB(5 * scale, 1 * scale, 9 * scale, 6 * scale), roomPaint); 
    canvas.drawRect(Rect.fromLTRB(1 * scale, 6 * scale, 9 * scale, 9 * scale), Paint()..color = Colors.white.withOpacity(0.02)); 

    // Außenwände
    canvas.drawRect(Rect.fromLTRB(1 * scale, 1 * scale, 9 * scale, 9 * scale), wallPaint);
    
    // Innenwände
    canvas.drawLine(Offset(5 * scale, 1 * scale), Offset(5 * scale, 6 * scale), wallPaint); 
    canvas.drawLine(Offset(1 * scale, 6 * scale), Offset(2.5 * scale, 6 * scale), wallPaint); 
    canvas.drawLine(Offset(3.5 * scale, 6 * scale), Offset(6.5 * scale, 6 * scale), wallPaint); 
    canvas.drawLine(Offset(7.5 * scale, 6 * scale), Offset(9 * scale, 6 * scale), wallPaint); 

    // Türen (White, Thicker)
    var doorPaint = Paint()..color = Colors.white..strokeWidth = 3;
    canvas.drawLine(Offset(2.5 * scale, 6 * scale), Offset(3.3 * scale, 5.2 * scale), doorPaint);
    canvas.drawLine(Offset(6.5 * scale, 6 * scale), Offset(7.3 * scale, 5.2 * scale), doorPaint);

    // Grid Matrix drüberzeichnen (Subtle White)
    var gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
      
    for (int i = 0; i <= 10; i++) {
      double pos = i * scale;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
    }

    // System zeichnet keine hässlichen grünen Quadrate mehr, sondern nur eine Blueprint-Umgebung

    // Beacons zeichnen (immer sichtbar, 2 simulierte + 1 physisch auf der Karte platziert als Referenz)
    var virtBeaconPaint = Paint()..color = Colors.white70;
    var virtGlow = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
    // Beacon 1
    canvas.drawCircle(Offset(2.0 * scale, 2.0 * scale), 20, virtGlow);
    canvas.drawCircle(Offset(2.0 * scale, 2.0 * scale), 4, virtBeaconPaint);
    canvas.drawCircle(Offset(2.0 * scale, 2.0 * scale), 10, virtBeaconPaint..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Beacon 2
    canvas.drawCircle(Offset(8.0 * scale, 2.0 * scale), 20, virtGlow);
    canvas.drawCircle(Offset(8.0 * scale, 2.0 * scale), 4, virtBeaconPaint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(8.0 * scale, 2.0 * scale), 10, virtBeaconPaint..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Beacon 3
    canvas.drawCircle(Offset(5.0 * scale, 8.0 * scale), 20, virtGlow);
    canvas.drawCircle(Offset(5.0 * scale, 8.0 * scale), 4, virtBeaconPaint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(5.0 * scale, 8.0 * scale), 10, virtBeaconPaint..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Simulator Visualisierung: Virtueller User (nur Mock Umgebung)
    if (simulatedUserPos != null) {
      var userCore = Paint()..color = Colors.grey;
      var userGlow = Paint()..color = Colors.white12..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(simulatedUserPos!.x * scale, simulatedUserPos!.y * scale), 20, userGlow);
      canvas.drawCircle(Offset(simulatedUserPos!.x * scale, simulatedUserPos!.y * scale), 6, userCore);
    }

    // 3. User Rohdaten
    if (rawPos != null) {
      var rawPaint = Paint()..color = Colors.white24;
      canvas.drawCircle(Offset(rawPos!.x * scale, rawPos!.y * scale), 15, rawPaint);
    }

    // 4. User Gefiltert (Final)
    if (filteredPos != null) {
      var filteredGlow = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      var filteredPaint = Paint()..color = Colors.redAccent;
      
      canvas.drawCircle(Offset(filteredPos!.x * scale, filteredPos!.y * scale), 15, filteredGlow);
      canvas.drawCircle(Offset(filteredPos!.x * scale, filteredPos!.y * scale), 6, filteredPaint);
      
      // Kleiner Kern
      var innerPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(filteredPos!.x * scale, filteredPos!.y * scale), 3, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
