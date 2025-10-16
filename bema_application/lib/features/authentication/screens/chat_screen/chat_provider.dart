import 'package:bema_application/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final ApiService _apiService = ApiService();
  bool _isBotTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isBotTyping => _isBotTyping;

  Future<void> sendTextMessage(String userInput) async {
    final userMessage = ChatMessage(
      user: ChatUser(id: 'user'),
      createdAt: DateTime.now(),
      text: userInput,
    );
    _messages.insert(0, userMessage);
    _isBotTyping = true;
    notifyListeners();

    var response = await _apiService.askBotQuestion(userInput);
    if (response != null && response.containsKey("answer")) {
      final answer = response["answer"];
      if (answer is List) {
        for (final part in answer) {
          _messages.insert(
              0,
              ChatMessage(
                user: ChatUser(id: 'bot'),
                createdAt: DateTime.now(),
                text: part,
              ));
        }
      } else if (answer is String) {
        _messages.insert(
            0,
            ChatMessage(
              user: ChatUser(id: 'bot'),
              createdAt: DateTime.now(),
              text: answer,
            ));
      }
    } else {
      _messages.insert(
          0,
          ChatMessage(
            user: ChatUser(id: 'bot'),
            createdAt: DateTime.now(),
            text: "Sorry, I couldn't process your request.",
          ));
    }

    _isBotTyping = false;
    notifyListeners();
  }
}
