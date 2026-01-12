import '../models/beacon_model.dart';

// Das ist eine Vorlage für alle Scanner
abstract class BeaconScanner {
  // Hier kommen die Daten raus (als Strom / Stream)
  Stream<List<BeaconData>> get scanResults;
  
  void startScan();
  void stopScan();
}
