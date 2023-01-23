library currency_textfield_2;

import 'package:currency_textfield_2/extensions.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// A custom TextEditingController for currency input.
///
/// [leftSymbol] it's your currency symbol.
///
/// [decimalSymbol] it's the decimal separator symbol.
///
/// [thousandSymbol] it's the thousand separator symbol.
///
/// [initDoubleValue] it's the optional initial value in double format.
///
/// [initIntValue] it's the optional initial value in int format. It'll be divided by 100 before being presented.
///
/// [numberOfDecimals] lets you define the max number of decimal digits to be presented.
///
/// [maxDigits] lets you define the max number of digits to be presented.
///
class CurrencyTextFieldController extends TextEditingController {
  final int _maxDigits;
  final int _numberOfDecimals;

  final String _leftSymbol;
  final String _decimalSymbol;
  final String _thousandSymbol;
  String _previewsText = '';

  final _onlyNumbersRegex = RegExp(r'[^\d]');

  double _value = 0.0;

  double get doubleValue => _value.toPrecision(_numberOfDecimals);
  String get leftSymbol => _leftSymbol;
  String get decimalSymbol => _decimalSymbol;
  String get thousandSymbol => _thousandSymbol;
  int get intValue => int.tryParse(_getOnlyNumbers(string: text) ?? '') ?? 0;

  CurrencyTextFieldController({
    String leftSymbol = 'R\$ ',
    String decimalSymbol = ',',
    String thousandSymbol = '.',
    double? initDoubleValue,
    int? initIntValue,
    int maxDigits = 15,
    int numberOfDecimals = 2,
  })  : assert(
          !(initDoubleValue != null && initIntValue != null),
          "You must set either 'initDoubleValue' or 'initIntValue' parameter",
        ),
        _leftSymbol = leftSymbol,
        _decimalSymbol = decimalSymbol,
        _thousandSymbol = thousandSymbol,
        _maxDigits = maxDigits,
        _numberOfDecimals = numberOfDecimals {
    if (initDoubleValue != null) {
      _previewsText = "$_leftSymbol${_applyMaskTo(value: initDoubleValue)}";
      _value = initDoubleValue;
      text = _previewsText;
      _setSelectionBy(offset: text.length);
    } else if (initIntValue != null) {
      _previewsText = "$_leftSymbol${_applyMaskTo(value: initIntValue / 100)}";
      _value = initIntValue / 100;
      text = _previewsText;
    }
    addListener(_listener);
  }

  void _listener() {
    if (_previewsText == text) {
      _setSelectionBy(offset: text.length);
      return;
    }

    final clearText = _clear(text: text);

    if (clearText.isEmpty) {
      _previewsText = '';
      text = '';
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

    if ((double.tryParse(clearText) ?? 0.0) == 0.0) {
      _previewsText = '';
      text = '';
      return;
    }

    final String maskedValue =
        '$_leftSymbol${_formatToNumber(string: clearText)}';

    _previewsText = maskedValue;
    _value = _getDoubleValueFor(string: clearText);
    text = maskedValue;

    _setSelectionBy(offset: text.length);
  }

  String _clear({required String text}) {
    _value = 0;
    return text
        .replaceAll(_leftSymbol, '')
        .replaceAll(_thousandSymbol, '')
        .replaceAll(_decimalSymbol, '')
        .trim();
  }

  void _setSelectionBy({required int offset}) {
    selection = TextSelection.fromPosition(TextPosition(offset: offset));
  }

  bool _isOnlyNumbers({String? string}) {
    if (string == null || string.isEmpty) return false;

    final clearText = _getOnlyNumbers(string: string);

    return clearText != null ? (clearText.length == string.length) : false;
  }

  String? _getOnlyNumbers({String? string}) =>
      string?.replaceAll(_onlyNumbersRegex, '');

  String _formatToNumber({required String string}) {
    final double value = _getDoubleValueFor(string: string);

    return _applyMaskTo(value: value);
  }

  double _getDoubleValueFor({required String string}) {
    return (double.tryParse(string) ?? 0.0) / pow(10, _numberOfDecimals);
  }

  String _applyMaskTo({required double value}) {
    final List<String> textRepresentation = value
        .toStringAsFixed(_numberOfDecimals)
        .replaceAll('.', '')
        .split('')
        .reversed
        .toList(growable: true);

    textRepresentation.insert(_numberOfDecimals, _decimalSymbol);

    int thousandPositionSymbol = _numberOfDecimals + 4;
    while (textRepresentation.length > thousandPositionSymbol) {
      textRepresentation.insert(thousandPositionSymbol, _thousandSymbol);
      thousandPositionSymbol += 4;
    }

    return textRepresentation.reversed.join();
  }

  @override
  void dispose() {
    removeListener(_listener);
    super.dispose();
  }
}
