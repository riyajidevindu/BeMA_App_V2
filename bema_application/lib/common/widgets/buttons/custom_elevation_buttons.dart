import 'package:bema_application/common/config/colors.dart';
import 'package:flutter/material.dart';

//Custom Elevation Button

class CustomElevationBtn extends StatefulWidget {
  final String buttonName;
  final Function() onClick;
  final bool isSubmitting;
  const CustomElevationBtn(
      {super.key,
      required this.buttonName,
      required this.onClick,
      required this.isSubmitting});

  @override
  State<CustomElevationBtn> createState() => _CustomElevationBtnState();
}

class _CustomElevationBtnState extends State<CustomElevationBtn> {
  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
        ),
        
        onPressed: () {
          widget.isSubmitting ?null: widget.onClick();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: widget.isSubmitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: backgroundColor,
                  ))
              : Text(
                  widget.buttonName,
                  style: const TextStyle(
                    color: backgroundColor,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

class CustomOutLineButtonGreen extends StatefulWidget {
  final String buttonName;
  final Function() onClick;
  const CustomOutLineButtonGreen(
      {super.key, required this.buttonName, required this.onClick});

  @override
  State<CustomOutLineButtonGreen> createState() =>
      _CustomOutLineButtonGreenState();
}

class _CustomOutLineButtonGreenState extends State<CustomOutLineButtonGreen> {
  var isLoading = false;
  Future<void> onClick() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    widget.onClick();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return SizedBox(
      width: 150,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: successColor),
        ),
        onPressed: () {
          onClick();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: height * 0.015),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: successColor,
                  ))
              : Text(
                  widget.buttonName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: successColor,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
