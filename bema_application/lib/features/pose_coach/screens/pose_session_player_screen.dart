import 'dart:io';
import 'package:bema_application/features/pose_coach/models/pose_session.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PoseSessionPlayerScreen extends StatefulWidget {
  static const routePath = '/poseSessionPlayer';
  final PoseSession session;

  const PoseSessionPlayerScreen({super.key, required this.session});

  @override
  State<PoseSessionPlayerScreen> createState() =>
      _PoseSessionPlayerScreenState();
}

class _PoseSessionPlayerScreenState extends State<PoseSessionPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final path = widget.session.videoPath;
    if (path == null || !File(path).existsSync()) {
      setState(() => _error = 'Video file not found');
      return;
    }
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      controller.setLooping(true);
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
      await controller.play();
    } catch (e) {
      setState(() => _error = 'Failed to load video: $e');
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
      appBar: AppBar(title: Text('${widget.session.exercise} playback')),
      body: _error != null
          ? Center(child: Text(_error!))
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                    const SizedBox(height: 12),
                    _buildMeta(),
                    const SizedBox(height: 12),
                    _buildControls(),
                  ],
                ),
    );
  }

  Widget _buildMeta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reps: ${widget.session.reps}'),
          Text(
              'Accuracy: ${(widget.session.accuracy * 100).toStringAsFixed(0)}%'),
          Text('Duration: ${widget.session.duration}s'),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final isPlaying = _controller?.value.isPlaying ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (_controller == null) return;
            if (isPlaying) {
              _controller!.pause();
            } else {
              _controller!.play();
            }
            setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.replay_10),
          onPressed: () async {
            if (_controller == null) return;
            final pos = await _controller!.position ?? Duration.zero;
            _controller!.seekTo(pos - const Duration(seconds: 10));
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed: () async {
            if (_controller == null) return;
            final pos = await _controller!.position ?? Duration.zero;
            _controller!.seekTo(pos + const Duration(seconds: 10));
          },
        ),
      ],
    );
  }
}
