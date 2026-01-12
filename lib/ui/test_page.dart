import 'package:flutter/material.dart';
import '../models/beacon_model.dart';
import '../models/position_model.dart';
import '../services/beacon_scanner.dart';
import '../services/mock_beacon_scanner.dart';
import '../services/positioning_engine.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  // Meine Dienste (Services)
  var scanner = MockBeaconScanner();
  var engine = PositioningEngine();
  
  // Meine Variablen
  List<BeaconData> beaconList = [];
  Position? myPosition;

  @override
  void initState() {
    super.initState();
    startMyScan();
  }

  void startMyScan() {
    scanner.startScan();
    scanner.scanResults.listen((data) {
      // Prüfen ob die Seite noch offen ist
      if (mounted) {
        setState(() {
          beaconList = data;
          // Berechne meine Position
          myPosition = engine.calculatePosition(data);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("First Test App"),
      ),
      body: Column(
        children: [
          // Der Karten-Bereich
          Container(
            height: 400,
            width: 400,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
            ),
            child: CustomPaint(
              painter: MyMapPainter(
                userPos: myPosition, 
                beacons: beaconList
              ),
            ),
          ),
          
          // Die Überschrift
          const Text(
            "My Data:", 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
          ),

          // Die Liste der Beacons
          Expanded(
            child: ListView.builder(
              itemCount: beaconList.length,
              itemBuilder: (context, index) {
                var currentBeacon = beaconList[index];
                return ListTile(
                  title: Text("B ${currentBeacon.major}"), 
                  subtitle: Text("Signal: ${currentBeacon.rssi}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MyMapPainter extends CustomPainter {
  final Position? userPos;
  final List<BeaconData> beacons;

  MyMapPainter({this.userPos, required this.beacons});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Farben definieren
    var borderPaint = Paint();
    borderPaint.color = Colors.grey;
    borderPaint.style = PaintingStyle.stroke;
    
    var beaconPaint = Paint();
    beaconPaint.color = Colors.red;
    beaconPaint.style = PaintingStyle.fill;
    
    var userPaint = Paint();
    userPaint.color = Colors.blue;
    userPaint.style = PaintingStyle.fill;

    // 2. Den Raum-Rahmen zeichnen
    var rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, borderPaint);

    // 10 Meter auf den Bildschirm skalieren
    double scale = size.width / 10.0;

    // 3. Die festen Beacons zeichnen
    // Beacon 1 (0,0)
    canvas.drawCircle(Offset(0 * scale, 0 * scale), 10, beaconPaint);
    
    // Beacon 2 (10,0)
    canvas.drawCircle(Offset(10 * scale, 0 * scale), 10, beaconPaint);
    
    // Beacon 3 (5,10)
    canvas.drawCircle(Offset(5 * scale, 10 * scale), 10, beaconPaint);

    // 4. Den User zeichnen (wenn Position da ist)
    if (userPos != null) {
      double x = userPos!.x * scale;
      double y = userPos!.y * scale;
      
      canvas.drawCircle(Offset(x, y), 15, userPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Immer neu zeichnen
  }
}
