import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import '../models/exercise.dart';
import 'package:bema_application/routes/route_names.dart';

class VideoGuideScreen extends StatefulWidget {
  final Exercise exercise;

  const VideoGuideScreen({super.key, required this.exercise});

  @override
  State<VideoGuideScreen> createState() => _VideoGuideScreenState();
}

class _VideoGuideScreenState extends State<VideoGuideScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.exercise.videoUrl == null) {
        setState(() {
          _hasError = true;
        });
        return;
      }

      // Check if it's a network URL or asset
      if (widget.exercise.videoUrl!.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.exercise.videoUrl!),
        );
      } else {
        _controller = VideoPlayerController.asset(widget.exercise.videoUrl!);
      }

      await _controller!.initialize();

      // Set video to loop automatically
      _controller!.setLooping(true);

      setState(() {
        _isInitialized = true;
      });

      // Auto-play the video
      _controller!.play();
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildStrokedText('${widget.exercise.name} Guide', 22),
                    const SizedBox(height: 5),
                    const Text(
                      'Watch and learn proper form',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(179, 255, 255, 255),
                      ),
                    ),
                  ],
                ),
              ),

              // Video Player
              Expanded(
                flex: 3,
                child: _buildVideoPlayer(),
              ),
              const SizedBox(height: 20),

              // Exercise Info
              Expanded(
                flex: 2,
                child: _buildExerciseInfo(),
              ),
              const SizedBox(height: 20),

              // Video Controls - Always visible
              _buildControlButtons(),
              const SizedBox(height: 15),

              // Ready Button - Always visible
              _buildReadyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 10),
              Text(
                'Video not available',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStrokedText('Key Points:', 18),
                const SizedBox(height: 10),
                Text(
                  widget.exercise.benefits,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(230, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 15),
                _buildStrokedText('Form Tips:', 16),
                const SizedBox(height: 8),
                const Text(
                  '✓ Maintain proper posture throughout\n'
                  '✓ Control your movement speed\n'
                  '✓ Breathe steadily and consistently\n'
                  '✓ Focus on quality over quantity',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(200, 255, 255, 255),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    if (!_isInitialized) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Restart button
        ElevatedButton.icon(
          onPressed: () {
            _controller!.seekTo(Duration.zero);
            _controller!.play();
          },
          icon: const Icon(Icons.replay, color: Colors.white, size: 24),
          label: const Text('Restart', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Play/Pause button
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _controller!.value.isPlaying
                  ? _controller!.pause()
                  : _controller!.play();
            });
          },
          icon: Icon(
            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 28,
          ),
          label: Text(
            _controller!.value.isPlaying ? 'Pause' : 'Play',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _controller!.value.isPlaying
                ? Colors.orange.withOpacity(0.8)
                : Colors.green.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.poseCoachScreen,
          arguments: widget.exercise,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: const Text(
        "✅ I'm Ready — Start AI Coach",
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStrokedText(String text, double fontSize,
      {bool isSelected = true}) {
    return Stack(
      children: <Widget>[
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
