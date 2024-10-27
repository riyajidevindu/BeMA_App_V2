import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_message.dart';
import 'package:bema_application/services/service.dart';
import 'package:flutter/material.dart';
import 'package:bema_application/services/api_service.dart';
// import 'package:flutter_emoji_picker/flutter_emoji_picker.dart'; // Add emoji picker

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ApiService apiService  = ApiService();

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    // Create user message
    ChatMessage newMessage = ChatMessage(text: _controller.text, sender: "user");
    setState(() {
      _messages.insert(0, newMessage);
    });

    String userInput = _controller.text;
    _controller.clear();

      // Send to FastAPI backend and get response
    final response = await apiService.askBotQuestion(userInput);

     // Check for null to handle errors
    if (response != null && response.containsKey("answer")) {
      // Create AI response
      ChatMessage aiMessage = ChatMessage(text: response["answer"], sender: "AI");
      setState(() {
        _messages.insert(0, aiMessage);
      });
    } else {
      print("Failed to get response from server.");
    }
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.emoji_emotions, color: Colors.orangeAccent),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _controller,
                onSubmitted: (value) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: "Type Your Message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 20.0,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Color.fromARGB(255, 5, 7, 7)),
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            padding: const EdgeInsets.all(10.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
           const Text(
               '😊', // User emoji
                style: TextStyle(fontSize: 20.0), // Adjust size as needed
                 ),
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
                Flexible(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(10.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      bool isUser = _messages[index].sender == "user";
                      return _buildChatBubble(_messages[index], isUser);
                    },
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: primaryColor,
                  ),
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
