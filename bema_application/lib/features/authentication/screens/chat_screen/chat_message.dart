import 'dart:typed_data';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    Key? key,
    this.text,
    required this.sender,
    this.audioBytes,
    this.isAudioMessage = false,
    this.onPlay,
  }) : super(key: key);

  final String? text;
  final String sender;
  final Uint8List? audioBytes;
  final bool isAudioMessage;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(sender),
      subtitle: _buildMessageContent(),
    );
  }

  Widget _buildMessageContent() {
    if (text != null && text!.isNotEmpty) {
      return Text(text!);
    } else if (isAudioMessage || audioBytes != null) {
      if (audioBytes != null) {
        return IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: onPlay,
        );
      } else {
        return Text('Audio message (processing...)');
      }
    } else {
      return Text('Unknown message type');
    }
  }
}