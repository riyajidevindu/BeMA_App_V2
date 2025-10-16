import 'package:animated_background/animated_background.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'chat_provider.dart';
import 'package:bema_application/common/config/colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false,
      ),
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            baseColor: Colors.blue,
            spawnOpacity: 0.0,
            opacityChangeRate: 0.25,
            minOpacity: 0.1,
            maxOpacity: 0.4,
            spawnMinSpeed: 30.0,
            spawnMaxSpeed: 70.0,
            spawnMinRadius: 7.0,
            spawnMaxRadius: 15.0,
            particleCount: 50,
          ),
        ),
        vsync: this,
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DashChat(
                currentUser: ChatUser(id: 'user', firstName: 'You'),
                onSend: (ChatMessage message) {
                chatProvider.sendTextMessage(message.text);
              },
              messages: chatProvider.messages.map((m) {
                return ChatMessage(
                  user: m.user.id == 'user'
                      ? ChatUser(id: 'user', firstName: 'You')
                      : ChatUser(
                          id: 'bot',
                          firstName: 'BEMA',
                          profileImage: 'assets/logo.png',
                        ),
                  createdAt: m.createdAt,
                  text: m.text ?? '',
                );
              }).toList(),
              typingUsers: chatProvider.isBotTyping
                  ? [
                      ChatUser(
                        id: 'bot',
                        firstName: 'BEMA',
                        profileImage: 'assets/logo.png',
                      )
                    ]
                  : [],
              messageOptions: MessageOptions(
                currentUserContainerColor: Colors.lightBlueAccent,
                containerColor: Colors.white,
                textColor: Colors.black,
              ),
              inputOptions: InputOptions(
                inputDecoration: InputDecoration(
                  hintText: 'Ask from BeMA...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            );
          },
        ),
      ),
    );
  }
}
