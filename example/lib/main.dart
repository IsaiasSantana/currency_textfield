// ignore_for_file: avoid_print

import 'package:currency_textfield_2/currency_textfield_2.dart';
import 'package:currency_textfield_2_example/input_field.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CurrencyTextFieldController _controller = CurrencyTextFieldController();
  final CurrencyTextFieldController _controller2 = CurrencyTextFieldController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(
            height: 40,
          ),
          MaterialButton(
            onPressed: () {
              print(_controller.doubleValue);
              print(_controller.value);
              print(_controller.text);
            },
            child: const Text('Controller1 value'),
          ),
          const SizedBox(
            height: 40,
          ),
          BuildInputField(
            controle: _controller2,
            tipoTeclado: TextInputType.number,
            clear: true,
            mascara: allValues,
          ),
          const SizedBox(
            height: 40,
          ),
          MaterialButton(
            onPressed: () {
              print(_controller2.doubleValue);
              print(_controller2.text);
            },
            child: const Text('Controller2 value'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
