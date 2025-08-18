library currency_textfield;

import 'package:flutter/widgets.dart';
import 'extensions.dart';

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

  //única RegExp para todas as instâncias
  static final RegExp _onlyNumbersRegex = RegExp(r'[^\d]');
  late String _currencySymbol, _symbolSeparator;

  //Cache da escala sem alocações temporárias
  late final int _scaleInt = (() {
    var s = 1;
    for (var i = 0; i < _numberOfDecimals; i++) {
      s *= 10;
    }
    return s;
  })();
  late final double _scale = _scaleInt.toDouble();

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
    // não muda o texto quando não há valor inicial (mantém compatibilidade com seus testes)
    forceValue(
      initDoubleValue: initDoubleValue,
      initIntValue: initIntValue,
      init: true,
    );
    addListener(_listener);
  }

  void _listener() {
    final String t = text;

    if (_previewsText == t) {
      if (_forceCursorToEnd) {
        selection = TextSelection.fromPosition(TextPosition(offset: t.length));
      }
      return;
    }

    if (t.isEmpty) {
      _zeroValue(clean: _checkCleanZeroText(t));
      return;
    }

    // negativo só se permitido e quando começa com '-'
    _isNegative = _enableNegative && t.startsWith('-');

    if (t == '-') {
      _previewsText = '-';
      return;
    }

    // Limpa números uma vez (trim é redundante: não restam espaços após regex)
    String clearText;
    if (_currencyOnLeft) {
      clearText = _getOnlyNumbers(string: t) ?? '';
    } else {
      if (t.lastChars(1).isNumeric()) {
        clearText = _getOnlyNumbers(string: t) ?? '';
      } else {
        clearText = (_getOnlyNumbers(string: t) ?? '').allBeforeLastN(1);
      }
    }

    // Checagem de "zero" sem parse (vazio ou apenas zeros)
    if (_isAllZeros(clearText)) {
      _zeroValue(forceNegative: t.endsWith('-'), clean: _checkCleanZeroText(t));
      return;
    }

    if (clearText.length > _maxDigits) {
      text = _previewsText;
      return;
    }

    if (!_startWithSeparator && t.endsWith(_decimalSymbol)) {
      _startWithSeparator = true;
      clearText = clearText + '0' * _numberOfDecimals;
    }

    _value = _getDoubleValueFor(string: clearText);

    _clampValue();

    _changeText();
  }

  ///Force a value to the text controller. If initDoubleValue and initIntValue are both null, 0 will be forced.
  void forceValue(
      {double? initDoubleValue, int? initIntValue, bool init = false}) {
    if (initDoubleValue != null) {
      _value = initDoubleValue;
    } else if (initIntValue != null) {
      _value = initIntValue / _scale;
    } else {
      if (!init) {
        _value = 0;
      }
    }
    // Só atualiza o texto quando houver valor inicial OU não estivermos no init do construtor
    if (initDoubleValue != null || initIntValue != null || !init) {
      _normalizeNegative();
      _clampValue();
      _changeText();
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

  void _normalizeNegative() {
    if (_value < 0) {
      if (!_enableNegative) {
        _value = -_value;
        _isNegative = false;
      } else {
        _isNegative = true;
      }
    } else {
      _isNegative = false;
    }
  }

  void _clampValue() {
    if (_minValue != null && _value < _minValue!) _value = _minValue!;
    if (_maxValue != null && _value > _maxValue!) _value = _maxValue!;
  }

  ///function to replace current maxValue.
  void replaceMaxValue(double newMaxvalue, {bool resetValue = false}) {
    _maxValue = newMaxvalue;

    if (resetValue) {
      _value = 0;
    } else {
      _clampValue();
    }

    _changeText();
  }

  ///function to replace current minValue.
  void replaceMinValue(double newMinvalue, {bool resetValue = false}) {
    _minValue = newMinvalue;

    if (resetValue) {
      _value = 0;
    } else {
      _clampValue();
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
      final masked = _applyMaskTo(value: _value);
      final sign = _isNegative ? '-' : '';
      _previewsText = _currencyOnLeft
          ? '$sign$_symbolSeparator$masked'
          : '$sign$masked$_symbolSeparator';
    }
    if (text != _previewsText) {
      text = _previewsText;
      selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    }
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

  ///resets the controller to 0.
  void _zeroValue({bool forceNegative = false, bool clean = false}) {
    if (clean) {
      _previewsText = '';
      text = _previewsText;
      return;
    }
    _value = 0;
    _isNegative = forceNegative;

    if (_resetSeparator && _startWithSeparator) {
      _startWithSeparator = false;
    }
    _changeText();
  }

  bool _checkCleanZeroText(String currentText) {
    return _value == 0 &&
        _showZeroValue &&
        currentText.length < _previewsText.length;
  }

  // mantém assinatura original (String? -> String?)
  String? _getOnlyNumbers({String? string}) =>
      string?.replaceAll(_onlyNumbersRegex, '');

  double _getDoubleValueFor({required String string}) {
    final double raw = double.tryParse(string) ?? 0.0;
    final double denom = _startWithSeparator ? _scale : 1.0;
    return (_isNegative ? -raw : raw) / denom;
  }

  // verificação leve de "apenas zeros" (inclui string vazia)
  bool _isAllZeros(String s) {
    if (s.isEmpty) return true;
    for (var i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) != 48) return false; // '0'
    }
    return true;
  }

  String _applyMaskTo({required double value}) {
    final int decimals = _startWithSeparator ? _numberOfDecimals : 0;
    final double absVal = value.abs();
    final int total = (absVal * (decimals == 0 ? 1 : _scale)).round();

    int intPart, fracPart;
    if (decimals == 0) {
      intPart = total;
      fracPart = 0;
    } else {
      intPart = total ~/ _scaleInt;
      fracPart = total % _scaleInt;
    }

    // parte inteira com milhares (mesmo agrupamento do original)
    final String intStr = intPart.toString();
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) sb.write(_thousandSymbol);
      sb.write(intStr[i]);
    }

    if (decimals > 0) {
      final fracStr = fracPart.toString().padLeft(decimals, '0');
      sb.write(_decimalSymbol);
      sb.write(fracStr);
    }

    return sb.toString();
  }

  @override
  void dispose() {
    removeListener(_listener);
    super.dispose();
  }
}
