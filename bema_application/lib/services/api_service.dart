import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  //final String baseUrl = "http://192.168.1.3:8000"; // For Emulator
  final String baseUrl = 'https://2f4a-123-231-105-70.ngrok-free.app'; //This is for when you run in physical device

  // Function to ask a question to the bot
  Future<Map<String, dynamic>?> askBotQuestion(String question) async {
    final response = await http.post(
      Uri.parse("$baseUrl/bot/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "question": question,
        "format": "points", // Custom parameter for point form, if supported
        "max_words": 75 // Custom parameter for word limit, if supported
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
          answer = "${words.take(75).join(" ")}...";
        }

        // Use a regular expression to match numbered items and split accordingly
        RegExp numberedPointPattern = RegExp(r'(?=\d+\.)');
        List<String> points = answer
            .split(numberedPointPattern)
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

  Future<Uint8List?> sendAudioAndGetResponse(Uint8List audioData) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/voice/"));

      // Add the audio file to the request
      request.files.add(http.MultipartFile.fromBytes(
        'audio_file',
        audioData,
        filename: 'audio.wav',
      ));

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        // Return the audio response as Uint8List
        return response.bodyBytes;
      } else {
        print("Failed to get audio response: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error sending audio: $e");
      return null;
    }
  }

  // Function to send data to the agent endpoint
  Future<Map<String, dynamic>?> sendAgentData(
      Map<String, dynamic> agentData) async {
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
