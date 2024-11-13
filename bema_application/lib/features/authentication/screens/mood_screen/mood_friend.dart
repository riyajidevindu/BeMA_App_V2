import 'dart:io';
import 'dart:typed_data';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;

class MoodFriend extends StatefulWidget {
  const MoodFriend({Key? key}) : super(key: key);

  @override
  State<MoodFriend> createState() => _MoodFriendState();
}

class _MoodFriendState extends State<MoodFriend> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? recordingFilePath;
  bool _isRecording = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(_animationController);
  }

  Future<void> _sendAudioMessage(BuildContext context) async {
    if (recordingFilePath != null) {
      final file = File(recordingFilePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          print("Audio file size: ${bytes.length} bytes");
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          await chatProvider.sendAudioMessage(bytes);
          
          // Get the last message (which should be the AI's response)
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
    await _audioPlayer.play();
    _animationController.repeat(reverse: true);
    
    // Stop animation when audio finishes playing
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _animationController.stop();
        _animationController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Friend')),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
                  child: ModelViewer(
                    backgroundColor: Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
                    src: 'assets/white_cartoon_dog.glb',
                    alt: 'A 3D model of a dog',
                    ar: false,
                    autoRotate: true,
                    disableZoom: true,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: IconButton(
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
    _animationController.dispose();
    super.dispose();
  }
}