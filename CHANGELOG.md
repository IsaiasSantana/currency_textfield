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