import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_message.dart';
import 'package:bema_application/services/service.dart';
import 'package:flutter/material.dart';
import 'package:bema_application/services/api_service.dart';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_provider.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ApiService apiService = ApiService();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isTyping = false;

  late final AnimationController _sendButtonController;
  late final Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
    );

    _sendButtonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _sendButtonController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    if (_controller.text.isEmpty) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(_controller.text);
    _controller.clear();

    ChatMessage userMessage =
        ChatMessage(text: _controller.text, sender: "user");
    setState(() {
      _messages.insert(0, userMessage);
      _listKey.currentState?.insertItem(0);
      _isTyping = true; // Display typing indicator
    });

    String userInput = _controller.text;
    _controller.clear();

    final response = await apiService.askBotQuestion(userInput);

    if (response != null && response.containsKey("answer")) {
      ChatMessage aiMessage =
          ChatMessage(text: response["answer"], sender: "AI");
      setState(() {
        _messages.insert(0, aiMessage);
        _listKey.currentState?.insertItem(0);
      });
    } else {
      print("Failed to get response from server.");
    }

    setState(() {
      _isTyping = false; // Hide typing indicator
    });
  }

  Widget _buildTextComposer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.emoji_emotions, color: Colors.orangeAccent),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (text) {
                Provider.of<ChatProvider>(context, listen: false)
                    .setIsTyping(text.isNotEmpty);
              },
              onSubmitted: (value) => _sendMessage(context),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 30.0),
              ),
            ),
          ),
          ScaleTransition(
            scale: _sendButtonAnimation,
            child: IconButton(
              onPressed: () {
                _sendButtonController.forward().then((_) {
                  _sendButtonController.reverse();
                  _sendMessage(context);
                });
              },
              icon:
                  const Icon(Icons.send, color: Color.fromARGB(255, 4, 8, 17)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundImage: AssetImage('assets/logo.png'),
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
              color: isUser
                  ? const Color.fromARGB(255, 85, 194, 224)
                  : const Color.fromARGB(255, 157, 219, 162),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(isUser ? 15 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 15),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
            const Text('😊', style: TextStyle(fontSize: 20.0)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    bool isUser = message.sender == "user";
                    return _buildChatBubble(message, isUser);
                  },
                ),
              ),
              if (chatProvider.isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, bottom: 10.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/logo.png'),
                        radius: 15,
                      ),
                      const SizedBox(width: 8.0),
                      Text("typing...",
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                child: Container(
                  color: const Color.fromARGB(207, 4, 87, 231),
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: _buildTextComposer(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
