import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FilteringTextInputFormatter allValues =
    FilteringTextInputFormatter.allow(RegExp('.*'));

class BuildInputField extends StatefulWidget {
  const BuildInputField(
      {super.key,
      required this.controle,
      this.mascara,
      this.textInputButton = TextInputAction.done,
      this.tipoTeclado = TextInputType.text,
      this.validator,
      this.hint,
      this.width = 200,
      this.oculto = false,
      this.finishFunction,
      this.clear = false,
      this.tapFunction,
      this.lines = 1,
      this.raio = 15,
      this.elevacao = 0.5,
      this.mudeiTextoFunction,
      estilo,
      this.mostrarHint = true,
      this.liberado = true,
      this.alinhamento = TextAlign.start,
      this.disabledColor,
      this.capitalization})
      : estilo = estilo ?? const TextStyle(fontSize: 16);
  final TextEditingController controle;
  final dynamic mascara;
  final TextInputAction textInputButton;
  final TextInputType tipoTeclado;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final double width;
  final bool oculto;
  final Function? finishFunction;
  final bool clear;
  final Function? tapFunction;
  final int? lines;
  final double raio;
  final double elevacao;
  final TextStyle estilo;
  final Function(String)? mudeiTextoFunction;
  final bool mostrarHint;
  final bool liberado;
  final TextAlign alinhamento;
  final Color? disabledColor;
  final TextCapitalization? capitalization;

  @override
  State<BuildInputField> createState() => _BuildInputFieldState();
}

class _BuildInputFieldState extends State<BuildInputField> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Material(
        borderRadius: BorderRadius.circular(widget.raio),
        elevation: widget.elevacao,
        child: TextFormField(
          textCapitalization: widget.capitalization ?? TextCapitalization.none,
          textAlign: widget.alinhamento,
          enabled: widget.liberado,
          style: widget.estilo,
          maxLines: widget.lines,
          obscureText: widget.oculto,
          cursorColor: Colors.transparent,
          controller: widget.controle,
          inputFormatters: [widget.mascara ?? allValues],
          autocorrect: false,
          keyboardType: widget.tipoTeclado,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: widget.validator,
          onEditingComplete: widget.finishFunction as void Function()?,
          textInputAction: widget.textInputButton,
          onTap: widget.tapFunction as void Function()?,
          onChanged: widget.mudeiTextoFunction,
          decoration: InputDecoration(
            labelText: widget.mostrarHint ? widget.hint : null,
            hintText: widget.hint,
            hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
            fillColor: Colors.grey[50],
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.raio),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.raio),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.raio),
              borderSide: const BorderSide(color: Colors.red),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.raio),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.raio),
              borderSide:
                  BorderSide(color: widget.disabledColor ?? Colors.grey[100]!),
            ),
            errorMaxLines: 3,
            suffixIcon: widget.clear
                ? Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      canRequestFocus: false,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      child:
                          const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onTap: () {
                        widget.controle.clear();
                        if (widget.mascara != null) {
                          if (widget.mascara is FilteringTextInputFormatter ==
                              false) {
                            widget.mascara.clear();
                          }
                        }

                        if (widget.mudeiTextoFunction != null) {
                          widget.mudeiTextoFunction!('');
                        }
                      },
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
