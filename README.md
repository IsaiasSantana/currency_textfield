# currency_textfield
![Build Status](https://img.shields.io/github/actions/workflow/status/IsaiasSantana/currency_textfield/dart.yml)
[![pub package](https://img.shields.io/pub/v/currency_textfield.svg)](https://pub.dev/packages/currency_textfield)
[![Buy Me A Coffee](https://img.shields.io/badge/☕%20Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/gian.bettega)

A Controller for currency text input

![sample](doc/gif.gif)

## Install

Follow this [guide](https://pub.dev/packages/currency_textfield/install) 

## Usage

Import the library

```dart
import 'package:currency_textfield/currency_textfield.dart';
```

Create the Controller
```dart
CurrencyTextFieldController controller = CurrencyTextFieldController()
```

## Parameters and getters


### Currency Symbol, Decimal and Thousand separator

It's possible to customize `currencySymbol`, `decimalSymbol` and `thousandSymbol`:

```dart
var controller = CurrencyTextFieldController(currencySymbol: "RR", decimalSymbol: ".", thousandSymbol: ",");
```

### Get double value, get int value and get number in string format

To get the number value from controller, you can use both the `doubleValue` or the `intValue` properties:

```dart
//Double value:
final double val = controller.doubleValue;
```

```dart
//Int value:
final int val = controller.intValue;
```

```dart
//String number:
final int val = controller.textWithoutCurrencySymbol;
```

### Initial value

You can initialize the controller using a int or a double, but not both at the same time.
To make this, just use `initDoubleValue` or `initIntValue`:

```dart
final CurrencyTextFieldController controller2 = CurrencyTextFieldController(initDoubleValue: 10);
final CurrencyTextFieldController controller3 = CurrencyTextFieldController(initIntValue: 1000);

// this will raise an error!
final CurrencyTextFieldController controller4 = CurrencyTextFieldController(initIntValue: 1000,initDoubleValue: 10);
```

### Position of the symbol and separator

You can decide if the symbol will be before or after the number.
To make this, just use `currencyOnLeft`:

```dart
// default with the currency before the number
final CurrencyTextFieldController controller = CurrencyTextFieldController();

// currency after the number
final CurrencyTextFieldController controller2 = CurrencyTextFieldController(currencyOnLeft: false);
```

And also  define the separator between the symbol and the value with `currencySeparator`:

```dart
// the default value is a single space
final CurrencyTextFieldController controller = CurrencyTextFieldController(currencySeparator: ' -> ');
```

### Block the user from setting negative numbers
Just set `enableNegative` to false

### Force a value from outside the TextField
```dart
final CurrencyTextFieldController controller = CurrencyTextFieldController();
// using a double
controller.forceValue(initDoubleValue: 300.5);

// using an int
controller.forceValue(initIntValue: 10000);
```

### Change the currency symbol of the controller
```dart
final CurrencyTextFieldController controller = CurrencyTextFieldController();
// keeping the current value:
controller.replaceCurrencySymbol('EUR');

// reseting the current value:
controller.replaceCurrencySymbol('EUR', resetValue: true);
```