import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TextGuideScreen extends StatefulWidget {
  const TextGuideScreen({Key? key}) : super(key: key);

  @override
  _TextGuideScreenState createState() => _TextGuideScreenState();
}

class _TextGuideScreenState extends State<TextGuideScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showDownArrow = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // At the top
        setState(() {
          _showDownArrow = true;
        });
      } else {
        // At the bottom
        setState(() {
          _showDownArrow = false;
        });
      }
    } else {
      setState(() {
        _showDownArrow = true;
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title Section
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
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
                SizedBox(height: screenHeight * 0.02),

                // GIF
                Container(
                  height: screenHeight * 0.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    child: Image.asset(
                      'assets/manual.gif',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Steps Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    children: steps.map((step) {
                      int index = steps.indexOf(step);
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
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
                                  text: "${step['heading']}\n", // Added extra newline for more space
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    height: 2.0,
                                  ),
                                ),
                                TextSpan(
                                  text: step['content'],
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                    height: 1.4,
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
          if (_showDownArrow)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _scrollToBottom,
                backgroundColor: Colors.white.withOpacity(0.8),
                elevation: 4,
                child: const Icon(
                  Icons.arrow_downward,
                  color: Colors.blueAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}