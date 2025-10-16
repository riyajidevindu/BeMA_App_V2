import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:flutter/material.dart';
import 'start_relax_screen.dart';
import 'text_guide_screen.dart';
import 'video_guide_screen.dart';

class DiveReflexScreen extends StatelessWidget {
  const DiveReflexScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        showSuccessSnackBarMessage(
          context,
          "Need guidance? Check out the Guides.",
        );
      });
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title Section
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: _buildStrokedText(
                "Dive Reflex Relaxation",
                screenWidth * 0.07,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Illustration for Dive Reflex
            Container(
              height: screenHeight * 0.3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                image: const DecorationImage(
                  image: AssetImage("assets/meditation.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // Buttons Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                children: [
                  // Start Relax Button
                  _buildGradientButton(
                    context,
                    "Start Relax",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StartRelaxScreen(),
                        ),
                      );
                    },
                    [Colors.blue.withOpacity(0.8), Colors.purple.withOpacity(0.8)],
                    screenWidth * 0.06,
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Video Guide Button
                  _buildGradientButton(
                    context,
                    "Video Guide",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VideoGuideScreen(),
                        ),
                      );
                    },
                    [Colors.orange.withOpacity(0.8), Colors.red.withOpacity(0.8)],
                    screenWidth * 0.05,
                    icon: Icons.play_circle,
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Text Guide Button
                  _buildGradientButton(
                    context,
                    "Text Guide",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TextGuideScreen(),
                        ),
                      );
                    },
                    [Colors.green.withOpacity(0.8), Colors.teal.withOpacity(0.8)],
                    screenWidth * 0.05,
                    icon: Icons.article,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrokedText(String text, double fontSize) {
    return Stack(
      children: <Widget>[
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 214, 129, 216),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(BuildContext context, String text,
      VoidCallback onPressed, List<Color> colors, double fontSize,
      {IconData? icon}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.02,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              SizedBox(width: screenWidth * 0.02),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
