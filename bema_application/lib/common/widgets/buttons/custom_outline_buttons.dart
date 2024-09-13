//Red
import 'package:bema_application/common/config/colors.dart';
import 'package:flutter/material.dart';

class CustomOutLineButton extends StatefulWidget {
  final String buttonName;
  final Function() onClick;
  const CustomOutLineButton(
      {super.key, required this.buttonName, required this.onClick});

  @override
  State<CustomOutLineButton> createState() => _CustomOutLineButtonState();
}

class _CustomOutLineButtonState extends State<CustomOutLineButton> {
  var isLoading = false;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: const BorderSide(color: primaryColor),
        ),
        onPressed: () {
          widget.onClick();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ))
              : Text(
                  widget.buttonName,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
