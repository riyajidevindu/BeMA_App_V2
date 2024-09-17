import 'package:bema_application/common/config/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Background extends StatelessWidget {
  final bool isBackButton;
  const Background({super.key, required this.isBackButton});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(children: [
        Center(
          child: Align(
            alignment: Alignment.center,
            child: Image.asset('assets/logo.png'),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height,
          color: backgroundColor.withOpacity(0.75),
        ),
        //back button
        isBackButton
            ? GestureDetector(
                onTap: () {
                  debugPrint('back button pressed');
                  context.pop();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                  child: Icon(
                    Icons.arrow_back,
                    color: backgroundColor,
                  ),
                ),
              )
            : const SizedBox(),
      ]),
    );
  }
}
