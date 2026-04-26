import 'package:flutter/widgets.dart';
import 'package:bluetooth_beacon_diplomarbeit/models/position_model.dart';
import 'package:bluetooth_beacon_diplomarbeit/models/fingerprint_model.dart';

// Minimalistischer Test-Code ohne Material/Cupertino Abhängigkeiten
void main() {
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF121212),
        child: const SimpleTestGui(),
      ),
    ),
  );
}

class SimpleTestGui extends StatelessWidget {
  const SimpleTestGui({super.key});

  @override
  Widget build(BuildContext context) {
    final radioMap = <Fingerprint>[
      Fingerprint(position: Position(x: 1, y: 1), rssiValues: const {}),
      Fingerprint(position: Position(x: 1, y: 2), rssiValues: const {}),
      Fingerprint(position: Position(x: 2, y: 1), rssiValues: const {}),
      Fingerprint(position: Position(x: 2, y: 2), rssiValues: const {}),
      Fingerprint(position: Position(x: 5, y: 5), rssiValues: const {}),
      Fingerprint(position: Position(x: 5, y: 6), rssiValues: const {}),
      Fingerprint(position: Position(x: 8, y: 2), rssiValues: const {}),
      Fingerprint(position: Position(x: 8, y: 3), rssiValues: const {}),
      Fingerprint(position: Position(x: 9, y: 8), rssiValues: const {}),
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "RADIO MAP MATRIX",
            style: TextStyle(
              color: Color(0xFF00FFFF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFFFFF), width: 1),
            ),
            child: CustomPaint(
              painter: RadioMapPainter(radioMap),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Test-Ansicht fuer Diplomarbeit Screenshot",
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class RadioMapPainter extends CustomPainter {
  final List<Fingerprint> fingerprints;
  RadioMapPainter(this.fingerprints);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 10.0;
    
    final gridPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;
      
    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(Offset(i * scale, 0), Offset(i * scale, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * scale), Offset(size.width, i * scale), gridPaint);
    }

    final fpPaint = Paint()..color = const Color(0xCC00FF00);
    for (var fp in fingerprints) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(fp.position.x * scale, fp.position.y * scale),
          width: scale * 0.8,
          height: scale * 0.8,
        ),
        fpPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
