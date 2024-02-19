library currency_textfield;

import '/extensions.dart';
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
/// `currencyOnLeft` lets you define if the symbol will be on left or right of the value.
///
/// Default `true`
///
/// `enableNegative` lets you define if the user can set negative values.
///
/// Default `true`
///
/// `currencySeparator` lets you define the separator between the symbol and the value.
///
/// Default `' '`
///
/// `maxValue` lets you define the maximum allowed value of the controller.
///
/// Default `null`
///
class CurrencyTextFieldController extends TextEditingController {
  final int _maxDigits, _numberOfDecimals;
  final String _currencySymbol,
      _decimalSymbol,
      _thousandSymbol,
      _currencySeparator;
  final bool _currencyOnLeft, _enableNegative;
  final RegExp _onlyNumbersRegex = RegExp(r'[^\d]');
  late final String _symbolSeparator;
  final double? _maxValue;

  String _previewsText = '';
  double _value = 0.0;
  bool _isNegative = false;

  double get doubleValue => _value.toPrecision(_numberOfDecimals);
  String get currencySymbol => _currencySymbol;
  String get decimalSymbol => _decimalSymbol;
  String get thousandSymbol => _thousandSymbol;
  int get intValue =>
      (_isNegative ? -1 : 1) *
      (int.tryParse(_getOnlyNumbers(string: text) ?? '') ?? 0);
  String get textWithoutCurrencySymbol =>
      text.replaceFirst(_symbolSeparator, '');

  CurrencyTextFieldController({
    String currencySymbol = 'R\$',
    String decimalSymbol = ',',
    String thousandSymbol = '.',
    String currencySeparator = ' ',
    double? initDoubleValue,
    int? initIntValue,
    int maxDigits = 15,
    int numberOfDecimals = 2,
    bool currencyOnLeft = true,
    bool enableNegative = true,
    double? maxValue,
  })  : _currencySymbol = currencySymbol,
        _decimalSymbol = decimalSymbol,
        _thousandSymbol = thousandSymbol,
        _currencySeparator = currencySeparator,
        _maxDigits = maxDigits,
        _numberOfDecimals = numberOfDecimals,
        _currencyOnLeft = currencyOnLeft,
        _enableNegative = enableNegative,
        _maxValue = maxValue {
    _symbolSeparator = currencyOnLeft
        ? (_currencySymbol + _currencySeparator)
        : (_currencySeparator + _currencySymbol);
    forceValue(initDoubleValue: initDoubleValue, initIntValue: initIntValue);
    addListener(_listener);
  }

  void _listener() {
    if (_previewsText == text) {
      _setSelectionBy(offset: text.length);
      return;
    }

    checkNegative();

    late String clearText;

    if (_currencyOnLeft) {
      clearText = (_getOnlyNumbers(string: text) ?? '').trim();
    } else {
      if (text.lastChars(1).isNumeric()) {
        clearText = (_getOnlyNumbers(string: text) ?? '').trim();
      } else {
        clearText =
            (_getOnlyNumbers(string: text) ?? '').trim().allBeforeLastN(1);
      }
    }

    if (clearText.isEmpty) {
      _zeroValue();
      return;
    }

    if (clearText.length > _maxDigits) {
      text = _previewsText;
      return;
    }

    if ((double.tryParse(clearText) ?? 0.0) == 0.0) {
      _zeroValue();
      return;
    }

    _value = _getDoubleValueFor(string: clearText);

    _checkMaxValue();

    final String maskedValue = _composeCurrency(_applyMaskTo(value: _value));

    _previewsText = maskedValue;

    text = maskedValue;

    _setSelectionBy(offset: text.length);
  }

  ///Force a value to the text controller.
  void forceValue({double? initDoubleValue, int? initIntValue}) {
    assert(!(initDoubleValue != null && initIntValue != null),
        "You must set either 'initDoubleValue' or 'initIntValue' parameter.");
    if (initDoubleValue != null) {
      _value = initDoubleValue;
      _updateValue();
    } else if (initIntValue != null) {
      _value = initIntValue / pow(10, _numberOfDecimals);
      _updateValue();
    }
  }

  void _updateValue() {
    if (_value < 0) {
      if (!_enableNegative) {
        _value = _value * -1;
      } else {
        _isNegative = true;
      }
    } else {
      _isNegative = false;
    }
    _checkMaxValue();
    _previewsText = _composeCurrency(_applyMaskTo(value: _value));
    text = _previewsText;
    _setSelectionBy(offset: text.length);
  }

  ///function to check if the value is greater than maxValue.
  void _checkMaxValue() {
    if (_maxValue != null) {
      if (_value > _maxValue!) {
        _value = _maxValue!;
      }
    }
  }

  ///check if the value is negative.
  bool checkNegative() {
    if (_enableNegative) {
      _isNegative = text.startsWith('-');
    } else {
      _isNegative = false;
    }
    return _isNegative;
  }

  void _setSelectionBy({required int offset}) {
    selection = TextSelection.fromPosition(TextPosition(offset: offset));
  }

  ///force the sign when `_value = 0`
  void _zeroValue() {
    _value = 0;
    _previewsText = _negativeSign();
    text = _previewsText;
  }

  String? _getOnlyNumbers({String? string}) =>
      string?.replaceAll(_onlyNumbersRegex, '');

  double _getDoubleValueFor({required String string}) {
    return (_isNegative ? -1 : 1) *
        (double.tryParse(string) ?? 0.0) /
        pow(10, _numberOfDecimals);
  }

  String _composeCurrency(String value) {
    return _currencyOnLeft
        ? '${_negativeSign()}$_symbolSeparator$value'
        : '${_negativeSign()}$value$_symbolSeparator';
  }

  String _negativeSign() {
    return (_isNegative ? '-' : '');
  }

  String _applyMaskTo({required double value}) {
    final List<String> textRepresentation = value
        .toStringAsFixed(_numberOfDecimals)
        .replaceAll('.', '')
        .replaceAll('-', '')
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
