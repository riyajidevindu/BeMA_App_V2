import 'dart:convert';
import 'dart:io';
import 'package:animated_background/animated_background.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/pose_coach/models/pose_session.dart';
import 'package:bema_application/features/pose_coach/services/key_frame_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class KeyFrameViewerScreen extends StatefulWidget {
  static const routePath = '/keyFrameViewer';
  final PoseSession session;

  const KeyFrameViewerScreen({super.key, required this.session});

  @override
  State<KeyFrameViewerScreen> createState() => _KeyFrameViewerScreenState();
}

class _KeyFrameViewerScreenState extends State<KeyFrameViewerScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  KeyFramePack? _keyFramePack;
  int _selectedRepIndex = 0;
  int _selectedFrameIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadKeyFrames();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadKeyFrames() async {
    final path = widget.session.videoPath;
    if (path == null) {
      setState(() {
        _error = 'No key frames found';
        _isLoading = false;
      });
      return;
    }

    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        setState(() {
          _error = 'Key frames directory not found';
          _isLoading = false;
        });
        return;
      }

      // Try to load from keyframes_metadata.json
      final metadataFile = File(p.join(path, 'keyframes_metadata.json'));
      if (await metadataFile.exists()) {
        final metadataJson = await metadataFile.readAsString();
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        _keyFramePack = KeyFramePack.fromJson(metadata);

        if (_keyFramePack!.keyFrames.isEmpty) {
          setState(() {
            _error = 'No key frames in pack';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        // Try loading frames directly from directory
        final frames = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
            .map((f) => f.path)
            .toList();
        frames.sort();

        if (frames.isEmpty) {
          setState(() {
            _error = 'No key frame images found';
            _isLoading = false;
          });
          return;
        }

        // Create a simple pack from found frames
        final keyFrames = frames.asMap().entries.map((entry) {
          return KeyFrame(
            phase: SquatPhase.standing,
            phaseName: 'Frame ${entry.key + 1}',
            imagePath: entry.value,
            kneeAngle: 0,
            accuracy: 0,
            timestamp: DateTime.now(),
            repNumber: 1,
          );
        }).toList();

        _keyFramePack = KeyFramePack(
          outputDir: path,
          keyFrames: keyFrames,
          exerciseType: widget.session.exercise,
          totalReps: widget.session.reps,
          averageAccuracy: widget.session.accuracy,
          recordedAt: widget.session.timestamp,
          durationSeconds: widget.session.duration,
        );

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading key frames: $e');
      setState(() {
        _error = 'Error loading key frames: $e';
        _isLoading = false;
      });
    }
  }

  List<KeyFrame> get _currentRepFrames {
    if (_keyFramePack == null) return [];
    final framesByRep = _keyFramePack!.framesByRep;
    final repNumbers = framesByRep.keys.toList();
    repNumbers.sort();
    if (_selectedRepIndex >= repNumbers.length) return [];
    return framesByRep[repNumbers[_selectedRepIndex]] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade100,
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            baseColor: Colors.white,
            spawnOpacity: 0.0,
            opacityChangeRate: 0.25,
            minOpacity: 0.1,
            maxOpacity: 0.4,
            spawnMinSpeed: 30.0,
            spawnMaxSpeed: 70.0,
            spawnMinRadius: 7.0,
            spawnMaxRadius: 15.0,
            particleCount: 50,
          ),
        ),
        vsync: this,
        child: SafeArea(
          child: Column(
            children: [
              const CustomAppBar(showBackButton: true),
              const SizedBox(height: 8),
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Frame Analysis',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.session.exercise} • ${widget.session.reps} reps • ${(widget.session.accuracy * 100).toInt()}% accuracy',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading key frames...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (_keyFramePack == null || _keyFramePack!.keyFrames.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No key frames captured',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildRepSelector(),
        const SizedBox(height: 8),
        Expanded(child: _buildFrameViewer()),
        _buildFrameInfo(),
        _buildThumbnailStrip(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRepSelector() {
    final framesByRep = _keyFramePack!.framesByRep;
    final repNumbers = framesByRep.keys.toList();
    repNumbers.sort();

    if (repNumbers.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: repNumbers.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedRepIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('Rep ${repNumbers[index]}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedRepIndex = index;
                  _selectedFrameIndex = 0;
                });
              },
              selectedColor: Colors.blue.shade200,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrameViewer() {
    final frames = _currentRepFrames;
    if (frames.isEmpty) {
      return const Center(child: Text('No frames for this rep'));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        child: PageView.builder(
          controller: _pageController,
          itemCount: frames.length,
          onPageChanged: (index) {
            setState(() => _selectedFrameIndex = index);
          },
          itemBuilder: (context, index) {
            final frame = frames[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(frame.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.grey.shade300,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image,
                            size: 64, color: Colors.grey.shade500),
                        const SizedBox(height: 8),
                        Text(
                          'Image not found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPhaseColor(frame.phase).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      frame.phaseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (index > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left,
                              color: Colors.white),
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                if (index < frames.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right,
                              color: Colors.white),
                        ),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrameInfo() {
    final frames = _currentRepFrames;
    if (frames.isEmpty || _selectedFrameIndex >= frames.length) {
      return const SizedBox.shrink();
    }

    final frame = frames[_selectedFrameIndex];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.straighten,
            label: 'Knee Angle',
            value: '${frame.kneeAngle.toStringAsFixed(0)}°',
          ),
          _buildInfoItem(
            icon: Icons.speed,
            label: 'Accuracy',
            value: '${(frame.accuracy * 100).toStringAsFixed(0)}%',
          ),
          _buildInfoItem(
            icon: Icons.format_list_numbered,
            label: 'Frame',
            value: '${_selectedFrameIndex + 1}/${frames.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailStrip() {
    final frames = _currentRepFrames;
    if (frames.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: frames.length,
        itemBuilder: (context, index) {
          final frame = frames[index];
          final isSelected = _selectedFrameIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFrameIndex = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.file(
                      File(frame.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey.shade300,
                        child: Icon(Icons.broken_image,
                            color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPhaseColor(frame.phase),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getPhaseColor(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return Colors.green;
      case SquatPhase.goingDown:
        return Colors.orange;
      case SquatPhase.bottomPosition:
        return Colors.blue;
      case SquatPhase.comingUp:
        return Colors.purple;
    }
  }
}
