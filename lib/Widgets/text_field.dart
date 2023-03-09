import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:flutter/material.dart';

class TextInputField extends StatelessWidget {
  const TextInputField(
      {Key? key,
      required this.hintText,
      required this.textInputType,
      required this.textEditingController,
      required this.isPassword,
      required this.validator})
      : super(key: key);
  final TextEditingController textEditingController;
  final bool isPassword;
  final String hintText;
  final TextInputType textInputType;
  final FormFieldValidator validator;

  @override
  Widget build(BuildContext context) {
    const border = UnderlineInputBorder(
        borderSide: BorderSide(width: 1, color: Colors.black));
    const focusedborder = UnderlineInputBorder(
        borderSide: BorderSide(width: 1, color: primarycolor));
    return TextFormField(
        controller: textEditingController,
        decoration: InputDecoration(
            hintText: hintText,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedborder,
            contentPadding: const EdgeInsets.all(10)),
        keyboardType: textInputType,
        obscureText: isPassword,
        validator: validator,
        );
  }
}
