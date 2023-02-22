library currency_textfield;

import 'package:currency_textfield/extensions.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// A custom TextEditingController for currency input.
///
/// `currencySymbol` is your currency symbol.
///
/// Default `R\$`
///
/// `decimalSymbol` is the decimal separator symbol.
///
/// Default `,`
///
/// `thousandSymbol` is the thousand separator symbol.
///
/// @Default `.`
///
/// `initDoubleValue` is the optional initial value in double format.
///
/// Default `null`
///
/// `initIntValue` is the optional initial value in int format. It'll be divided by 100 before being presented.
///
/// Default `null`
///
/// `numberOfDecimals` lets you define the max number of decimal digits to be presented.
///
/// Default `2`
///
/// `maxDigits` lets you define the max number of digits to be presented.
///
/// Default `15`
///
/// `currencyOnLeft` lets you define if the symbol will be on left or right of the number.
///
/// Default `true`
///
class CurrencyTextFieldController extends TextEditingController {
  final int _maxDigits;
  final int _numberOfDecimals;
  final String _currencySymbol;
  final String _decimalSymbol;
  final String _thousandSymbol;
  final bool _currencyOnLeft;
  String _previewsText = '';
  double _value = 0.0;

  final _onlyNumbersRegex = RegExp(r'[^\d]');
  //bool _isNegative = false;

  double get doubleValue => _value.toPrecision(_numberOfDecimals);
  String get currencySymbol => _currencySymbol;
  String get decimalSymbol => _decimalSymbol;
  String get thousandSymbol => _thousandSymbol;
  int get intValue => int.tryParse(_getOnlyNumbers(string: text) ?? '') ?? 0;

  CurrencyTextFieldController({
    String currencySymbol = 'R\$',
    String decimalSymbol = ',',
    String thousandSymbol = '.',
    double? initDoubleValue,
    int? initIntValue,
    int maxDigits = 15,
    int numberOfDecimals = 2,
    bool currencyOnLeft = true,
    //bool enableNegative = true,
  })  : assert(
          !(initDoubleValue != null && initIntValue != null),
          "You must set either 'initDoubleValue' or 'initIntValue' parameter",
        ),
        _currencySymbol = currencySymbol,
        _decimalSymbol = decimalSymbol,
        _thousandSymbol = thousandSymbol,
        _maxDigits = maxDigits,
        _numberOfDecimals = numberOfDecimals,
        _currencyOnLeft = currencyOnLeft {
    if (initDoubleValue != null) {
      _value = initDoubleValue;
      _previewsText = _composeCurrency(_applyMaskTo(value: _value));
      text = _previewsText;
      _setSelectionBy(offset: text.length);
    } else if (initIntValue != null) {
      _value = initIntValue / 100;
      _previewsText = _composeCurrency(_applyMaskTo(value: _value));
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
      _value = 0;
      _previewsText = '';
      text = '';
      return;
    }

    if (clearText.length > _maxDigits || !_isOnlyNumbers(string: clearText)) {
      text = _previewsText;
      return;
    }

    if ((double.tryParse(clearText) ?? 0.0) == 0.0) {
      _value = 0;
      _previewsText = '';
      text = '';
      return;
    }

    _value = _getDoubleValueFor(string: clearText);

    final String maskedValue = _composeCurrency(_applyMaskTo(value: _value));

    _previewsText = maskedValue;

    text = maskedValue;

    _setSelectionBy(offset: text.length);
  }

  String _clear({required String text}) {
    return text
        .replaceAll(_currencySymbol, '')
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

  double _getDoubleValueFor({required String string}) {
    return (double.tryParse(string) ?? 0.0) / pow(10, _numberOfDecimals);
  }

  String _composeCurrency(String value) {
    return _currencyOnLeft
        ? '$_currencySymbol $value'
        : '$value $_currencySymbol';
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
