library currency_textfield;

import 'package:flutter/material.dart';
import 'dart:math';

/// A custom TextEditingController for currency input.
class CurrencyTextFieldController extends TextEditingController {
  final int _maxDigits = 11; // 999.999.999.99
  final int _numberOfDecimals = 2;

  final String _rightSymbol;
  final String _decimalSymbol;
  final String _thousandSymbol;
  String _previewsText = "";

  final _onlyNumbersRegex = new RegExp(r"[^\d]");

  double _value = 0.0;

  double get doubleValue => _value;
  String get rightSymbol => _rightSymbol;
  String get decimalSymbol => _decimalSymbol;
  String get thousandSymbol => _thousandSymbol;

  CurrencyTextFieldController(
      {String rightSymbol = "R\$ ",
        String decimalSymbol = ",",
        String thousandSymbol = "."})
      : _rightSymbol = rightSymbol,
        _decimalSymbol = decimalSymbol,
        _thousandSymbol = thousandSymbol {
    addListener(_listener);
  }

  String _getOnlyNumbers({String string}) =>
      string.replaceAll(_onlyNumbersRegex, "");

  bool _isOnlyNumbers({String string}) {
    if (string == null || string.isEmpty) return false;

    final clearText = _getOnlyNumbers(string: string);

    return clearText != null ? (clearText.length == string.length) : false;
  }

  String _applyMaskTo({double value}) {
    List<String> textRepresentation = value
        .toStringAsFixed(_numberOfDecimals)
        .replaceAll(".", "")
        .split("")
        .reversed
        .toList(growable: true);

    textRepresentation.insert(_numberOfDecimals, _decimalSymbol);

    var thousandPositionSymbol = _numberOfDecimals + 4;
    while (textRepresentation.length > thousandPositionSymbol) {
      textRepresentation.insert(thousandPositionSymbol, _thousandSymbol);
      thousandPositionSymbol += 4;
    }

    return textRepresentation.reversed.join("");
  }

  double _getDoubleValueFor({String string}) {
    return (double.parse(string) ?? 0.0) / pow(10, _numberOfDecimals);
  }

  String _formatToNumber({String string}) {
    double value = _getDoubleValueFor(string: string);

    return _applyMaskTo(value: value);
  }

  String _clear({String text}) {
    return text
        .replaceAll(_rightSymbol, "")
        .replaceAll(_thousandSymbol, "")
        .replaceAll(_decimalSymbol, "")
        .trim();
  }

  _setSelectionBy({int offset}) {
    selection = TextSelection.fromPosition(TextPosition(offset: offset));
  }

  _listener() {
    if (_previewsText == text) {
      if (_clear(text: text).length == _maxDigits) {
        _setSelectionBy(offset: text.length);
      }
      return;
    }

    final clearText = _clear(text: text);

    if (clearText.isEmpty) {
      _previewsText = "";
      text = "";
      return;
    }

    if (clearText.length > _maxDigits) {
      text = _previewsText;
      return;
    }

    if (!_isOnlyNumbers(string: clearText)) {
      text = _previewsText;
      return;
    }

    if ((double.parse(clearText) ?? 0.0) == 0.0) {
      _previewsText = "";
      text = "";
      return;
    }

    final maskedValue = "$_rightSymbol${_formatToNumber(string: clearText)}";

    _previewsText = maskedValue;
    _value = _getDoubleValueFor(string: clearText);
    text = maskedValue;

    _setSelectionBy(offset: text.length);
  }

  @override
  void dispose() {
    removeListener(_listener);
    super.dispose();
  }
}
