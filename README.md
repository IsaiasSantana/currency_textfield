# currency_textfield_2

A Controller for currency text input

Forked from https://pub.dev/packages/currency_textfield
Updated with fixes and new settings

![sample](doc/gif.gif)

## Install

Follow this [guide](https://pub.dev/packages/currency_textfield_2/install) 

## Usage

Import the library

```dart
import 'package:currency_textfield_2/currency_textfield_2.dart';
```

Create the Controller
```dart
CurrencyTextFieldController controller = CurrencyTextFieldController()
```

### Currency Symbol, Decimal and Thousand separator

It's possible to customize `leftSymbol`, `decimal` and `thousand` separators:

```dart
var controller = CurrencyTextFieldController(leftSymbol: "RR", decimalSymbol: ".", thousandSymbol: ",");
```

### Get double value

To get the number value from controller, use the `doubleValue` property:

```dart
final double val = controller.doubleValue;
```


