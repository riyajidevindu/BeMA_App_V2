import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:animated_background/animated_background.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/pose_coach/models/pose_session.dart';
import 'package:bema_application/features/pose_coach/services/video_generation_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class PoseSessionPlayerScreen extends StatefulWidget {
  static const routePath = '/poseSessionPlayer';
  final PoseSession session;

  const PoseSessionPlayerScreen({super.key, required this.session});

  @override
  State<PoseSessionPlayerScreen> createState() =>
      _PoseSessionPlayerScreenState();
}

class _PoseSessionPlayerScreenState extends State<PoseSessionPlayerScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;

  // Frame-by-frame playback
  ProcessedWorkout? _processedWorkout;
  List<String> _framePaths = [];
  int _currentFrameIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  int _fps = 10;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final path = widget.session.videoPath;
    if (path == null) {
      setState(() => _error = 'No workout recording found');
      return;
    }

    try {
      // Check if it's a directory (processed frames) or a video file
      final dir = Directory(path);
      if (await dir.exists()) {
        // It's a processed workout directory with frames
        final metadataFile = File(p.join(path, 'workout_metadata.json'));
        if (await metadataFile.exists()) {
          final metadataJson = await metadataFile.readAsString();
          final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
          _processedWorkout = ProcessedWorkout.fromJson(metadata);
          _framePaths = _processedWorkout!.framePaths
              .where((f) => File(f).existsSync())
              .toList();
          _fps = _processedWorkout!.fps;

          if (_framePaths.isEmpty) {
            setState(() => _error = 'No frames found in recording');
            return;
          }

          setState(() {
            _isLoading = false;
          });
          _play();
        } else {
          // Try to load frames directly from directory
          final frames = dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
              .map((f) => f.path)
              .toList()
            ..sort();

          if (frames.isEmpty) {
            setState(() => _error = 'No frames found in recording');
            return;
          }

          _framePaths = frames;
          setState(() {
            _isLoading = false;
          });
          _play();
        }
      } else {
        // It's a file path - check if it's a video
        final file = File(path);
        if (await file.exists()) {
          setState(() => _error =
              'Video playback not supported. Use frame-based recordings.');
        } else {
          setState(() => _error = 'Recording not found');
        }
      }
    } catch (e) {
      setState(() => _error = 'Failed to load recording: $e');
    }
  }

  void _play() {
    if (_framePaths.isEmpty) return;

    setState(() => _isPlaying = true);
    _playbackTimer?.cancel();

    final frameDuration = Duration(milliseconds: (1000 / _fps).round());
    _playbackTimer = Timer.periodic(frameDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentFrameIndex++;
        if (_currentFrameIndex >= _framePaths.length) {
          _currentFrameIndex = 0; // Loop
        }
      });
    });
  }

  void _pause() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _seekTo(int frameIndex) {
    setState(() {
      _currentFrameIndex = frameIndex.clamp(0, _framePaths.length - 1);
    });
  }

  void _skipForward() {
    _seekTo(_currentFrameIndex + (_fps * 2)); // Skip 2 seconds
  }

  void _skipBackward() {
    _seekTo(_currentFrameIndex - (_fps * 2)); // Back 2 seconds
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade100,
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            spawnMaxRadius: 50,
            spawnMinSpeed: 10.00,
            particleCount: 68,
            spawnMaxSpeed: 50,
            minOpacity: 0.3,
            spawnOpacity: 0.4,
            baseColor: Colors.lightBlue,
          ),
        ),
        vsync: this,
        child: SafeArea(
          child: Column(
            children: [
              const CustomAppBar(showBackButton: true),
              // Title below the app bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  widget.session.exercise,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading workout recording...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Frame Display Card
          _buildFrameDisplay(),
          const SizedBox(height: 16),

          // Progress Slider
          _buildProgressBar(),
          const SizedBox(height: 16),

          // Playback Controls
          _buildControls(),
          const SizedBox(height: 16),

          // Legend
          _buildLegend(),
          const SizedBox(height: 24),

          // Session Stats Card
          _buildStatsCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFrameDisplay() {
    if (_framePaths.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No frames available'),
        ),
      );
    }

    final currentPath = _framePaths[_currentFrameIndex];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(currentPath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final totalFrames = _framePaths.length;
    final currentSeconds = (_currentFrameIndex / _fps);
    final totalSeconds = (totalFrames / _fps);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue.shade700,
            inactiveTrackColor: Colors.blue.shade200,
            thumbColor: Colors.blue.shade700,
            overlayColor: Colors.blue.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: _currentFrameIndex.toDouble(),
            max: (totalFrames - 1).toDouble().clamp(0, double.infinity),
            onChanged: (value) {
              _pause();
              _seekTo(value.toInt());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(
                    Duration(milliseconds: (currentSeconds * 1000).toInt())),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
              Text(
                'Frame ${_currentFrameIndex + 1}/${totalFrames}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
              Text(
                _formatDuration(
                    Duration(milliseconds: (totalSeconds * 1000).toInt())),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back 2 seconds
          IconButton(
            icon: const Icon(Icons.replay_10, size: 32),
            color: Colors.blue.shade700,
            onPressed: _skipBackward,
          ),
          const SizedBox(width: 16),

          // Play/Pause
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 36,
                color: Colors.white,
              ),
              onPressed: _togglePlayPause,
            ),
          ),
          const SizedBox(width: 16),

          // Forward 2 seconds
          IconButton(
            icon: const Icon(Icons.forward_10, size: 32),
            color: Colors.blue.shade700,
            onPressed: _skipForward,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Your Movement', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 24),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Correct Form', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Session Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildStatRow(
            icon: Icons.fitness_center,
            label: 'Exercise',
            value: widget.session.exercise,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.repeat,
            label: 'Reps Completed',
            value: '${widget.session.reps}',
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.check_circle,
            label: 'Accuracy',
            value: '${(widget.session.accuracy * 100).toStringAsFixed(0)}%',
            valueColor: _getAccuracyColor(widget.session.accuracy),
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.timer,
            label: 'Duration',
            value: '${widget.session.duration}s',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
