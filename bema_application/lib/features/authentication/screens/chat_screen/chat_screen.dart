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
  final Map<int, AudioPlayer> _audioPlayers = {};
  final Map<int, bool> _isPlayingMap = {};
  final Map<int, Duration> _audioDurations = {};
  final Map<int, Duration> _audioPositions = {};

  Future<void> _sendTextMessage(BuildContext context) async {
    if (_controller.text.isNotEmpty) {
      final text = _controller.text;
      _controller.clear();
      setState(() {});
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendTextMessage(text);
    }
  }

  Future<void> _playAudio(Uint8List audioBytes, int messageId) async {
    if (_audioPlayers[messageId] == null) {
      _audioPlayers[messageId] = AudioPlayer();
    }

    final player = _audioPlayers[messageId]!;
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_audio_$messageId.mp3');
    await tempFile.writeAsBytes(audioBytes);

    try {
      await player.setFilePath(tempFile.path);
      player.play();
      _isPlayingMap[messageId] = true;

      player.durationStream.listen((duration) {
        setState(() {
          _audioDurations[messageId] = duration ?? Duration.zero;
        });
      });

      player.positionStream.listen((position) {
        setState(() {
          _audioPositions[messageId] = position;
          if (position >= _audioDurations[messageId]!) {
            _isPlayingMap[messageId] = false;
          }
        });
      });

      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlayingMap[messageId] = false;
          });
        }
      });
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Widget _buildVoiceMessageBubble(Uint8List audioBytes, int messageId) {
  final isPlaying = _isPlayingMap[messageId] ?? false;
  final audioDuration = _audioDurations[messageId] ?? Duration.zero;
  final audioPosition = _audioPositions[messageId] ?? Duration.zero;

  // If the duration is not yet loaded, load it when the widget is built
  if (audioDuration == Duration.zero) {
    _loadAudioDuration(audioBytes, messageId);
  }

  return Row(
    children: [
      IconButton(
        icon: Icon(
          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          color: const Color.fromARGB(255, 181, 18, 140),
          size: 28.0,
        ),
        onPressed: () async {
          if (isPlaying) {
            await _audioPlayers[messageId]?.pause();
            setState(() {
              _isPlayingMap[messageId] = false;
            });
          } else {
            await _playAudio(audioBytes, messageId);
          }
        },
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: audioDuration.inSeconds > 0
                  ? audioPosition.inSeconds / audioDuration.inSeconds
                  : 0.0,
              backgroundColor: Colors.grey.shade300,
              color: const Color.fromARGB(255, 221, 255, 68),
            ),
            const SizedBox(height: 4.0),
            Text(
              '${audioPosition.inMinutes}:${audioPosition.inSeconds.remainder(60).toString().padLeft(2, '0')} / '
              '${audioDuration.inMinutes}:${audioDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.black, fontSize: 12.0),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> _loadAudioDuration(Uint8List audioBytes, int messageId) async {
  if (_audioPlayers[messageId] == null) {
    _audioPlayers[messageId] = AudioPlayer();
  }

  final player = _audioPlayers[messageId]!;
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/temp_audio_$messageId.mp3');
  await tempFile.writeAsBytes(audioBytes);

  try {
    await player.setFilePath(tempFile.path);
    final duration = player.duration ?? Duration.zero;
    setState(() {
      _audioDurations[messageId] = duration;
    });
  } catch (e) {
    print("Error loading audio duration: $e");
  }
}

  Widget _buildChatBubble(ChatMessage message, bool isUser, int index) {
    final isVoiceMessage = message.audioBytes != null;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundImage: AssetImage('assets/logo.png'),
              radius: 20,
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
                 ? const Color.fromARGB(255, 70, 168, 195)
                  : const Color.fromARGB(255, 78, 166, 87),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16.0),
                topRight: const Radius.circular(16.0),
                bottomLeft: Radius.circular(isUser ? 16.0 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16.0),
              ),
            ),
            child: isVoiceMessage
                ? _buildVoiceMessageBubble(message.audioBytes!, index)
                : Text(
                    message.text ?? "",
                    style: const TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
           const Text('😊', style: TextStyle(fontSize: 20.0)),
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
        automaticallyImplyLeading: false,
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
                    return _buildChatBubble(message, isUser, index);
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
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }
}
