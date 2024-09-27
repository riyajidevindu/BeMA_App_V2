import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/common/config/colors.dart';

class Background extends StatefulWidget {
  final bool isBackButton;
  const Background({super.key, required this.isBackButton});

  @override
  _BackgroundState createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  @override
  void initState() {
    super.initState();
    // Pre-cache the image to enhance the experience
    precacheImage(AssetImage('assets/logo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Align(
              alignment: Alignment.center,
              child: Image.asset('assets/logo.png'), // Cached locally
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height,
            color: backgroundColor.withOpacity(0.75),
          ),
          widget.isBackButton
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
        ],
      ),
    );
  }
}
