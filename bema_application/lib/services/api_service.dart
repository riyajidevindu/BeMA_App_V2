import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
 //final String baseUrl = "http://10.0.2.2:8000"; // For Emulator
 final String baseUrl = 'https://a0fa-101-2-191-32.ngrok-free.app'; //This is for when you run in physical device


  // Function to ask a question to the bot
  Future<Map<String, dynamic>?> askBotQuestion(String question) async {
    final response = await http.post(
      Uri.parse("$baseUrl/bot/"),
      headers: {"Content-Type": "application/json"},
     body: jsonEncode({
        "question": question,
        "format": "points",   // Custom parameter for point form, if supported
        "max_words": 75       // Custom parameter for word limit, if supported
      }),
    );

   if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if the response has an "answer" field
      if (data.containsKey("answer")) {
        String answer = data["answer"];

     // Limit the response to 75 words
      List<String> words = answer.split(" ");
      if (words.length > 75) {
        answer = words.take(75).join(" ") + "...";
      }

   // Use a regular expression to match numbered items and split accordingly
RegExp numberedPointPattern = RegExp(r'(?=\d+\.)');
List<String> points = answer.split(numberedPointPattern)
  .map((point) => point.trim())
  .where((point) => point.isNotEmpty)
  .toList();

// Reverse the list of points to display them in ascending order
points = points.reversed.toList();

// Return the list of points
return {"answer": points};

      }
    } else {
      print("Failed to get response: ${response.statusCode}");
    }
    return null;
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