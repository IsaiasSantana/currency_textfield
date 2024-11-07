library currency_textfield;

import '/extensions.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// A custom TextEditingController for currency input.
///
/// `currencySymbol` is your currency symbol.
///
/// Default: `R\$`
///
/// `decimalSymbol` is the decimal separator symbol.
///
/// Default: `,`
///
/// `thousandSymbol` is the thousand separator symbol.
///
/// @Default: `.`
///
/// `initDoubleValue` is the optional initial value in double format.
///
/// Default: `null`
///
/// `initIntValue` is the optional initial value in int format. It'll be divided by 100 before being presented.
///
/// Default: `null`
///
/// `numberOfDecimals` lets you define the max number of decimal digits to be presented.
///
/// Default: `2`
///
/// `maxDigits` lets you define the max number of digits to be presented.
///
/// Default: `15`
///
/// `currencyOnLeft` lets you define if the symbol will be on left or right of the value.
///
/// Default: `true`
///
/// `enableNegative` lets you define if the user can set negative values.
///
/// Default: `true`
///
/// `currencySeparator` lets you define the separator between the symbol and the value.
///
/// Default: `' '`
///
/// `maxValue` lets you define the maximum allowed value of the controller.
///
/// Default: `null`
///
/// `minValue` lets you define the minimum allowed value of the controller.
///
/// Default: `null`
///
/// `startWithSeparator` lets you define if the controller starts with decimals activated.
///
/// Default: `true`
///
/// `showZeroValue` lets you define if the controller will show the 0 value.
///
/// Default: `false`
///
/// `forceCursorToEnd` lets you define if the controller will always force the user to input the numbers on the end of the string.
///
/// Default: `true`
///
/// `removeSymbol` lets you define that controller will only show the formatted number.
///
/// Default: `false`
///
class CurrencyTextFieldController extends TextEditingController {
  final int _maxDigits, _numberOfDecimals;
  final String _decimalSymbol, _thousandSymbol, _currencySeparator;
  final bool _currencyOnLeft,
      _enableNegative,
      _resetSeparator,
      _showZeroValue,
      _forceCursorToEnd,
      _removeSymbol;
  final RegExp _onlyNumbersRegex = RegExp(r'[^\d]');
  late String _currencySymbol, _symbolSeparator;

  String _previewsText = '';
  double _value = 0.0;
  double? _maxValue;
  double? _minValue;
  bool _isNegative = false;
  late bool _startWithSeparator;

  ///return the number part of the controller as a double.
  double get doubleValue => _value.toPrecision(_numberOfDecimals);

  ///return the currency Symbol of the controller.
  String get currencySymbol => _currencySymbol;

  ///return the decimal Symbol of the controller.
  String get decimalSymbol => _decimalSymbol;

  ///return the thousand Symbol of the controller.
  String get thousandSymbol => _thousandSymbol;

  ///return the number part of the controller as a int. Ex: `1000` for a controller with `R$ 10,00` text.
  int get intValue =>
      (_isNegative ? -1 : 1) *
      (int.tryParse(_getOnlyNumbers(string: text) ?? '') ?? 0);

  ///return the number part of the controller as a String.
  String get textWithoutCurrencySymbol =>
      text.replaceFirst(_symbolSeparator, '');

  ///return the number part of the controller as a String, formatted as a double (with `.` as decimal separator).
  String get doubleTextWithoutCurrencySymbol => text != ''
      ? text
          .replaceFirst(_symbolSeparator, '')
          .replaceAll(thousandSymbol, '')
          .replaceFirst(decimalSymbol, '.')
      : '0';

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
    double? minValue,
    bool startWithSeparator = true,
    bool showZeroValue = false,
    bool forceCursorToEnd = true,
    bool removeSymbol = false,
  })  : assert(thousandSymbol != decimalSymbol,
            "thousandSymbol must be different from decimalSymbol."),
        assert(numberOfDecimals >= 0,
            "numberOfDecimals must greater than or equal to 0."),
        _currencySymbol = currencySymbol,
        _decimalSymbol = decimalSymbol,
        _thousandSymbol = thousandSymbol,
        _currencySeparator = currencySeparator,
        _maxDigits = maxDigits,
        _numberOfDecimals = numberOfDecimals,
        _currencyOnLeft = currencyOnLeft,
        _enableNegative = enableNegative,
        _maxValue = maxValue,
        _minValue = minValue,
        _startWithSeparator = startWithSeparator,
        _resetSeparator = !startWithSeparator,
        _showZeroValue = showZeroValue,
        _forceCursorToEnd = forceCursorToEnd,
        _removeSymbol = removeSymbol {
    _changeSymbolSeparator();
    forceValue(
        initDoubleValue: initDoubleValue,
        initIntValue: initIntValue,
        init: true);
    addListener(_listener);
  }

  void _listener() {
    if (_previewsText == text) {
      if (_forceCursorToEnd) {
        _setSelectionBy(offset: text.length);
      }
      return;
    }

    if (text.isEmpty) {
      _zeroValue(clean: _checkCleanZeroText(text));
      return;
    }

    checkNegative();

    if (text == '-') {
      _previewsText = '-';
      return;
    }

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

    if ((double.tryParse(clearText) ?? 0.0) == 0.0) {
      _zeroValue(
          forceNegative: text.endsWith('-'), clean: _checkCleanZeroText(text));
      return;
    }

    if (clearText.length > _maxDigits) {
      text = _previewsText;
      return;
    }

    if (!_startWithSeparator) {
      if (text.endsWith(_decimalSymbol)) {
        _startWithSeparator = true;
        clearText = clearText + '0' * _numberOfDecimals;
      }
    }

    _value = _getDoubleValueFor(string: clearText);

    _checkMinValue();
    _checkMaxValue();

    _changeText();
  }

  ///Force a value to the text controller. If initDoubleValue and initIntValue are both null, 0 will be forced.
  void forceValue(
      {double? initDoubleValue, int? initIntValue, bool init = false}) {
    if (initDoubleValue != null) {
      _value = initDoubleValue;
      _updateValue();
    } else if (initIntValue != null) {
      _value = initIntValue / pow(10, _numberOfDecimals);
      _updateValue();
    } else {
      if (!init) {
        _value = 0;
        _updateValue();
      }
    }
  }

  ///Replace the current currency symbol by the defined value. If `resetValue = true` the controller will be reseted to 0.
  void replaceCurrencySymbol(String newSymbol, {bool resetValue = false}) {
    _currencySymbol = newSymbol;
    _changeSymbolSeparator();

    if (resetValue) {
      _value = 0;
    }

    _changeText();
  }

  void _updateValue() {
    _checkMinValue();

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

    _changeText();
  }

  ///function to check if the value is greater than maxValue.
  void _checkMaxValue() {
    if (_maxValue != null) {
      if (_value > _maxValue!) {
        _value = _maxValue!;
      }
    }
  }

  ///function to check if the value is lower than minValue.
  void _checkMinValue() {
    if (_minValue != null) {
      if (_value < _minValue!) {
        _value = _minValue!;
      }
    }
  }

  ///function to replace current maxValue.
  void replaceMaxValue(double newMaxvalue, {bool resetValue = false}) {
    _maxValue = newMaxvalue;

    if (resetValue) {
      _value = 0;
    } else {
      _checkMaxValue();
    }

    _changeText();
  }

  ///function to replace current minValue.
  void replaceMinValue(double newMinvalue, {bool resetValue = false}) {
    _minValue = newMinvalue;

    if (resetValue) {
      _value = 0;
    } else {
      _checkMinValue();
    }

    _changeText();
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

  void _changeText() {
    if (_value == 0 && !_showZeroValue) {
      _previewsText = '';
    } else {
      _previewsText = _composeCurrency(_applyMaskTo(value: _value));
    }
    text = _previewsText;
    _setSelectionBy(offset: text.length);
  }

  void _changeSymbolSeparator() {
    if (!_removeSymbol) {
      _symbolSeparator = _currencyOnLeft
          ? (_currencySymbol + _currencySeparator)
          : (_currencySeparator + _currencySymbol);
    } else {
      _symbolSeparator = '';
    }
  }

  void _setSelectionBy({required int offset}) {
    selection = TextSelection.fromPosition(TextPosition(offset: offset));
  }

  ///resets the controller to 0.
  void _zeroValue({bool forceNegative = false, bool clean = false}) {
    if (clean) {
      _previewsText = '';
      text = _previewsText;
      return;
    }
    _value = 0;
    _isNegative = forceNegative;

    if (_showZeroValue) {
      _changeText();
    } else {
      _previewsText = '';
    }

    if (_resetSeparator && _startWithSeparator) {
      _startWithSeparator = false;
    }
  }

  bool _checkCleanZeroText(String currentText) {
    return _value == 0 &&
        _showZeroValue &&
        currentText.length < _previewsText.length;
  }

  String? _getOnlyNumbers({String? string}) =>
      string?.replaceAll(_onlyNumbersRegex, '');

  double _getDoubleValueFor({required String string}) {
    return (_isNegative ? -1 : 1) *
        (double.tryParse(string) ?? 0.0) /
        (_startWithSeparator ? pow(10, _numberOfDecimals) : 1);
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
    final decimals = _startWithSeparator ? _numberOfDecimals : 0;
    final List<String> textRepresentation = value
        .abs()
        .toStringAsFixed(decimals)
        .replaceAll('.', '')
        .split('')
        .reversed
        .toList(growable: true);

    int thousandPositionSymbol = decimals + 4;

    if (decimals > 0) {
      textRepresentation.insert(decimals, _decimalSymbol);
    } else {
      thousandPositionSymbol -= 1;
    }

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
