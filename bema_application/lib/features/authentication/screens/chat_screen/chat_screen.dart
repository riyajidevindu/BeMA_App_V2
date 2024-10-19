import 'package:flutter/material.dart';
import 'package:bema_application/common/config/colors.dart'; // Custom colors
import 'package:bema_application/common/widgets/app_bar.dart'; // Custom AppBar
import 'package:bema_application/features/authentication/screens/chat_screen/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Open emoji picker
            },
            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.orangeAccent, size: 28),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Type Your Message...",
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              // Trigger send message
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundImage: AssetImage('assets/logo.png'), // App icon for AI
              radius: 20,
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
              padding: const EdgeInsets.all(12.0),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser ? Colors.blueAccent.withOpacity(0.8) : Colors.greenAccent.withOpacity(0.7),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15.0),
                  topRight: const Radius.circular(15.0),
                  bottomLeft: isUser ? const Radius.circular(15.0) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(15.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
            const Icon(Icons.person, color: Colors.blueAccent, size: 30), // User icon
          ],
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
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Chat ListView
                Expanded(
                  child: ListView.builder(
                    reverse: true, // Newest message at the bottom
                    padding: const EdgeInsets.all(10.0),
                    itemCount: 10, // Replace with _messages.length
                    itemBuilder: (context, index) {
                      // Replace with real data later
                      bool isUser = index % 2 == 0;
                      return _buildChatBubble(ChatMessage(text: "Sample message $index", sender: isUser ? "user" : "AI"), isUser);
                    },
                  ),
                ),
                // Message composer
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: _buildTextComposer(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
