import 'dart:io';
import 'dart:typed_data';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  Future<void> _sendTextMessage(BuildContext context) async {
    if (_controller.text.isNotEmpty) {
      final text = _controller.text;
      _controller.clear();
      setState(() {});
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendTextMessage(text);
    }
  }

  Future<void> _playAudio(Uint8List audioBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_audio.mp3');
    await tempFile.writeAsBytes(audioBytes);

    try {
      await _audioPlayer.setFilePath(tempFile.path);
      _audioPlayer.play();
      _isPlayingAudio = true;

      _audioPlayer.durationStream.listen((duration) {
        setState(() {
          _audioDuration = duration ?? Duration.zero;
        });
      });

      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _audioPosition = position;
          if (position >= _audioDuration) {
            _isPlayingAudio = false;
          }
        });
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlayingAudio = false;
          });
        }
      });
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Widget _buildVoiceMessageBubble(Uint8List audioBytes) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isPlayingAudio
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: Colors.blueAccent,
            size: 28.0,
          ),
          onPressed: () async {
            if (_isPlayingAudio) {
              await _audioPlayer.pause();
              setState(() {
                _isPlayingAudio = false;
              });
            } else {
              await _playAudio(audioBytes);
            }
          },
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _audioDuration.inSeconds > 0
                    ? _audioPosition.inSeconds / _audioDuration.inSeconds
                    : 0.0,
                backgroundColor: Colors.grey.shade300,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 4.0),
              Text(
                '${_audioPosition.inMinutes}:${_audioPosition.inSeconds.remainder(60).toString().padLeft(2, '0')} / '
                '${_audioDuration.inMinutes}:${_audioDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.black, fontSize: 12.0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isUser) {
    final isVoiceMessage = message.audioBytes != null;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.android, color: Colors.white),
            ),
            const SizedBox(width: 8.0),
          ],
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color.fromARGB(255, 68, 153, 222)
                  : const Color.fromARGB(255, 98, 164, 31),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16.0),
                topRight: const Radius.circular(16.0),
                bottomLeft: Radius.circular(isUser ? 16.0 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16.0),
              ),
            ),
            child: isVoiceMessage
                ? _buildVoiceMessageBubble(message.audioBytes!)
                : Text(
                    message.text ?? "",
                    style: const TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextComposer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 117, 209, 105),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendTextMessage(context),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          CircleAvatar(
            radius: 24.0,
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendTextMessage(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: backgroundColor, // Use background color from theme
      appBar: AppBar(
        backgroundColor: backgroundColor, // Consistent background color
        title: const CustomAppBar(), // Custom AppBar from previous screen
      ),
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
                    final isUser = message.sender == "user";
                    return _buildChatBubble(message, isUser);
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
    super.dispose();
  }
}
