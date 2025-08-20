import 'package:flutter_test/flutter_test.dart';
import 'package:currency_textfield/currency_textfield.dart';

void main() {
  test('input_zero_results_in_empty_text', () {
    final controller = CurrencyTextFieldController();
    controller.text = "0";
    expect(controller.text, "");
    expect(controller.doubleValue, 0.0);
  });

  test('input_non_zero_formats_correctly', () {
    final controller = CurrencyTextFieldController();
    controller.text = "1244";
    expect(controller.text, "R\$ 12,44");
    expect(controller.doubleValue, 12.44);

    // Large BR value (long path, western grouping)
    final cLarge = CurrencyTextFieldController(initDoubleValue: 1234567890.12);
    expect(cLarge.text, 'R\$ 1.234.567.890,12');
  });

  test('constructor_allows_custom_symbols', () {
    final controller = CurrencyTextFieldController(
      currencySymbol: "RR",
      decimalSymbol: ".",
      thousandSymbol: ",",
    );
    expect(controller.thousandSymbol, ",");
    expect(controller.currencySymbol, "RR");
    expect(controller.decimalSymbol, ".");
  });

  test('invalid_input_is_ignored', () {
    final controller = CurrencyTextFieldController();
    controller.text = "abcl;'s";
    expect(controller.text, "");
    expect(controller.doubleValue, 0.0);
  });

  test('input_longer_than_max_digits_is_rejected', () {
    final controller = CurrencyTextFieldController();
    controller.text = "9999999999999999";
    expect(controller.text, '');
    expect(controller.doubleValue, 0.0);
  });

  test('exceeding_max_digits_after_valid_input_keeps_previous_value', () {
    final controller = CurrencyTextFieldController();
    controller.text = "99";
    expect(controller.text, 'R\$ 0,99');
    expect(controller.doubleValue, 0.99);

    controller.text = "9999999999999999";
    expect(controller.text, 'R\$ 0,99');
    expect(controller.doubleValue, 0.99);
  });

  test('mixed_symbols_are_sanitized', () {
    final controller = CurrencyTextFieldController();
    controller.text = "-19,24.123";
    expect(controller.text, '-R\$ 19.241,23');
    expect(controller.doubleValue, -19241.23);

    controller.text = "-19?24.123";
    expect(controller.text, '-R\$ 19.241,23');
  });

  test('init_with_double_formats_correctly', () {
    final controller = CurrencyTextFieldController(initDoubleValue: 19.5);
    expect(controller.text, 'R\$ 19,50');
  });

  test('init_with_int_formats_correctly', () {
    final controller = CurrencyTextFieldController(initIntValue: 195);
    expect(controller.text, 'R\$ 1,95');
    expect(controller.doubleValue, 1.95);
  });

  test('currency_on_right_positions_symbol_correctly', () {
    final controller =
        CurrencyTextFieldController(initIntValue: 195, currencyOnLeft: false);
    expect(controller.text, '1,95 R\$');

    // Large value with symbol on right (western)
    final cRightLarge = CurrencyTextFieldController(
      currencyOnLeft: false,
      initDoubleValue: 1234567890.12,
    );
    expect(cRightLarge.text, '1.234.567.890,12 R\$');

    // Large value with symbol on right (indian grouping)
    final cRightLargeIndian = CurrencyTextFieldController(
      currencyOnLeft: false,
      indianGrouping: true,
      initDoubleValue: 1234567890.12,
    );
    expect(cRightLargeIndian.text, '1.23.45.67.890,12 R\$');
  });

  test('negative_values_respect_enableNegative_flag', () {
    final controller = CurrencyTextFieldController(initIntValue: -195);
    final controller2 =
        CurrencyTextFieldController(initIntValue: -195, enableNegative: false);
    expect(controller.text, '-R\$ 1,95');
    expect(controller2.text, 'R\$ 1,95');
  });

  test('force_value_updates_text_correctly', () {
    final controller = CurrencyTextFieldController(initIntValue: 195);
    controller.forceValue(initIntValue: 100);
    expect(controller.text, 'R\$ 1,00');
    controller.forceValue(initDoubleValue: 100);
    expect(controller.text, 'R\$ 100,00');
  });

  test('text_without_currency_symbol_is_correct', () {
    final controller = CurrencyTextFieldController(initIntValue: 195);
    final controller2 =
        CurrencyTextFieldController(initIntValue: 195, currencyOnLeft: false);
    final controller3 = CurrencyTextFieldController(
      initDoubleValue: 195,
      currencySymbol: 'test',
      currencySeparator: ' e ',
    );
    final controller4 = CurrencyTextFieldController(
      initIntValue: 195,
      currencyOnLeft: false,
      currencySymbol: '\$',
      currencySeparator: '->',
      decimalSymbol: ':',
    );
    expect(controller.textWithoutCurrencySymbol, '1,95');
    expect(controller2.textWithoutCurrencySymbol, '1,95');
    expect(controller3.textWithoutCurrencySymbol, '195,00');
    expect(controller4.textWithoutCurrencySymbol, '1:95');
  });

  test('init_int_respects_number_of_decimals', () {
    final controller = CurrencyTextFieldController(initIntValue: 195);
    final controller2 =
        CurrencyTextFieldController(initIntValue: 1950, numberOfDecimals: 1);
    final controller3 =
        CurrencyTextFieldController(initIntValue: 19500, numberOfDecimals: 3);

    expect(controller.textWithoutCurrencySymbol, '1,95');
    expect(controller2.textWithoutCurrencySymbol, '195,0');
    expect(controller3.textWithoutCurrencySymbol, '19,500');
  });

  test('zero_decimals_formats_without_fraction', () {
    final controller =
        CurrencyTextFieldController(initIntValue: 19500, numberOfDecimals: 0);

    expect(controller.textWithoutCurrencySymbol, '19.500');
    expect(controller.doubleValue, 19500.0);
    expect(controller.intValue, 19500);
    expect(controller.doubleTextWithoutCurrencySymbol, '19500');

    // Large integer, no decimals (western long path)
    final cNoDecLarge = CurrencyTextFieldController(
        numberOfDecimals: 0, initDoubleValue: 1234567890);
    expect(cNoDecLarge.text, 'R\$ 1.234.567.890');
  });

  test('max_value_clamps_on_forceValue', () {
    final controller =
        CurrencyTextFieldController(initDoubleValue: 300, maxValue: 400);

    controller.forceValue(initDoubleValue: 350);
    expect(controller.textWithoutCurrencySymbol, '350,00');
    controller.forceValue(initDoubleValue: 3500);
    expect(controller.textWithoutCurrencySymbol, '400,00');
  });

  test('replace_currency_symbol_updates_text_and_state', () {
    final controller = CurrencyTextFieldController(initIntValue: 195);
    controller.replaceCurrencySymbol('EUR');
    expect(controller.text, 'EUR 1,95');
    expect(controller.doubleValue, 1.95);
    expect(controller.intValue, 195);
    expect(controller.currencySymbol, 'EUR');
    expect(controller.doubleTextWithoutCurrencySymbol, '1.95');
    expect(controller.textWithoutCurrencySymbol, '1,95');

    controller.replaceCurrencySymbol('USD', resetValue: true);
    expect(controller.text, '');
    expect(controller.doubleValue, 0);
    expect(controller.intValue, 0);
    expect(controller.currencySymbol, 'USD');
    expect(controller.doubleTextWithoutCurrencySymbol, '0');
    expect(controller.textWithoutCurrencySymbol, '');
  });

  test('replace_max_value_respects_clamping', () {
    final controller =
        CurrencyTextFieldController(initDoubleValue: 300, maxValue: 400);

    controller.forceValue(initDoubleValue: 600);
    expect(controller.textWithoutCurrencySymbol, '400,00');
    controller.replaceMaxValue(700);
    controller.forceValue(initDoubleValue: 600);
    expect(controller.textWithoutCurrencySymbol, '600,00');
    controller.replaceMaxValue(500);
    expect(controller.textWithoutCurrencySymbol, '500,00');
  });

  test('show_zero_value_with_initial_zero_formats_value', () {
    final controller =
        CurrencyTextFieldController(initIntValue: 0, showZeroValue: true);
    expect(controller.text, "R\$ 0,00");
  });

  test('show_zero_value_without_initial_value_displays_empty', () {
    final controller = CurrencyTextFieldController(showZeroValue: true);
    final controller2 = CurrencyTextFieldController(initIntValue: 0);
    expect(controller.text, '');
    expect(controller2.text, '');
  });

  test('enable_negative_with_show_zero_value_edge_cases', () {
    final controller = CurrencyTextFieldController(showZeroValue: true);
    controller.text = "R\$ 0,00-";
    expect(controller.text, '-R\$ 0,00');
    controller.clear();
    controller.text = "R\$ 7,00-";
    expect(controller.text, "R\$ 7,00");
  });

  test('min_value_clamps_on_forceValue_and_constructor', () {
    final controller =
        CurrencyTextFieldController(initDoubleValue: 300, minValue: 200);
    final controller2 =
        CurrencyTextFieldController(initDoubleValue: 100, minValue: 200);

    controller.forceValue(initDoubleValue: 100);
    expect(controller.textWithoutCurrencySymbol, '200,00');
    expect(controller2.textWithoutCurrencySymbol, '200,00');
  });

  test('replace_min_value_respects_clamping', () {
    final controller =
        CurrencyTextFieldController(initDoubleValue: 300, minValue: 200);

    controller.forceValue(initDoubleValue: 100);
    expect(controller.textWithoutCurrencySymbol, '200,00');
    controller.replaceMinValue(0);
    controller.forceValue(initDoubleValue: 50);
    expect(controller.textWithoutCurrencySymbol, '50,00');
  });

  test('remove_symbol_hides_symbol_but_preserves_values', () {
    final controller =
        CurrencyTextFieldController(initDoubleValue: 300, removeSymbol: true);

    expect(controller.textWithoutCurrencySymbol, '300,00');
    expect(controller.text, '300,00');
    expect(controller.currencySymbol, 'R\$');
    expect(controller.doubleValue, 300);
    expect(controller.intValue, 30000);
    expect(controller.doubleTextWithoutCurrencySymbol, '300.00');
  });

  test('clear_on_zero_value_clears_text', () {
    final controller =
        CurrencyTextFieldController(initIntValue: 0, showZeroValue: true);

    controller.clear();
    expect(controller.text, "");
  });

  test('start_with_separator_false_keeps_integers_until_separator', () {
    final c = CurrencyTextFieldController(startWithSeparator: false);
    c.text = '1234';
    expect(c.text, 'R\$ 1.234');
    c.text = '1234,';
    expect(c.text, 'R\$ 1.234,00');

    // Large integer typed in integer-mode (no decimals until separator)
    c.clear();
    c.text = '1234567890';
    expect(c.text, 'R\$ 1.234.567.890');
  });

  test('max_digits_accepts_exact_limit_and_blocks_above', () {
    final c = CurrencyTextFieldController(maxDigits: 4);
    c.text = '1234';
    expect(c.text, 'R\$ 12,34');
    c.text = '12345';
    expect(c.text, 'R\$ 12,34');
  });

  test('cursor_moves_to_end_after_formatting', () {
    final c = CurrencyTextFieldController();
    c.text = '1244';
    expect(c.selection.baseOffset, c.text.length);
    expect(c.selection.extentOffset, c.text.length);
  });

  test('custom_thousand_and_decimal_symbols_large_number', () {
    final c = CurrencyTextFieldController(
      decimalSymbol: '.',
      thousandSymbol: ',',
      initDoubleValue: 1234567,
    );
    expect(c.text, 'R\$ 1,234,567.00');

    // Even larger value with en-US symbols
    c.forceValue(initDoubleValue: 1234567890.12);
    expect(c.text, 'R\$ 1,234,567,890.12');
  });

  test('currency_on_right_with_remove_symbol_true_has_no_trailing_separator',
      () {
    final c = CurrencyTextFieldController(
      initDoubleValue: 12.34,
      currencyOnLeft: false,
      removeSymbol: true,
    );
    expect(c.text, '12,34');
  });

  test('int_value_and_negative_while_typing', () {
    final c = CurrencyTextFieldController();
    c.text = '-100';
    expect(c.text, '-R\$ 1,00');
    expect(c.intValue, -100);
    expect(c.doubleValue, -1.00);
  });

  test('replace_max_value_with_reset_clears_text', () {
    final c = CurrencyTextFieldController(initDoubleValue: 123);
    c.replaceMaxValue(50, resetValue: true);
    expect(c.doubleValue, 0.0);
    expect(c.text, '');
  });

  test('replace_min_value_with_reset_clears_text', () {
    final c = CurrencyTextFieldController(initDoubleValue: 123);
    c.replaceMinValue(200, resetValue: true);
    expect(c.doubleValue, 0.0);
    expect(c.text, '');
  });

  test('double_text_without_currency_returns_zero_when_empty', () {
    final c = CurrencyTextFieldController();
    expect(c.text, '');
    expect(c.doubleTextWithoutCurrencySymbol, '0');
  });

  test('number_of_decimals_zero_when_typing_and_derivatives', () {
    final c = CurrencyTextFieldController(numberOfDecimals: 0);
    c.text = '19500';
    expect(c.textWithoutCurrencySymbol, '19.500');
    expect(c.doubleValue, 19500.0);
    expect(c.intValue, 19500);
    expect(c.doubleTextWithoutCurrencySymbol, '19500');
  });

  test('replace_currency_symbol_with_right_position_keeps_format', () {
    final c = CurrencyTextFieldController(
      initIntValue: 195,
      currencyOnLeft: false,
    );
    expect(c.text, '1,95 R\$');
    c.replaceCurrencySymbol('USD');
    expect(c.text, '1,95 USD');
  });

  test('indian_grouping_false_keeps_western_format', () {
    final c = CurrencyTextFieldController(initDoubleValue: 1234567.89);
    expect(c.text, 'R\$ 1.234.567,89');
  });

  test('indian_grouping_true_applies_3_2_2', () {
    final c = CurrencyTextFieldController(
      initDoubleValue: 1234567.89,
      indianGrouping: true,
    );
    expect(c.text, 'R\$ 12.34.567,89');

    // Large value (long path, indian grouping)
    final cLargeIndian = CurrencyTextFieldController(
      indianGrouping: true,
      initDoubleValue: 1234567890.12,
    );
    expect(cLargeIndian.text, 'R\$ 1.23.45.67.890,12');
  });

  test('negative_parentheses_false_keeps_minus_sign', () {
    final c = CurrencyTextFieldController(initDoubleValue: -1234.56);
    expect(c.text, '-R\$ 1.234,56');

    // Large negative (western long path)
    final cNegLarge =
        CurrencyTextFieldController(initDoubleValue: -9876543210.99);
    expect(cNegLarge.text, '-R\$ 9.876.543.210,99');
  });

  test('negative_parentheses_true_wraps_in_parentheses', () {
    final c = CurrencyTextFieldController(
      initDoubleValue: -1234.56,
      negativeParentheses: true,
    );
    expect(c.text, '(R\$ 1.234,56)');
  });

  test('abbreviations_convert_k_m_b', () {
    final c = CurrencyTextFieldController(enableAbbreviations: true);
    c.text = '1k';
    expect(c.doubleValue, 1000.0);
    expect(c.text, 'R\$ 1.000,00');

    c.clear();
    c.text = '2,5m';
    expect(c.doubleValue, 2500000.0);
    expect(c.text, 'R\$ 2.500.000,00');

    c.clear();
    c.text = '3B';
    expect(c.doubleValue, 3000000000.0);
    expect(c.text, 'R\$ 3.000.000.000,00');
  });

  test('abbreviations_respect_negative_sign', () {
    final c = CurrencyTextFieldController(enableAbbreviations: true);
    c.text = '-2k';
    expect(c.doubleValue, -2000.0);
    expect(c.text, '-R\$ 2.000,00');
  });

  test('abbreviations_with_dot_decimal_in_enUS_style', () {
    final c = CurrencyTextFieldController(
      enableAbbreviations: true,
      decimalSymbol: '.',
      thousandSymbol: ',',
    );
    c.text = '2.5m';
    expect(c.doubleValue, 2500000.0);
    expect(c.text, 'R\$ 2,500,000.00');
  });

  test('negative_parentheses_true_with_symbol_on_right', () {
    final c = CurrencyTextFieldController(
      initDoubleValue: -195,
      currencyOnLeft: false,
      negativeParentheses: true,
    );
    expect(c.text, '(195,00 R\$)');
  });

  test('indian_grouping_with_start_without_separator_typing_flow', () {
    final c = CurrencyTextFieldController(
        indianGrouping: true, startWithSeparator: false);
    c.text = '1234567';
    expect(c.text, 'R\$ 12.34.567'); // sem casas decimais

    // Larger integer in integer-mode (indian)
    c.clear();
    c.text = '1234567890';
    expect(c.text, 'R\$ 1.23.45.67.890'); // sem casas decimais
  });

  // Fast path: western grouping with <=6 digits
  test('western_fast_path_for_six_digits', () {
    final c = CurrencyTextFieldController();
    c.text = '123456'; // should insert one thousand separator
    expect(c.text, 'R\$ 1.234,56');
  });

  // Fast path: indian grouping when prefix length <=2
  test('indian_fast_path_prefix_leq_2', () {
    final c = CurrencyTextFieldController(indianGrouping: true);
    c.text = '1234'; // 12.34
    expect(c.text, 'R\$ 12,34');
    c.clear();
    c.text = '12345'; // inteiro=123 -> 123,45
    expect(c.text, 'R\$ 123,45');
  });

  // Decimals == 0: early return, multiple values
  test('no_decimals_early_return_formatting', () {
    final c = CurrencyTextFieldController(numberOfDecimals: 0);
    c.text = '0';
    expect(c.text, ''); // showZeroValue default false
    c.text = '123'; // 123
    expect(c.text, 'R\$ 123');
    c.text = '-1234567'; // negative
    expect(c.text, '-R\$ 1.234.567');

    // Indian grouping + no decimals (long path) via init
    final ci = CurrencyTextFieldController(
      indianGrouping: true,
      numberOfDecimals: 0,
      initDoubleValue: 1234567890,
    );
    expect(ci.text, 'R\$ 1.23.45.67.890');
  });

  // Decimals == 0 + startWithSeparator=false (integer-only typing)
  test('no_decimals_with_start_without_separator', () {
    final c = CurrencyTextFieldController(
        numberOfDecimals: 0, startWithSeparator: false);
    c.text = '123456';
    expect(c.text, 'R\$ 123.456');
  });

  // Multi-char separators in normalization (e.g., thin space + custom)
  test('doubleTextWithoutCurrencySymbol_with_multichar_separators', () {
    final c = CurrencyTextFieldController(
      currencySymbol: 'EUR',
      currencySeparator: '\u00A0', // NBSP
      thousandSymbol: "'", // Swiss style
      decimalSymbol: '.',
      initDoubleValue: 1234.5,
    );
    // EUR⎵1'234.50
    expect(c.text, "EUR\u00A01'234.50");
    expect(c.textWithoutCurrencySymbol, "1'234.50");
    expect(c.doubleTextWithoutCurrencySymbol, '1234.50');
  });

  // replaceCurrencySymbol no-op when symbol is the same and no reset
  test('replaceCurrencySymbol_noop_when_same_symbol', () {
    final c = CurrencyTextFieldController(initDoubleValue: 12.34);
    final before = c.text;
    c.replaceCurrencySymbol('R\$'); // same as default and resetValue=false
    expect(c.text, before);
  });

  // Short-circuit: setting same clearText should not change text/selection
  test('short_circuit_when_clearText_unchanged', () {
    final c = CurrencyTextFieldController();
    c.text = '1244';
    final beforeText = c.text;
    final beforeSel = c.selection;
    // Reassign an equivalent formatted input (same clearText after sanitization)
    c.text = 'R\$ 12,44'; // same value as '1244' produces
    expect(c.text, beforeText);
    expect(c.selection.baseOffset, beforeSel.baseOffset);
    expect(c.selection.extentOffset, beforeSel.extentOffset);
  });

  // Abbreviations with currency symbol present (prefix)
  test('abbreviations_with_prefix_symbol', () {
    final c = CurrencyTextFieldController(enableAbbreviations: true);
    c.text = 'R\$ 2k';
    expect(c.doubleValue, 2000.0);
    expect(c.text, 'R\$ 2.000,00');
  });

  // Abbreviations with suffix symbol (currencyOnLeft=false)
  test('abbreviations_with_suffix_symbol', () {
    final c = CurrencyTextFieldController(
        enableAbbreviations: true, currencyOnLeft: false);
    c.text = '2k R\$';
    expect(c.doubleValue, 2000.0);
    expect(c.text, '2.000,00 R\$');
  });

  // Abbreviations + enableNegative=false should coerce to positive
  test('abbreviations_respect_enableNegative_false', () {
    final c = CurrencyTextFieldController(
        enableAbbreviations: true, enableNegative: false);
    c.text = '-2k';
    expect(c.doubleValue, 2000.0);
    expect(c.text, 'R\$ 2.000,00');
  });
  test('selection_not_reapplied_when_setting_same_text', () {
    final c = CurrencyTextFieldController();
    c.text = '1244'; // formata para 'R$ 12,44'
    final beforeSel = c.selection;
    final same = c.text; // exatamente o mesmo texto já formatado
    c.text = same; // cai no early return (t == _previewsText)
    expect(c.text, same);
    expect(c.selection.baseOffset, beforeSel.baseOffset);
    expect(c.selection.extentOffset, beforeSel.extentOffset);
  });

  test('abbreviations_with_dot_decimal_in_enUS_style', () {
    final c = CurrencyTextFieldController(
      enableAbbreviations: true,
      decimalSymbol: '.',
      thousandSymbol: ',',
    );
    c.text = '2.5m';
    expect(c.doubleValue, 2500000.0);
    expect(c.text, 'R\$ 2,500,000.00');
  });
}
