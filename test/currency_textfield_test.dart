import 'package:flutter_test/flutter_test.dart';

import 'package:currency_textfield/currency_textfield.dart';

void main() {
  test('test_add_0_asInput_for_controller', () {
    final controller = CurrencyTextFieldController();
    controller.text = "0";
    expect(controller.text, "");
    expect(controller.doubleValue, 0.0);
  });

  test('test_add_inputNonZero_for_controller', () {
    final controller = CurrencyTextFieldController();

    controller.text = "1244";
    expect(controller.text, "R\$ 12,44");
    expect(controller.doubleValue, 12.44);
  });

  test('test_change_symbols_constructor', () {
    final controller = CurrencyTextFieldController(leftSymbol: "RR", decimalSymbol: ".", thousandSymbol: ",");

    expect(controller.thousandSymbol, ",");
    expect(controller.leftSymbol, "RR");
    expect(controller.decimalSymbol, ".");
  });

  test('test_invalid_input', () {
    final controller = CurrencyTextFieldController();
    controller.text = "abcl;'s";
    expect(controller.text, "");
    expect(controller.doubleValue, 0.0);
  });

  test('test_insert_input_greatherThan_maximumValue', () {
    final controller = CurrencyTextFieldController();
    controller.text = "99999999999999";
    expect(controller.text, '');
    expect(controller.doubleValue, 0.0);
  });

  test('test_insert_some_inputs_and_after_tryToInsertAValue_greatherThan_maximumValue', () {
    final controller = CurrencyTextFieldController();
    controller.text = "99";
    expect(controller.text, 'R\$ 0,99');
    expect(controller.doubleValue, 0.99);

    controller.text = "99999999999999";
    expect(controller.text, 'R\$ 0,99');
    expect(controller.doubleValue, 0.99);
  });

  test('test_insert_numbers_with_symbols', () {
    final controller = CurrencyTextFieldController();
    controller.text = "-19,24.123";
    expect(controller.text, '');
    expect(controller.doubleValue, 0.0);
  });

  test('initDouble', () {
    final controller = CurrencyTextFieldController(initDoubleValue: 19.5);
    expect(controller.text, 'R\$ 19,50');
  });
}
