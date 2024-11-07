## [4.14.0] - 2024-11-07
- Added missing min value check.
- Fixed zero not being deleted if `showZeroValue` parameter is true.[23](https://github.com/IsaiasSantana/currency_textfield/issues/23)
- Bump flutter_lints to 5.0.0.

## [4.13.0] - 2024-11-06
- Added `removeSymbol` parameter to let you define that controller will only show the formatted number.
- Fixed tests.

## [4.12.1] - 2024-11-06
- Mini improvement to `forceValue` function.

## [4.12.0] - 2024-06-26
- Added `minValue` property to the controller. Now it is possible to define the minimum value the user is allowed to input. Everything lower than that will be forced to the minimum value.

## [4.11.0] - 2024-06-07
- Added `forceCursorToEnd` parameter: now you can define if the controller will always force the user to input the numbers on the end of the string.
- Fixed If enableNegative + showZeroValue properties are true, then negative #s cannot be entered! [22](https://github.com/IsaiasSantana/currency_textfield/issues/22).

## [4.10.1] - 2024-06-04
- Added ios folder to example.

## [4.10.0] - 2024-06-04
- Added `showZeroValue` parameter: now you can define if the controller will show the 0 value.[19](https://github.com/IsaiasSantana/currency_textfield/issues/19)

## [4.9.1] - 2024-06-02
- Fixed a bug that caused minus sign to not disappear when the value of the controller is 0.[18](https://github.com/IsaiasSantana/currency_textfield/issues/18).
- Removed unnecessary call to the listener.

## [4.9.0] - 2024-06-01
- Fixed `symbolSeparator` not reseting if `startWithSeparator` was set to false.[17](https://github.com/IsaiasSantana/currency_textfield/issues/17).
- Fixed [16](https://github.com/IsaiasSantana/currency_textfield/issues/16).
- Fixed an error with `thousandSymbol` introduced in 4.8.0.

## [4.8.0] - 2024-05-31
- Added `startWithSeparator` parameter: now you can define if the controller starts with decimals activated.[15](https://github.com/IsaiasSantana/currency_textfield/issues/15)

## [4.7.0] - 2024-05-30
- Bump flutter_lints to 4.0.0.

## [4.6.1] - 2024-05-30
- Fixed controller output when `numberOfDecimals` = 0.
- Updated web sample to flutter 3.22.

## [4.6.0] - 2024-05-25
- Added `replaceMaxValue` function to the controller. Now it is possible to change the controller's maxValue.

## [4.5.0] - 2024-04-09
- Added `replaceCurrencySymbol` function to the controller. Now it is possible to change the controller's currency symbol.
- Forced `doubleTextWithoutCurrencySymbol` to be '0' when controller.text = ''.

## [4.4.1] - 2024-02-21
- Fixed `doubleTextWithoutCurrencySymbol`.

## [4.4.0] - 2024-02-21
- Added `doubleTextWithoutCurrencySymbol` getter to the controller. Now it is possible to return the number part of the controller as a String, formatted as a double (with `.` as decimal separator).
- Added a check to ensure that `thousandSymbol` and `decimalSymbol` ​​are not the same.

## [4.3.1] - 2024-02-19
- Added `maxValue` property to the controller. Now it is possible to define the maximum value the user is allowed to input. Everything greater than that will be forced to the maximum value.
- Fixed input of `initIntValue` when `numberOfDecimals` was different than 2.

## [4.2.0] - 2024-02-17
- Added `textWithoutCurrencySymbol` getter to the controller. Now it is possible to return the number part of the controller as a String. Good to avoid round errors and to use with decimal package. 
- Readme improvements.

## [4.1.0] - 2024-02-16
- Fixed incorrect handling of negative values.
- Updated android sample and added web.
- Added `forceValue()` function to the controller. Now it is possible to change the controller's value from outside the textfield. 
- `checkNegative()` function now returns true if number is negative and false if it is positive. 
- Bumped flutter_lints to 3.0.1

## [4.0.0]
- Bumped to dart 3

## [3.1.0]
- Added `currencySeparator` that lets you define the separator between the symbol and the value.

## [3.0.0]
- Fixed a [issue](https://github.com/IsaiasSantana/currency_textfield/issues/13) that blocked deleting characters one by one when `currencyOnLeft` = false

## [2.9.0]
- Added the possibility to have negative numbers
- New `enableNegative` parameter to block user from setting negative numbers

## [2.8.0]
- Added `currencyOnLeft` parameter: now you can decide if the symbol will be before or after the number
- breaking change: because of the new parameter, `leftSymbol` was renamed to `currencySymbol`
- fix sample warnings and improved docs

## [2.7.2]
- Mini fix and cleanup

## [2.7.1]
- Improved docs
- Increased the default maxDigits parameter to 15

## [2.7.0]
- Removed decimal dependency in favor of int getter
- Improved sample with the new int initializer and getter

## [2.5.2]
- Improved sample with custom input field

## [2.5.1]
- Bump decimal and dart versions
- Added missing type of some variables, different getters of the controller on example and linter on code

## [2.5.0]
- Fixed cursor position (tks @benz93chung)
- Fixed double value not reseting when clearing content from text field
- added init value
- added precision to double value

## [2.0.0]
- Migrate to null-safety
## [1.0.1] - [1.0.2] - [1.0.3] - 2019-10-07.

-   Adjust parameters.

## [1.0.0] - 2019-10-07.

-   First release.