# currency_textfield

A Controller for currency text input

![sample](doc/gif.gif)

## Usage

Import the library

```dart
import 'package:currency_textfield/currency_textfield.dart';
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

To get the number value from masked text, use the `doubleValue` property:

```dart
final double val = controller.doubleValue;
```


