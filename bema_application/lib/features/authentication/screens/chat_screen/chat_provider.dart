import 'dart:typed_data';
import 'package:bema_application/services/api_service.dart';
import 'package:flutter/material.dart';
import 'chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final ApiService _apiService = ApiService();
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  Future<void> sendTextMessage(String userInput) async {
    ChatMessage userMessage = ChatMessage(text: userInput, sender: "user");
    _messages.insert(0, userMessage);
    _isTyping = true;
    notifyListeners();

    var response = await _apiService.askBotQuestion(userInput);
    if (response != null && response.containsKey("answer")) {
      _messages.insert(0, ChatMessage(text: response["answer"].join("\n"), sender: "AI"));
    } else {
      _messages.insert(0, ChatMessage(text: "Sorry, I couldn't process your request.", sender: "AI"));
    }

    _isTyping = false;
    notifyListeners();
  }

  Future<void> sendAudioMessage(Uint8List audioData) async {
    _messages.insert(0, ChatMessage(sender: "user", isAudioMessage: true));
    _isTyping = true;
    notifyListeners();

    Uint8List? audioResponse = await _apiService.sendAudioAndGetResponse(audioData);
    if (audioResponse != null) {
      _messages.insert(0, ChatMessage(sender: "AI", audioBytes: audioResponse));
    } else {
      _messages.insert(0, ChatMessage(text: "Sorry, I couldn't process your audio message.", sender: "AI"));
    }

    _isTyping = false;
    notifyListeners();
  }
}