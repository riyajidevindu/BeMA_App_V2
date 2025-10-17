import 'dart:io';
import 'dart:convert';
import 'package:bema_application/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final ApiService _apiService = ApiService();
  bool _isBotTyping = false;
  String? _userEmotion;
  bool _isInitialized = false;

  List<ChatMessage> get messages => _messages;
  bool get isBotTyping => _isBotTyping;
  String? get userEmotion => _userEmotion;
  bool get isInitialized => _isInitialized;

  /// Initialize and load chat history from storage
  Future<void> loadChatHistory() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryJson = prefs.getString('chat_history');

      if (chatHistoryJson != null) {
        final List<dynamic> decodedList = json.decode(chatHistoryJson);
        _messages.clear();

        for (var messageData in decodedList) {
          final message = ChatMessage(
            user: ChatUser(
              id: messageData['userId'],
              firstName: messageData['userName'],
            ),
            createdAt: DateTime.parse(messageData['createdAt']),
            text: messageData['text'],
          );
          _messages.add(message);
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading chat history: $e');
      _isInitialized = true;
    }
  }

  /// Save chat history to storage
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final chatHistoryList = _messages.map((message) {
        return {
          'userId': message.user.id,
          'userName': message.user.firstName ?? '',
          'text': message.text,
          'createdAt': message.createdAt.toIso8601String(),
        };
      }).toList();

      await prefs.setString('chat_history', json.encode(chatHistoryList));
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  /// Clear all chat history
  Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      _messages.clear();
      _userEmotion = null;
      notifyListeners();
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  /// Set default emotion (used when user skips photo)
  void setDefaultEmotion() {
    _userEmotion = 'neutral';
    notifyListeners();
  }

  /// Detect emotion from user image
  Future<void> detectEmotion(File imageFile) async {
    try {
      final result = await _apiService.detectEmotion(imageFile);
      if (result != null && result.containsKey('result')) {
        _userEmotion = result['result'];
        notifyListeners();
      }
    } catch (e) {
      print('Error detecting emotion: $e');
      _userEmotion = 'neutral'; // Default fallback
      notifyListeners();
    }
  }

  Future<void> sendTextMessage(String userInput) async {
    final userMessage = ChatMessage(
      user: ChatUser(id: 'user'),
      createdAt: DateTime.now(),
      text: userInput,
    );
    _messages.insert(0, userMessage);
    _isBotTyping = true;
    notifyListeners();

    // Pass emotion along with the question
    var response = await _apiService.askBotQuestion(
      userInput,
      emotion: _userEmotion,
    );
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
            ),
          );
        }
      } else if (answer is String) {
        _messages.insert(
          0,
          ChatMessage(
            user: ChatUser(id: 'bot'),
            createdAt: DateTime.now(),
            text: answer,
          ),
        );
      }
    } else {
      _messages.insert(
        0,
        ChatMessage(
          user: ChatUser(id: 'bot'),
          createdAt: DateTime.now(),
          text: "Sorry, I couldn't process your request.",
        ),
      );
    }

    _isBotTyping = false;
    notifyListeners();

    // Save chat history after each message exchange
    await _saveChatHistory();
  }
}
