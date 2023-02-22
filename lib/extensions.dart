extension Precision on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

extension E on String {
  String lastChars(int n) => substring(length - n);
  bool isNumeric() => double.tryParse(this) != null;
  String allBeforeLastN(int n) => substring(0, length - n);
}
