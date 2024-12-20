import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class VideoGuideScreen extends StatelessWidget {
  const VideoGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false
      ),
      body: Center(
        child: Text(
          "Video Player Integration Goes Here!",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
