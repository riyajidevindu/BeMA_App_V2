//text field with underline

import 'package:bema_application/common/config/colors.dart';
import 'package:flutter/material.dart';

class CustomTextFieldUB extends StatefulWidget {
  final TextEditingController controller;
  final IconData prefixIcon;
  final String labelText;
  final String hintText;
  final bool isObscureText;
  final String? Function(String?) validation;
  final TextInputType inputType;
  final bool enabled;
  final Color textColor;

  const CustomTextFieldUB({
    super.key,
    required this.controller,
    required this.prefixIcon,
    required this.labelText,
    required this.hintText,
    required this.isObscureText,
    required this.validation,
    required this.inputType,
    required this.enabled,
    this.textColor = backgroundColor,
  });

  @override
  State<CustomTextFieldUB> createState() => _CustomTextFieldUBState();
}

class _CustomTextFieldUBState extends State<CustomTextFieldUB> {
  bool obscureText = true;
  bool showIcon = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      child: TextFormField(
        enabled: widget.enabled,
        controller: widget.controller,
        keyboardType: widget.inputType,
        obscureText: widget.isObscureText ? obscureText : false,
        validator: widget.validation,
        cursorColor: widget.textColor,
        decoration: InputDecoration(
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: widget.textColor),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          labelText: widget.labelText,
          labelStyle: TextStyle(color: widget.textColor),
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: placeholderColor),
          prefixIcon: Icon(
            widget.prefixIcon,
            color: widget.textColor,
          ),
          suffixIcon: widget.isObscureText
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: IconButton(
                    icon: showIcon
                        ? Icon(
                            Icons.visibility_off,
                            color: widget.textColor,
                          )
                        : Icon(
                            Icons.visibility,
                            color: widget.textColor,
                          ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                        showIcon = !showIcon;
                      });
                    },
                  ),
                )
              : null,
        ),
        style: TextStyle(color: widget.textColor),
      ),
    );
  }
}
