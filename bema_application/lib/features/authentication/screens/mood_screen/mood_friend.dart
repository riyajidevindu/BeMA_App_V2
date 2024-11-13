import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
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
            _waveAnimationController.repeat(reverse: true);
            _bounceAnimationController.repeat(reverse: true);
          } else {
            _waveAnimationController.stop();
            _bounceAnimationController.stop();
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

    _audioPlayer.positionStream.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  Future<void> _sendAudioMessage(BuildContext context) async {
    if (recordingFilePath != null) {
      final file = File(recordingFilePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          print("Audio file size: ${bytes.length} bytes");
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          setState(() {
            _isLoading = true;
            _isModelRotating = true;
          });
          await chatProvider.sendAudioMessage(bytes);
          setState(() {
            _isLoading = false;
            _isModelRotating = false;
          });

          if (chatProvider.messages.isNotEmpty) {
            var lastMessage = chatProvider.messages.first;
            if (lastMessage.audioBytes != null) {
              _playAudio(lastMessage.audioBytes!);
            }
          }
        } else {
          print("Error: Audio file is empty");
        }
      } else {
        print("Error: Audio file does not exist at path: $recordingFilePath");
      }
    } else {
      print("Error: recordingFilePath is null");
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
          size: Size(100, 50),
          painter: SoundWavePainter(_waveAnimation.value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Friend'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/${RouteNames.homeScreen}');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: ModelViewer(
                        backgroundColor: Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
                        src: 'assets/white_cartoon_dog.glb',
                        alt: 'A 3D model of a dog',
                        ar: false,
                        autoRotate: _isModelRotating,
                        disableZoom: true,
                      ),
                    );
                  },
                ),
                if (_isPlaying)
                  Positioned(
                    bottom: 50, // Adjust this value to position the wave near the dog's mouth
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
                ? CircularProgressIndicator()
                : IconButton(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    onPressed: () async {
                      if (_isRecording) {
                        String? filePath = await _audioRecorder.stop();
                        if (filePath != null) {
                          setState(() {
                            _isRecording = false;
                            recordingFilePath = filePath;
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
                          });
                        }
                      }
                    },
                    color: Colors.orangeAccent,
                    iconSize: 48,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _bounceAnimationController.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }
}

class SoundWavePainter extends CustomPainter {
  final double animationValue;

  SoundWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(0, height / 2);

    for (double i = 0; i < width; i++) {
      path.lineTo(
        i, 
        height / 2 + sin((i / width * 2 * pi + animationValue * 2 * pi) * 2) * height / 4
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}