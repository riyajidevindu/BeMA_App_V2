import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // final String baseUrl = "http://127.0.0.1:8000"; //This is for Emiulator
  final String baseUrl = 'https://227b-112-135-73-195.ngrok-free.app'; //This is for when you run in physical device


  // Function to ask a question to the bot
  Future<Map<String, dynamic>?> askBotQuestion(String question) async {
    final response = await http.post(
      Uri.parse("$baseUrl/bot/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"question": question}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to get response: ${response.statusCode}");
      return null;
    }
  }

  // Function to send data to the agent endpoint
  Future<Map<String, dynamic>?> sendAgentData(Map<String, dynamic> agentData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/agent/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(agentData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to send data: ${response.statusCode}");
      return null;
    }
  }
}
