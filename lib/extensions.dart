/// Extensions file

/// Extension to reduce the decimal part of the double to n places
extension Precision on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

/// Extensions on String
extension E on String {
  /// get last n chars from string.
  String lastChars(int n) => substring(length - n);
  /// check if string is a number.
  bool isNumeric() => double.tryParse(this) != null;
  /// get all characters from string before last n characters.
  String allBeforeLastN(int n) => substring(0, length - n);
}
