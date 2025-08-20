import 'package:flutter/widgets.dart';
import 'extensions.dart';

/// A specialized [TextEditingController] to handle currency/number input with
/// live formatting (thousands/decimal separators, currency symbol placement),
/// value clamping (min/max), negative handling, and convenience getters.
///
/// ### Key features
/// - Thousands/decimal separators with custom symbols.
/// - Currency symbol on the left or right (or hidden, while still kept internally).
/// - Optional negative values.
/// - Start without decimal separator (integer mode) until user types it.
/// - Min/Max clamping.
/// - Optional Indian digit grouping (3-2-2 pattern: lakhs/crores).
/// - Optional accounting negative format (parentheses).
/// - Optional numeric abbreviations on input: `1k`, `2.5m`, `3b`.
///
/// The public API keeps values consistent with formatting:
/// - [doubleValue]: numeric value with desired decimal precision.
/// - [intValue]: raw integer representation of the masked digits (with sign).
/// - [textWithoutCurrencySymbol]: formatted string without the currency symbol.
/// - [doubleTextWithoutCurrencySymbol]: normalized numeric string using `.` as decimal.
class CurrencyTextFieldController extends TextEditingController {
  /// Maximum number of raw digits allowed (ignoring separators/symbols).
  final int _maxDigits;

  /// Number of decimal digits to format/display (>= 0).
  final int _numberOfDecimals;

  /// Symbol used for the decimal separator in the formatted string (e.g. "," or ".").
  final String _decimalSymbol;

  /// Symbol used for the thousands separator in the formatted string (e.g. "." or ",").
  final String _thousandSymbol;

  /// Separator placed between the currency symbol and the number (e.g. " ", "->", "").
  final String _currencySeparator;

  /// If `true`, the currency symbol is placed before the number (left side).
  /// If `false`, the currency symbol is placed after the number (right side).
  final bool _currencyOnLeft;

  /// If `true`, negative values are allowed. If `false`, negatives are coerced to positive.
  final bool _enableNegative;

  /// If `true`, when value is reset to zero, we also reset the “startWithSeparator” mode.
  final bool _resetSeparator;

  /// If `true`, show "0" formatted (e.g., "R$ 0,00") when the numeric value is zero.
  /// If `false`, show an empty string when value is zero.
  final bool _showZeroValue;

  /// If `true`, forces the text cursor (caret) to the end after each reformat.
  final bool _forceCursorToEnd;

  /// If `true`, the currency symbol is not rendered in [text], but it is preserved internally.
  final bool _removeSymbol;

  // --- New optional features (all default to disabled / no behavior change) ---

  /// If `true`, use Indian digit grouping for the integer part (3-2-2-… pattern).
  final bool _indianGrouping;

  /// If `true`, show negative values using accounting style:
  /// parentheses around the formatted string instead of a leading minus.
  /// (Value stays negative internally.)
  final bool _negativeParentheses;

  /// If `true`, interpret numeric abbreviations on input such as:
  /// `1k` → 1000, `2.5m` → 2,500,000, `3b` → 3,000,000,000.
  final bool _enableAbbreviations;

  /// Map of abbreviation suffixes to multipliers. Keys are case-insensitive
  /// and normalized to lowercase (e.g. {"k":1e3, "m":1e6, "b":1e9}).
  final Map<String, double> _abbreviations;

  /// Single shared RegExp to strip everything but digits.
  static final RegExp _onlyNumbersRegex = RegExp(r'[^\d]');

  late String _currencySymbol, _symbolSeparator;

  // Scale cache to avoid pow(10, n) repeatedly.
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

  /// Returns the numeric part as [double], rounded to [_numberOfDecimals].
  double get doubleValue => _value.toPrecision(_numberOfDecimals);

  /// Returns the current currency symbol.
  String get currencySymbol => _currencySymbol;

  /// Returns the current decimal separator symbol.
  String get decimalSymbol => _decimalSymbol;

  /// Returns the current thousands separator symbol.
  String get thousandSymbol => _thousandSymbol;

  /// Returns the numeric part as [int] (signed).
  /// Example: for "R$ 10,00" and 2 decimals, returns 1000 (or -1000 if negative).
  int get intValue =>
      (_isNegative ? -1 : 1) *
      (int.tryParse(_getOnlyNumbers(string: text) ?? '') ?? 0);

  /// Returns the formatted text without the currency symbol (keeps separators).
  String get textWithoutCurrencySymbol =>
      text.replaceFirst(_symbolSeparator, '');

  /// Returns the formatted number as a string normalized to a "double-like" format:
  /// - removes thousands separators
  /// - uses "." as decimal separator
  /// - returns "0" if empty
  String get doubleTextWithoutCurrencySymbol => text != ''
      ? text
          .replaceFirst(_symbolSeparator, '')
          .replaceAll(thousandSymbol, '')
          .replaceFirst(decimalSymbol, '.')
      : '0';

  /// Creates a currency-aware [TextEditingController].
  ///
  /// #### Common formatting
  /// - [currencySymbol]: currency symbol to display (default `'R$'`).
  /// - [decimalSymbol]: decimal separator (default `','`).
  /// - [thousandSymbol]: thousands separator (default `'.'`).
  /// - [currencySeparator]: string between currency symbol and number (default `' '`).
  /// - [numberOfDecimals]: how many decimal digits to display (default `2`, can be `0`).
  /// - [currencyOnLeft]: place currency symbol on the left (`true`) or right (`false`).
  /// - [removeSymbol]: if `true`, hide the currency symbol in [text] (kept internally).
  ///
  /// #### Value handling
  /// - [initDoubleValue]: initial numeric value as double (optional).
  /// - [initIntValue]: initial raw integer value in "cents-like" units (optional).
  ///   For example, with `numberOfDecimals = 2`, `initIntValue: 195` → `1,95`.
  /// - [maxDigits]: maximum number of raw digits allowed (default `15`).
  /// - [enableNegative]: if `false`, negative values are coerced to positive.
  /// - [minValue]/[maxValue]: clamp range for the numeric value (optional).
  ///
  /// #### Editing behavior
  /// - [startWithSeparator]: if `false`, start in integer mode (no decimals)
  ///   until user types the decimal separator; if `true` (default), always show decimals.
  /// - [showZeroValue]: if `true`, show the formatted zero; if `false`, show empty text for zero.
  /// - [forceCursorToEnd]: if `true`, keep caret at the end after reformatting.
  ///
  /// #### Optional extra features (opt-in)
  /// - [indianGrouping]: if `true`, use Indian digit grouping (3-2-2-…).
  /// - [negativeParentheses]: if `true`, display negatives with parentheses instead of a minus.
  /// - [enableAbbreviations]: if `true`, accept input like `1k`, `2.5m`, `3b`.
  /// - [abbreviations]: custom abbreviation map; defaults to `{'k':1e3,'m':1e6,'b':1e9}`.
  CurrencyTextFieldController({
    // Common formatting
    String currencySymbol = 'R\$',
    String decimalSymbol = ',',
    String thousandSymbol = '.',
    String currencySeparator = ' ',

    // Initial values
    double? initDoubleValue,
    int? initIntValue,

    // Limits / formatting rules
    int maxDigits = 15,
    int numberOfDecimals = 2,
    bool currencyOnLeft = true,
    bool enableNegative = true,
    double? maxValue,
    double? minValue,

    // Editing behavior
    bool startWithSeparator = true,
    bool showZeroValue = false,
    bool forceCursorToEnd = true,
    bool removeSymbol = false,

    // Extra features (opt-in)
    bool indianGrouping = false,
    bool negativeParentheses = false,
    bool enableAbbreviations = false,
    Map<String, double>? abbreviations,
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
        _removeSymbol = removeSymbol,
        _indianGrouping = indianGrouping,
        _negativeParentheses = negativeParentheses,
        _enableAbbreviations = enableAbbreviations,
        _abbreviations = (abbreviations ??
                const {'k': 1e3, 'm': 1e6, 'b': 1e9})
            .map((k, v) => MapEntry(k.toLowerCase(), v.toDouble())) {
    _changeSymbolSeparator();
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

    // Negative only if allowed and starting with '-'
    _isNegative = _enableNegative && t.startsWith('-');

    if (t == '-') {
      _previewsText = '-';
      return;
    }

    // Abbreviations (e.g., "2.5m", "3B") if enabled
    if (_enableAbbreviations) {
      final match = _matchAbbreviation(t);
      if (match != null) {
        final base = match.$1;
        final mult = match.$2;
        _value = base * mult;
        _normalizeNegative();
        if (!_startWithSeparator && _numberOfDecimals > 0) {
          _startWithSeparator = true;
        }
        _clampValue();
        _changeText();
        return;
      }
    }

    // Sanitize once (trim is unnecessary since regex strips spaces/symbols)
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

    // Quick zero check (empty or only zeros)
    if (_isAllZeros(clearText)) {
      _zeroValue(forceNegative: t.endsWith('-'), clean: _checkCleanZeroText(t));
      return;
    }

    // Enforce max raw digits
    if (clearText.length > _maxDigits) {
      text = _previewsText;
      return;
    }

    // Switch from integer-mode to decimal-mode when user types the separator
    if (!_startWithSeparator && t.endsWith(_decimalSymbol)) {
      _startWithSeparator = true;
      clearText = clearText + '0' * _numberOfDecimals;
    }

    _value = _getDoubleValueFor(string: clearText);

    _clampValue();

    _changeText();
  }

  /// Force a value into the controller.
  ///
  /// If both [initDoubleValue] and [initIntValue] are `null`, 0 will be forced
  /// only when [init] is `false`. When [init] is `true` (constructor), we do not
  /// update the text if there's no initial value (keeps compatibility with tests).
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
    if (initDoubleValue != null || initIntValue != null || !init) {
      _normalizeNegative();
      _clampValue();
      _changeText();
    }
  }

  /// Replace the current currency symbol with [newSymbol].
  /// If [resetValue] is `true`, the controller value is reset to 0.
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

  /// Replace the current [_maxValue]. If [resetValue] is `true`, reset to 0.
  void replaceMaxValue(double newMaxvalue, {bool resetValue = false}) {
    _maxValue = newMaxvalue;

    if (resetValue) {
      _value = 0;
    } else {
      _clampValue();
    }

    _changeText();
  }

  /// Replace the current [_minValue]. If [resetValue] is `true`, reset to 0.
  void replaceMinValue(double newMinvalue, {bool resetValue = false}) {
    _minValue = newMinvalue;

    if (resetValue) {
      _value = 0;
    } else {
      _clampValue();
    }

    _changeText();
  }

  /// Returns whether the current text indicates a negative input.
  /// Also updates internal negative flag accordingly.
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
      if (_isNegative && _negativeParentheses) {
        final core = _currencyOnLeft
            ? '$_symbolSeparator$masked'
            : '$masked$_symbolSeparator';
        _previewsText = '($core)';
      } else {
        final sign = _isNegative ? '-' : '';
        _previewsText = _currencyOnLeft
            ? '$sign$_symbolSeparator$masked'
            : '$sign$masked$_symbolSeparator';
      }
    }
    if (text != _previewsText) {
      text = _previewsText;
      final pos = TextPosition(offset: text.length);
      selection = TextSelection.fromPosition(pos);
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

  /// Reset controller to 0. If [clean] is `true`, also clear the text.
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

  /// Returns whether the controller should clear when current text shrinks
  /// and [_showZeroValue] is on while numeric value is 0.
  bool _checkCleanZeroText(String currentText) {
    return _value == 0 &&
        _showZeroValue &&
        currentText.length < _previewsText.length;
  }

  // Keep original signature (String? -> String?).
  String? _getOnlyNumbers({String? string}) =>
      string?.replaceAll(_onlyNumbersRegex, '');

  double _getDoubleValueFor({required String string}) {
    final double raw = double.tryParse(string) ?? 0.0;
    final double denom = _startWithSeparator ? _scale : 1.0;
    return (_isNegative ? -raw : raw) / denom;
  }

  // Lightweight check for "only zeros" (also true for empty string).
  bool _isAllZeros(String s) {
    if (s.isEmpty) return true;
    for (var i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) != 48) return false; // '0'
    }
    return true;
  }

  // Western grouping: 3-3-3
  String _formatIntWestern(String intStr) {
    final len = intStr.length;
    if (len <= 3) return intStr;
    final sb = StringBuffer();
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) sb.write(_thousandSymbol);
      sb.write(intStr[i]);
    }
    return sb.toString();
  }

  // Indian grouping: 3-2-2-…
  String _formatIntIndian(String intStr) {
    final len = intStr.length;
    if (len <= 3) return intStr;
    final prefix = intStr.substring(0, len - 3);
    final suffix = intStr.substring(len - 3);
    final sb = StringBuffer();
    final plen = prefix.length;
    for (int i = 0; i < plen; i++) {
      if (i > 0 && (plen - i) % 2 == 0) sb.write(_thousandSymbol);
      sb.write(prefix[i]);
    }
    sb.write(_thousandSymbol);
    sb.write(suffix);
    return sb.toString();
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

    // Integer part with thousands grouping (western 3-3-3 or indian 3-2-2-…)
    final String raw = intPart.toString();
    final String intFormatted =
        _indianGrouping ? _formatIntIndian(raw) : _formatIntWestern(raw);

    if (decimals > 0) {
      final fracStr = fracPart.toString().padLeft(decimals, '0');
      return '$intFormatted$_decimalSymbol$fracStr';
    }
    return intFormatted;
  }

  /// Detect inputs like "1k", "2.5m", "3B".
  /// Returns (base, multiplier) if a valid abbreviation is found; otherwise `null`.
  (double, double)? _matchAbbreviation(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    var cleaned = s.replaceFirst(_symbolSeparator, '').replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    final last = cleaned.codeUnitAt(cleaned.length - 1);
    final isAlpha = (last >= 65 && last <= 90) || (last >= 97 && last <= 122);
    if (!isAlpha) return null;

    final suffix = String.fromCharCode(last).toLowerCase();
    final mult = _abbreviations[suffix];
    if (mult == null) return null;
    final numberPart = cleaned.substring(0, cleaned.length - 1);
    final baseStr = numberPart
        .replaceAll(_thousandSymbol, '')
        .replaceAll(_decimalSymbol, '.');
    final base = double.tryParse(baseStr);
    if (base == null) return null;

    return (base, mult);
  }

  @override
  void dispose() {
    removeListener(_listener);
    super.dispose();
  }
}