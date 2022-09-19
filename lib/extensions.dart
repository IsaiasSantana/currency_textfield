import 'package:decimal/decimal.dart';

extension Precision on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
  Decimal decimal() => Decimal.parse(toString());
}