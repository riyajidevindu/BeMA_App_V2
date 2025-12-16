import 'dart:ui';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/progress_indicator/custom_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoGuideScreen extends StatefulWidget {
  const VideoGuideScreen({Key? key}) : super(key: key);

  @override
  _VideoGuideScreenState createState() => _VideoGuideScreenState();
}

class _VideoGuideScreenState extends State<VideoGuideScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/guide_video.mp4')
      ..initialize().then((_) {
        setState(() {}); // Ensure the first frame is shown after the video is initialized
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rewind() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 5);
    _controller.seekTo(newPosition);
  }

  void _forward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 5);
    _controller.seekTo(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heading
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Text(
                "Video Guide",
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 183, 54, 219),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // GIF
            Container(
              height: screenHeight * 0.1,
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
                  'assets/video_guide.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Video Frame
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Video Progress Indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Colors.white,
                  backgroundColor: Colors.grey,
                  bufferedColor: Colors.lightBlueAccent,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // Action Buttons Panel
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        icon: Icons.replay_10,
                        onPressed: _rewind,
                        size: screenWidth * 0.08,
                      ),
                      _buildActionButton(
                        icon: _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        size: screenWidth * 0.08,
                      ),
                      _buildActionButton(
                        icon: Icons.forward_10,
                        onPressed: _forward,
                        size: screenWidth * 0.08,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _controller.value.isInitialized
          ? null
          : const CustomProgressIndicator(),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required VoidCallback onPressed,
      required double size}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.2),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.all(size * 0.4),
          elevation: 10,
          shadowColor: Colors.black.withOpacity(0.5),
        ),
        child: Icon(
          icon,
          size: size,
        ),
      ),
    );
  }
}
