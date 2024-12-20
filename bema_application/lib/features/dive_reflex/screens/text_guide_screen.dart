import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TextGuideScreen extends StatelessWidget {
  const TextGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final steps = [
      {
        "heading": "Prepare Cold Water",
        "content": "Fill a bowl with cold water and add ice cubes. If unavailable, grab an ice pack or wet cloth."
      },
      {
        "heading": "Find a Calm Spot",
        "content": "Sit comfortably in a safe and quiet place."
      },
      {
        "heading": "Take a Deep Breath",
        "content": "Inhale deeply to prepare yourself for the exercise."
      },
      {
        "heading": "Apply the Cold",
        "content": "Submerge your face in the cold water for 10–30 seconds. If using an ice pack, press it gently on your forehead and nose."
      },
      {
        "heading": "Breathe and Relax",
        "content": "Focus on slow, deep breaths while applying the cold. Feel your stress melt away."
      },
      {
        "heading": "Repeat if Needed",
        "content": "If stress persists, repeat the process up to 2–3 times."
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Text Guide",
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Steps Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: steps.map((step) {
                  int index = steps.indexOf(step);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "${step['heading']}\n",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: step['content'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}