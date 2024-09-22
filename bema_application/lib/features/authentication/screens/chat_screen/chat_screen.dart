import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_message.dart';
import 'package:bema_application/services/service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = []; // This is the list that holds messages
  final OpenAIService openAIService = OpenAIService();

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;  // Prevent sending empty messages

    // Create a new message instance
    ChatMessage newMessage = ChatMessage(text: _controller.text, sender: "user");

    setState(() {
      _messages.insert(0, newMessage);  // Insert the new message at the start of the list
    });

    String userInput = _controller.text;
    _controller.clear(); 
    
     // Call OpenAI API and get the response
    String openAIResponse = await openAIService.sendMessageToOpenAI(userInput); // Clear the input field after sending the message

     // Create a new message with the AI's response
    ChatMessage aiMessage = ChatMessage(text: openAIResponse, sender: "AI");

    setState(() {
      _messages.insert(0, aiMessage);  // Insert the AI's response into the chat
    });
    
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Row(
        children: [

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _controller,
                onSubmitted: (value) => _sendMessage(),
                decoration: 
                const InputDecoration.collapsed(
                    hintText: "Type Your Answer"),
              ),
            ),
          ),
          IconButton(onPressed: () => _sendMessage(), 
          icon: const Icon(Icons.send))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
                child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(3.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            )),
            Container(
              decoration: const BoxDecoration(
                color: primaryColor,
              ),
              child: _buildTextComposer(),
            )
          ],
        ),
      ),
    );
  }
}
