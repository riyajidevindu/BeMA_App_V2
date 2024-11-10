import 'package:flutter/material.dart';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_message.dart';
import 'package:bema_application/services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final ApiService apiService = ApiService();
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  // Method to set typing status
  void setIsTyping(bool isTyping) {
    _isTyping = isTyping;
    notifyListeners();
  }

  // Method to send a message and handle the response
  Future<void> sendMessage(String userInput) async {
    // Add user message to chat history
    ChatMessage userMessage = ChatMessage(text: userInput, sender: "user");
    _messages.insert(0, userMessage);
    setIsTyping(true); // Show typing indicator
    notifyListeners();

    // Fetch AI response from API
    final response = await apiService.askBotQuestion(userInput);

  // Check if response is not null and contains "answer" key
    if (response != null && response.containsKey("answer")) {
      List<String> points = List<String>.from(response["answer"]);

      // Insert each point as a separate message
      for (String point in points.reversed) {
        ChatMessage aiMessage = ChatMessage(text: point, sender: "AI");
        _messages.insert(0, aiMessage);
      }
    } else {
      print("Failed to get response from server.");
    }

    setIsTyping(false); // Hide typing indicator
    notifyListeners();
  }
}
