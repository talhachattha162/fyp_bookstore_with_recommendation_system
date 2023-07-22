import 'package:bookstore_recommendation_system_fyp/utils/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/themenotifier.dart';

class TextInputField extends StatelessWidget {
  const TextInputField(
      {Key? key,
      required this.hintText,
      required this.suffixIcon,
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
final Widget suffixIcon;
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    const border = UnderlineInputBorder(
        borderSide: BorderSide(width: 1, color: Colors.black));
    final focusedborder = UnderlineInputBorder(
        borderSide: BorderSide(
      width: 1,
      color: themeNotifier.getTheme() ==
              ThemeData.dark(useMaterial3: true).copyWith(
                colorScheme: ColorScheme.dark().copyWith(
                  primary: darkprimarycolor,
                  error: Colors.red,
                  onPrimary: darkprimarycolor,
                  outline: darkprimarycolor,
                  primaryVariant: darkprimarycolor,
                  onPrimaryContainer: darkprimarycolor,
                ),
              )
          ? darkprimarycolor
          : primarycolor,
    ));
    return TextFormField(
      controller: textEditingController,
      decoration: InputDecoration(
          hintText: hintText,
          suffixIcon:suffixIcon,
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


