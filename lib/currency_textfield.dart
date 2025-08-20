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

  late final bool _symbolIsPrefix = _currencyOnLeft;
  late final bool _decimalIsDot = _decimalSymbol == '.';
  late final int _thousandLen = _thousandSymbol.length;
  int _symbolSepLen = 0; // updated in _changeSymbolSeparator()

  String _previewsText = '';
  double _value = 0.0;
  double? _maxValue;
  double? _minValue;
  bool _isNegative = false;
  late bool _startWithSeparator;

  String _lastClearText = '';
  bool _lastIsNegative = false;
  late bool _lastStartWithSeparator;

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
  String get textWithoutCurrencySymbol => _stripCurrencySymbol(text);

  /// Returns the formatted number normalized as a "double-like" string:
  /// - removes thousands separators
  /// - uses "." as decimal separator
  /// - returns "0" if empty
  String get doubleTextWithoutCurrencySymbol {
    final s = text;
    if (s.isEmpty) return '0';
    final noSymbol = _stripCurrencySymbol(s);
    return _normalizeNumericString(noSymbol);
  }

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
        _abbreviations = (abbreviations ?? const {'k': 1e3, 'm': 1e6, 'b': 1e9})
            .map((k, v) => MapEntry(k.toLowerCase(), v.toDouble())) {
    _changeSymbolSeparator();
    _lastStartWithSeparator = _startWithSeparator;
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
        if (!(selection.isCollapsed && selection.end == t.length)) {
          selection =
              TextSelection.fromPosition(TextPosition(offset: t.length));
        }
      }
      return;
    }

    if (t.isEmpty) {
      _zeroValue(clean: _checkCleanZeroText(t));
      _lastClearText = '';
      _lastIsNegative = false;
      _lastStartWithSeparator = _startWithSeparator;
      return;
    }

    // Negative only if allowed and starting with '-'
    _isNegative = _enableNegative && t.startsWith('-');

    // In-progress typing: keep plain minus
    if (t == '-') {
      _previewsText = '-';
      _lastClearText = '';
      _lastIsNegative = _isNegative;
      _lastStartWithSeparator = _startWithSeparator;
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
        _lastClearText = _getOnlyNumbers(string: text) ?? '';
        _lastIsNegative = _isNegative;
        _lastStartWithSeparator = _startWithSeparator;
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
      _lastClearText = '0' * clearText.length;
      _lastIsNegative = _isNegative;
      _lastStartWithSeparator = _startWithSeparator;
      return;
    }

    // Enforce max raw digits
    if (clearText.length > _maxDigits) {
      text = _previewsText;
      return;
    }

    // Switch from integer-mode to decimal-mode when user types the separator
    // do nothing if there are no decimals configured
    if (_numberOfDecimals > 0 &&
        !_startWithSeparator &&
        t.endsWith(_decimalSymbol)) {
      _startWithSeparator = true;
      clearText = clearText + '0' * _numberOfDecimals;
    }
    if (clearText == _lastClearText &&
        _isNegative == _lastIsNegative &&
        _startWithSeparator == _lastStartWithSeparator) {
      if (text != _previewsText) {
        text = _previewsText;
        if (_forceCursorToEnd) {
          final pos = TextPosition(offset: text.length);
          if (!(selection.isCollapsed && selection.end == pos.offset)) {
            selection = TextSelection.fromPosition(pos);
          }
        }
      }
      return;
    }

    _value = _getDoubleValueFor(string: clearText);
    _clampValue();
    _changeText();
    _lastClearText = _getOnlyNumbers(string: text) ?? '';
    _lastIsNegative = _isNegative;
    _lastStartWithSeparator = _startWithSeparator;
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
      _lastClearText = _getOnlyNumbers(string: text) ?? '';
      _lastIsNegative = _isNegative;
      _lastStartWithSeparator = _startWithSeparator;
    }
  }

  /// Replace the current currency symbol with [newSymbol].
  /// If [resetValue] is `true`, the controller value is reset to 0.
  void replaceCurrencySymbol(String newSymbol, {bool resetValue = false}) {
    if (!resetValue && newSymbol == _currencySymbol) return;

    _currencySymbol = newSymbol;
    _changeSymbolSeparator();

    if (resetValue) {
      _value = 0;
    }

    _changeText();
    _lastClearText = _getOnlyNumbers(string: text) ?? '';
    _lastIsNegative = _isNegative;
    _lastStartWithSeparator = _startWithSeparator;
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
    _lastClearText = _getOnlyNumbers(string: text) ?? '';
    _lastIsNegative = _isNegative;
    _lastStartWithSeparator = _startWithSeparator;
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
    _lastClearText = _getOnlyNumbers(string: text) ?? '';
    _lastIsNegative = _isNegative;
    _lastStartWithSeparator = _startWithSeparator;
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
        final core = _symbolIsPrefix
            ? '$_symbolSeparator$masked'
            : '$masked$_symbolSeparator';
        _previewsText = '($core)';
      } else {
        final sign = _isNegative ? '-' : '';
        _previewsText = _symbolIsPrefix
            ? '$sign$_symbolSeparator$masked'
            : '$sign$masked$_symbolSeparator';
      }
    }
    if (text != _previewsText) {
      text = _previewsText;
      final pos = TextPosition(offset: text.length);
      if (!(selection.isCollapsed && selection.end == pos.offset)) {
        selection = TextSelection.fromPosition(pos);
      }
    }
  }

  void _changeSymbolSeparator() {
    if (!_removeSymbol) {
      _symbolSeparator = _symbolIsPrefix
          ? (_currencySymbol + _currencySeparator)
          : (_currencySeparator + _currencySymbol);
    } else {
      _symbolSeparator = '';
    }
    _symbolSepLen = _symbolSeparator.length;
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

  // Western grouping: 3-3-3 (with fast path)
  String _formatIntWestern(String intStr) {
    final len = intStr.length;
    if (len <= 3) return intStr;
    if (len <= 6) {
      final cut = len - 3;
      return '${intStr.substring(0, cut)}$_thousandSymbol${intStr.substring(cut)}';
    }
    final sb = StringBuffer();
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) sb.write(_thousandSymbol);
      sb.write(intStr[i]);
    }
    return sb.toString();
  }

  // Indian grouping: 3-2-2-… (with fast path)
  String _formatIntIndian(String intStr) {
    final len = intStr.length;
    if (len <= 3) return intStr;
    final prefix = intStr.substring(0, len - 3);
    final suffix = intStr.substring(len - 3);
    if (prefix.length <= 2) {
      return '$prefix$_thousandSymbol$suffix';
    }
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
    if (decimals == 0) {
      final intPart = absVal.round();
      final raw = intPart.toString();
      return _indianGrouping ? _formatIntIndian(raw) : _formatIntWestern(raw);
    }

    final int total = (absVal * _scale).round();
    final int intPart = total ~/ _scaleInt;
    final int fracPart = total % _scaleInt;

    // Integer part with thousands grouping (western 3-3-3 or indian 3-2-2-…)
    final String raw = intPart.toString();
    final String intFormatted =
        _indianGrouping ? _formatIntIndian(raw) : _formatIntWestern(raw);

    final fracStr = fracPart.toString().padLeft(decimals, '0');
    return '$intFormatted$_decimalSymbol$fracStr';
  }

  /// Detect inputs like "1k", "2.5m", "3B".
  /// Returns (base, multiplier) if a valid abbreviation is found; otherwise `null`.
  (double, double)? _matchAbbreviation(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    var cleaned = s;
    if (_symbolSepLen > 0) {
      if (_symbolIsPrefix && cleaned.startsWith(_symbolSeparator)) {
        cleaned = cleaned.substring(_symbolSepLen);
      } else if (!_symbolIsPrefix && cleaned.endsWith(_symbolSeparator)) {
        cleaned = cleaned.substring(0, cleaned.length - _symbolSepLen);
      }
    }
    cleaned = cleaned.replaceAll(' ', '');
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

  //remove symbol (prefix/suffix) in O(1) without chained replace*
  String _stripCurrencySymbol(String s) {
    if (_symbolSepLen == 0 || s.isEmpty) return s;
    if (_symbolIsPrefix) {
      return s.startsWith(_symbolSeparator) ? s.substring(_symbolSepLen) : s;
    } else {
      return s.endsWith(_symbolSeparator)
          ? s.substring(0, s.length - _symbolSepLen)
          : s;
    }
  }

  //single-pass removal of thousands and normalization of decimal to '.'
  String _normalizeNumericString(String s) {
    if (s.isEmpty) return s;
    final out = StringBuffer();

    int i = 0;
    var decimalDone = false;

    while (i < s.length) {
      if (_thousandLen > 0 &&
          i + _thousandLen <= s.length &&
          s.substring(i, i + _thousandLen) == _thousandSymbol) {
        i += _thousandLen;
        continue;
      }
      if (!decimalDone &&
          !_decimalIsDot &&
          _decimalSymbol.isNotEmpty &&
          i + _decimalSymbol.length <= s.length &&
          s.substring(i, i + _decimalSymbol.length) == _decimalSymbol) {
        out.write('.');
        i += _decimalSymbol.length;
        decimalDone = true;
        continue;
      }
      out.write(s[i]);
      i++;
    }
    return out.toString();
  }

  @override
  void dispose() {
    removeListener(_listener);
    super.dispose();
  }
}
