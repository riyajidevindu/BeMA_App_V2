import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
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
    final text = _controller.text;  // Save the text to send
    _controller.clear();  // Clear the text field immediately

    // Trigger a UI update to show the cleared text field
    setState(() {});

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendTextMessage(text);  // Send the message in the background
  }
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
              ),
            ),
          ),
          const SizedBox(width: 8.0), // Space between text field and send button
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

  Future<void> _playAudio(Uint8List audioBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_audio.mp3');
    await tempFile.writeAsBytes(audioBytes);
    await _audioPlayer.setFilePath(tempFile.path);
    await _audioPlayer.play();
  }

  Widget _buildChatBubble(ChatMessage message, bool isUser) {
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
              color: isUser ? Colors.blueAccent : Colors.greenAccent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16.0),
                topRight: const Radius.circular(16.0),
                bottomLeft: Radius.circular(isUser ? 16.0 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16.0),
              ),
            ),
          child: Text(
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
    _audioRecorder.dispose();
    super.dispose();
  }
}
