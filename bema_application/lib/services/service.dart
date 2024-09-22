import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> sendMessageToOpenAI(String userInput) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",  // or the model you're using
        "messages": [
          {"role": "user", "content": userInput}
        ],
        "max_tokens": 150,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final generatedText = responseBody['choices'][0]['message']['content'];
      return generatedText;
    } else {
      throw Exception('Failed to load OpenAI response');
    }
  }
}
