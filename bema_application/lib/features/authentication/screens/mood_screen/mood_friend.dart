import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import 'package:bema_application/services/api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
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
  final FlutterTts _flutterTts = FlutterTts();
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
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;
  late AnimationController _thinkingAnimationController;
  late Animation<double> _thinkingAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  String? _statusText; // Nullable to hide the cloud when null
  String? _selectedModelPath; // Path to the selected model
  String _characterName = ""; // Store character name for personalization
  bool _showNextQuestionPrompt = false; // Show prompt after audio finishes

  // Fallback messages for different scenarios
  final List<String> _connectionIssueMessages = [
    "Oops! I seem to have lost my train of thought for a moment.",
    "My mind wandered off briefly, could you ask that again?",
    "I got a bit distracted there! What were you saying?",
    "Sorry, I was daydreaming! Could you repeat that?",
  ];

  final List<String> _noResponseMessages = [
    "I'm not quite sure how to respond to that. Try asking something else!",
    "That's a tricky one! Could you rephrase your question?",
    "I need a bit more clarity. Can you ask that differently?",
    "Hmm, I'm drawing a blank on that one. Ask me something else!",
  ];

  @override
  void initState() {
    super.initState();

    // Bounce animation for talking
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation =
        Tween<double>(begin: 0, end: 10).animate(_bounceAnimationController);

    // Wave animation for sound visualization
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveAnimation =
        Tween<double>(begin: 0, end: 1).animate(_waveAnimationController);

    // Breathing animation for idle state
    _breathingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _breathingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _breathingAnimationController.repeat(reverse: true);

    // Thinking animation (rotation)
    _thinkingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _thinkingAnimation =
        Tween<double>(begin: 0, end: 1).animate(_thinkingAnimationController);

    // Pulse animation for mic button
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (_isPlaying) {
            _statusText = "Talking...";
            _showNextQuestionPrompt = false;
            _waveAnimationController.repeat(reverse: true);
            _bounceAnimationController.repeat(reverse: true);
          } else {
            _waveAnimationController.stop();
            _bounceAnimationController.stop();
            // Show next question prompt when audio finishes
            if (_position >= _duration && _duration > Duration.zero) {
              _statusText = null;
              _showNextQuestionPrompt = true;
            }
          }
        });
      }
    });

    _audioPlayer.positionStream.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
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
      barrierDismissible:
          false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return ModelSelectionDialog(
          modelPaths: [
            'assets/girl.glb',
            'assets/white_cartoon_dog.glb',
          ],
          onModelSelected: (modelPath) {
            setState(() {
              _selectedModelPath = modelPath;
              // Set character name based on model
              if (modelPath.contains('girl.glb')) {
                _characterName = 'Ema';
              } else if (modelPath.contains('white_cartoon_dog.glb')) {
                _characterName = 'BeMA Puppy';
              }
            });
          },
        );
      },
    ).then((value) {
      // If dialog is closed without selecting a character, go back to relax section
      if (_selectedModelPath == null) {
        Navigator.of(context).pop(); // Go back to the intermediate screen
      }
    });
  }

  Future<void> _sendAudioMessage(BuildContext context) async {
    if (recordingFilePath != null) {
      final file = File(recordingFilePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          setState(() {
            _isLoading = true;
            _isModelRotating = true;
            _statusText = "Thinking...";
          });

          // Start thinking animation
          _thinkingAnimationController.repeat();

          try {
            // Call the API to get text response
            final apiService = ApiService();
            final baseUrl = apiService.baseUrl;

            var request = http.MultipartRequest(
              'POST',
              Uri.parse("$baseUrl/api/voice/"),
            );

            request.files.add(http.MultipartFile.fromBytes(
              'audio_file',
              bytes,
              filename: 'audio.wav',
            ));

            var streamedResponse = await request.send();
            var response = await http.Response.fromStream(streamedResponse);

            setState(() {
              _isLoading = false;
              _isModelRotating = false;
            });

            // Stop thinking animation
            _thinkingAnimationController.stop();

            if (response.statusCode == 200) {
              try {
                // Try to parse as JSON to extract answer
                final jsonResponse = json.decode(response.body);
                String answerText = "";

                // Extract only the answer field, not justification
                if (jsonResponse is Map && jsonResponse.containsKey('answer')) {
                  answerText = jsonResponse['answer'].toString();
                } else if (jsonResponse is String) {
                  answerText = jsonResponse;
                } else {
                  // If response format is unexpected, use the whole response
                  answerText = response.body;
                }

                // Remove the word "Answer:" if it appears at the beginning
                answerText = answerText.replaceFirst(
                    RegExp(r'^answer:\s*', caseSensitive: false), '');

                if (answerText.isNotEmpty) {
                  // Speak only the answer using TTS
                  await _speakAnswer(answerText);
                } else {
                  await _speakFallbackMessage(_noResponseMessages);
                }
              } catch (e) {
                // If JSON parsing fails, try to use as audio
                print("Not JSON response, trying as audio: $e");
                final audioBytes = response.bodyBytes;
                if (audioBytes.isNotEmpty) {
                  await _playAudio(audioBytes);
                } else {
                  await _speakFallbackMessage(_noResponseMessages);
                }
              }
            } else {
              // Use fallback message instead of "No response"
              await _speakFallbackMessage(_noResponseMessages);
            }
          } catch (e) {
            print("Error sending audio: $e");
            setState(() {
              _isLoading = false;
              _isModelRotating = false;
            });

            // Stop thinking animation
            _thinkingAnimationController.stop();

            // Use fallback message that sounds like character is distracted
            await _speakFallbackMessage(_connectionIssueMessages);
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

  Future<void> _speakAnswer(String answerText) async {
    setState(() {
      _statusText = "Talking...";
    });

    // Configure TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _statusText = null;
          _showNextQuestionPrompt = true;
          _isPlaying = false;
        });
        _waveAnimationController.stop();
        _bounceAnimationController.stop();
      }
    });

    // Start TTS and animations
    setState(() {
      _isPlaying = true;
    });
    _waveAnimationController.repeat(reverse: true);
    _bounceAnimationController.repeat(reverse: true);

    // Speak the answer
    await _flutterTts.speak(answerText);
  }

  Future<void> _speakFallbackMessage(List<String> messages) async {
    // Pick a random message from the list
    final random = math.Random();
    final message = messages[random.nextInt(messages.length)];

    setState(() {
      _statusText = message;
    });

    // Configure TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _statusText = null;
          _showNextQuestionPrompt = true;
          _isPlaying = false;
        });
        _waveAnimationController.stop();
        _bounceAnimationController.stop();
      }
    });

    // Start TTS and animations
    setState(() {
      _isPlaying = true;
    });
    _waveAnimationController.repeat(reverse: true);
    _bounceAnimationController.repeat(reverse: true);

    // Speak the message
    await _flutterTts.speak(message);
  }

  // Build floating bubble background effect like home screen
  List<Widget> _buildFloatingBubbles() {
    return List.generate(8, (index) {
      final random = math.Random(index);
      final size = 100.0 + random.nextDouble() * 150;
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 800;

      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _breathingAnimationController,
          builder: (context, child) {
            final scale = 1.0 + (_breathingAnimationController.value * 0.1);
            return Transform.scale(
              scale: scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
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
    final mediaQuery = MediaQuery.of(context);
    final safeArea = mediaQuery.padding;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Gradient background with bubble effect like home screen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor,
                  Colors.white,
                  backgroundColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Floating bubbles background effect
          ..._buildFloatingBubbles(),

          Column(
            children: [
              SizedBox(height: safeArea.top + 56), // Safe area + AppBar height

              // Character name header
              if (_selectedModelPath != null && _characterName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0098FF), Color(0xFF00C6FF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0098FF).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chatting with $_characterName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 3D Model with animations
                    if (_selectedModelPath != null)
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _bounceAnimation,
                          _breathingAnimation,
                          _thinkingAnimation,
                        ]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isPlaying || _isRecording
                                ? 1.0
                                : _breathingAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _bounceAnimation.value),
                              child: Transform.rotate(
                                angle: _isLoading
                                    ? _thinkingAnimation.value * 0.2 - 0.1
                                    : 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isPlaying
                                            ? primaryColor.withOpacity(0.5)
                                            : Colors.black.withOpacity(0.1),
                                        blurRadius: _isPlaying ? 40 : 20,
                                        spreadRadius: _isPlaying ? 10 : 5,
                                      ),
                                    ],
                                  ),
                                  child: ModelViewer(
                                    backgroundColor: Colors.transparent,
                                    src: _selectedModelPath!,
                                    alt: 'A 3D model',
                                    ar: false,
                                    autoRotate: _isModelRotating,
                                    disableZoom: true,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Modern status bubble
                    if (_statusText != null)
                      Positioned(
                        top: 20,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      backgroundColor.withOpacity(0.9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isLoading)
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin:
                                            const EdgeInsets.only(right: 12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            primaryColor,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      _statusText!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Enhanced sound wave visualization (positioned higher to not cover character)
                    if (_isPlaying)
                      Positioned(
                        bottom: 140,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🔊 Speaking...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0098FF),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildSoundWave(),
                            ],
                          ),
                        ),
                      ),

                    // Thinking indicator with animated dots
                    if (_isLoading && !_isRecording)
                      Positioned(
                        bottom: 100,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_characterName is thinking',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildThinkingDots(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Modern audio controls - only show when actively playing
              if (_isPlaying)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: primaryColor.withOpacity(0.2),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withOpacity(0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _position.inSeconds.toDouble(),
                          min: 0,
                          max: _duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            final position = Duration(seconds: value.toInt());
                            _audioPlayer.seek(position);
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  const Color(0xFF00C6FF),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_isPlaying) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.play();
                                }
                              },
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Next question prompt after audio finishes
              if (_showNextQuestionPrompt && !_isRecording && !_isLoading)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                backgroundColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.15),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Got another question for $_characterName?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Modern mic button
              Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 10.0,
                  bottom: safeArea.bottom + 20.0, // Safe area at bottom
                ),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRecording ? _pulseAnimation.value : 1.0,
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () async {
                                    if (_isRecording) {
                                      _pulseAnimationController.stop();
                                      String? filePath =
                                          await _audioRecorder.stop();
                                      if (filePath != null) {
                                        setState(() {
                                          _isRecording = false;
                                          recordingFilePath = filePath;
                                        });
                                        await _sendAudioMessage(context);
                                      }
                                    } else {
                                      if (await _audioRecorder
                                          .hasPermission()) {
                                        final Directory appDocDir =
                                            await getApplicationDocumentsDirectory();
                                        final String filePath = path.join(
                                            appDocDir.path, 'audio.wav');
                                        await _audioRecorder.start(
                                          const RecordConfig(
                                            encoder: AudioEncoder.wav,
                                            bitRate: 128000,
                                            sampleRate: 44100,
                                          ),
                                          path: filePath,
                                        );
                                        setState(() {
                                          _isRecording = true;
                                          recordingFilePath = filePath;
                                          _statusText = "Listening...";
                                          _showNextQuestionPrompt =
                                              false; // Hide prompt when starting recording
                                        });
                                        _pulseAnimationController.repeat(
                                            reverse: true);
                                      }
                                    }
                                  },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isRecording
                                      ? [Colors.red, Colors.redAccent]
                                      : _isLoading
                                          ? [Colors.grey, Colors.grey.shade400]
                                          : [
                                              primaryColor,
                                              const Color(0xFF00C6FF)
                                            ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _isRecording
                                        ? Colors.red.withOpacity(0.5)
                                        : primaryColor.withOpacity(0.5),
                                    blurRadius: _isRecording ? 25 : 20,
                                    spreadRadius: _isRecording ? 8 : 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isRecording
                                    ? Icons.stop_rounded
                                    : _isLoading
                                        ? Icons.hourglass_empty
                                        : Icons.mic,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRecording
                          ? "🎤 Recording... Tap to stop"
                          : _isLoading
                              ? "⏳ Processing your message..."
                              : "💬 Tap to ask $_characterName a question",
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildRecordingIndicator(),
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
                color: Colors.grey.shade300
                    .withOpacity(0.5), // Transparent ash color background
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for thinking dots animation
  Widget _buildThinkingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + (index * 200)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(value),
                shape: BoxShape.circle,
              ),
            );
          },
          onEnd: () {
            // Loop animation
          },
        );
      }),
    );
  }

  // Helper widget for recording indicator
  Widget _buildRecordingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: 20 * value,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
          onEnd: () {
            // This creates a continuous animation effect
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    _bounceAnimationController.dispose();
    _waveAnimationController.dispose();
    _breathingAnimationController.dispose();
    _thinkingAnimationController.dispose();
    _pulseAnimationController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
