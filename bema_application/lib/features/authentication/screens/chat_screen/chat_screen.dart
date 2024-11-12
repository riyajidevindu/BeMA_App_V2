import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'chat_provider.dart';
import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? recordingFilePath;
  bool _isRecording = false;

  Future<void> _sendTextMessage(BuildContext context) async {
    if (_controller.text.isNotEmpty) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendTextMessage(_controller.text);
      _controller.clear();
    }
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
          setState(() {
            recordingFilePath = null;
          });
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

  Widget _buildTextComposer(BuildContext context) {
    return Row(
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
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Type a message...",
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () => _sendTextMessage(context),
        ),
      ],
    );
  }

  Future<void> _playAudio(Uint8List audioBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_audio.mp3');
    await tempFile.writeAsBytes(audioBytes);
    await _audioPlayer.setFilePath(tempFile.path);
    await _audioPlayer.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ListView.builder(
                  reverse: true,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ChatMessage(
                      text: message.text,
                      sender: message.sender,
                      audioBytes: message.audioBytes,
                      isAudioMessage: message.isAudioMessage,
                      onPlay: message.audioBytes != null
                          ? () => _playAudio(message.audioBytes!)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          _buildTextComposer(context),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}