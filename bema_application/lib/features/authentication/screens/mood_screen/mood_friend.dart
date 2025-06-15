import 'dart:io';
import 'dart:typed_data';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import 'package:bema_application/features/authentication/screens/chat_screen/chat_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'custom_painters.dart'; // Import the custom painters
import 'model_selection_dialog.dart'; // Import the model selection dialog

class MoodFriend extends StatefulWidget {
  const MoodFriend({Key? key}) : super(key: key);

  @override
  State<MoodFriend> createState() => _MoodFriendState();
}

class _MoodFriendState extends State<MoodFriend> with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? recordingFilePath;
  bool _isRecording = false;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isModelRotating = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _bounceAnimationController;
  late Animation<double> _bounceAnimation;
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;
  
  String? _statusText; // Nullable to hide the cloud when null
  String? _selectedModelPath; // Path to the selected model

  @override
  void initState() {
    super.initState();
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(_bounceAnimationController);

    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveAnimationController);

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (_isPlaying) {
            _statusText = "Talking...";
            _waveAnimationController.repeat(reverse: true);
            _bounceAnimationController.repeat(reverse: true);
          } else {
            _waveAnimationController.stop();
            _bounceAnimationController.stop();
          }
        });
      }
    });

    _audioPlayer.positionStream.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;

          // Hide wave and cloud when playback completes
          if (_position >= _duration && _duration > Duration.zero) {
            _statusText = null;
            _waveAnimationController.stop();
          }
        });
      }
    });

    _audioPlayer.durationStream.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration ?? Duration.zero;
        });
      }
    });

    // Show the model selection dialog when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showModelSelectionDialog();
    });
  }

  void _showModelSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return ModelSelectionDialog(
          modelPaths: [
            'assets/girl.glb',
            'assets/white_cartoon_dog.glb',
            'assets/professor_einstein.glb',
          ],
          onModelSelected: (modelPath) {
            setState(() {
              _selectedModelPath = modelPath;
            });
          },
        );
      },
    );
  }

  Future<void> _sendAudioMessage(BuildContext context) async {
    if (recordingFilePath != null) {
      final file = File(recordingFilePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          setState(() {
            _isLoading = true;
            _isModelRotating = true;
            _statusText = "Thinking...";
          });
          await chatProvider.sendAudioMessage(bytes);
          setState(() {
            _isLoading = false;
            _isModelRotating = false;
            _statusText = null; // Hide cloud when done
          });

          if (chatProvider.messages.isNotEmpty) {
            var lastMessage = chatProvider.messages.first;
            if (lastMessage.audioBytes != null) {
              _playAudio(lastMessage.audioBytes!);
            }
          }
        }
      }
    }
  }

  Future<void> _playAudio(Uint8List audioBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_audio.mp3');
    await tempFile.writeAsBytes(audioBytes);
    await _audioPlayer.setFilePath(tempFile.path);
    _audioPlayer.play();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildSoundWave() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(100, 50),
          painter: ModernSoundWavePainter(_waveAnimation.value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 56), // Height of the AppBar
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_selectedModelPath != null)
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: ModelViewer(
                              backgroundColor: backgroundColor,
                              src: _selectedModelPath!,
                              alt: 'A 3D model',
                              ar: false,
                              autoRotate: _isModelRotating,
                              disableZoom: true,
                            ),
                          );
                        },
                      ),
                    if (_statusText != null) // Show the cloud only if text is present
                      Positioned(
                        top: 40,
                        left: MediaQuery.of(context).size.width * 0.4,
                        child: CustomPaint(
                          size: const Size(200, 100), // Increased size
                          painter: ThinkingCloudPainter(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                _statusText!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_isPlaying)
                      Positioned(
                        bottom: 50,
                        child: _buildSoundWave(),
                      ),
                  ],
                ),
              ),
              if (_isPlaying || _position > Duration.zero)
                Column(
                  children: [
                    Slider(
                      value: _position.inSeconds.toDouble(),
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        final position = Duration(seconds: value.toInt());
                        _audioPlayer.seek(position);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position)),
                          IconButton(
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                            onPressed: () {
                              if (_isPlaying) {
                                _audioPlayer.pause();
                              } else {
                                _audioPlayer.play();
                              }
                            },
                          ),
                          Text(_formatDuration(_duration)),
                        ],
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          IconButton(
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                            onPressed: () async {
                              if (_isRecording) {
                                String? filePath = await _audioRecorder.stop();
                                if (filePath != null) {
                                  setState(() {
                                    _isRecording = false;
                                    recordingFilePath = filePath;
                                    _statusText = "Thinking...";
                                  });
                                  await _sendAudioMessage(context);
                                }
                              } else {
                                if (await _audioRecorder.hasPermission()) {
                                  final Directory appDocDir = await getApplicationDocumentsDirectory();
                                  final String filePath = path.join(appDocDir.path, 'audio.wav');
                                  await _audioRecorder.start(const RecordConfig(), path: filePath);
                                  setState(() {
                                    _isRecording = true;
                                    recordingFilePath = filePath;
                                    _statusText = "Listening...";
                                  });
                                }
                              }
                            },
                            color: Colors.orangeAccent,
                            iconSize: 48,
                          ),
                          Text(
                            _isRecording ? "Tap to stop recording" : "Tap to ask question",
                            style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: backgroundColor,
              title: const CustomAppBar(),
              automaticallyImplyLeading: false, // Remove the default back arrow
            ),
          ),
          Positioned(
            top: 36,
            left: 25,
            child: Container(
              width: 40, // Adjust the width of the circle
              height: 40, // Adjust the height of the circle
              decoration: BoxDecoration(
                color: Colors.grey.shade300.withOpacity(0.5), // Transparent ash color background
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  context.go('/${RouteNames.bottomNavigationBarScreen}', extra: 0);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bounceAnimationController.dispose();
    _waveAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}