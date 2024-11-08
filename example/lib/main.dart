// ignore_for_file: avoid_print

import 'package:currency_textfield/currency_textfield.dart';
import 'input_field.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency textfield demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Currency Textfield Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CurrencyTextFieldController _controller =
      CurrencyTextFieldController(showZeroValue: true);
  final CurrencyTextFieldController _controller2 = CurrencyTextFieldController(
      initDoubleValue: -10, currencySeparator: ' -> ');
  final CurrencyTextFieldController _controller3 = CurrencyTextFieldController(
      initIntValue: -1000, enableNegative: false, maxValue: 2000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Align(
          child: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              BuildInputField(
                controle: _controller,
                tipoTeclado: TextInputType.number,
                clear: true,
                mascara: allValues,
              ),
              const SizedBox(
                height: 10,
              ),
              MaterialButton(
                onPressed: () {
                  _controller.replaceCurrencySymbol('EUR', resetValue: true);
                },
                child: const Text('Change currency symbol'),
              ),
              const SizedBox(
                height: 30,
              ),
              MaterialButton(
                onPressed: () {
                  print(_controller.doubleValue);
                  print(_controller.value);
                  print(_controller.text);
                  print(_controller.textWithoutCurrencySymbol);
                },
                child: const Text('Controller1 value'),
              ),
              const SizedBox(
                height: 30,
              ),
              BuildInputField(
                controle: _controller2,
                tipoTeclado: TextInputType.number,
                clear: true,
                mascara: allValues,
              ),
              const SizedBox(
                height: 30,
              ),
              MaterialButton(
                onPressed: () {
                  print(_controller2.doubleValue);
                  print(_controller2.text);
                },
                child: const Text('Controller2 value'),
              ),
              const SizedBox(
                height: 30,
              ),
              BuildInputField(
                controle: _controller3,
                tipoTeclado: TextInputType.number,
                clear: true,
                mascara: allValues,
              ),
              const SizedBox(
                height: 30,
              ),
              MaterialButton(
                onPressed: () {
                  print(_controller3.intValue);
                  print(_controller3.text);
                  print(_controller3.textWithoutCurrencySymbol);
                  print(_controller3.doubleTextWithoutCurrencySymbol);
                },
                child: const Text('Controller3 value'),
              ),
              const SizedBox(
                height: 30,
              ),
              MaterialButton(
                onPressed: () {
                  print(
                      'initial value: ${_controller3.text}, initial double value: ${_controller3.doubleValue}');
                  print('trying to change controller.text to 4000');
                  _controller.text = '4000';
                  print(
                      'text value: ${_controller3.text}, double value: ${_controller3.doubleValue}');
                  print('trying to change controller.text to R\$ 4000.00');
                  _controller.text = 'R\$ 4000.00';
                  print(
                      'text value: ${_controller3.text}, double value: ${_controller3.doubleValue}');
                  print(
                      'changing controller.text using _controller3.forceValue() function');
                  _controller3.forceValue(initDoubleValue: 300);
                  print(
                      'final value: ${_controller3.text}, final double value: ${_controller3.doubleValue}');
                },
                child: const Text('Force controller 3 value'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
