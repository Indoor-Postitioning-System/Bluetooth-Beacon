import '../models/position_model.dart';

class KalmanFilter2D {

  final double q;
  final double r; 

  double _p = 1.0; 

  double? _x; 
  double? _y; 

  KalmanFilter2D({this.q = 0.05, this.r = 0.5});

  Position filter(Position measuredPosition) {
    if (_x == null || _y == null) {
      _x = measuredPosition.x;
      _y = measuredPosition.y;
      return Position(x: _x!, y: _y!);
    }

    _p = _p + q;

    double k = _p / (_p + r); 

    _x = _x! + k * (measuredPosition.x - _x!);
    _y = _y! + k * (measuredPosition.y - _y!);

    _p = (1 - k) * _p;

    return Position(x: _x!, y: _y!);
  }
}
