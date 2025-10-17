import 'dart:io';
import 'package:animated_background/animated_background.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'chat_provider.dart';
import 'package:bema_application/common/config/colors.dart';
import 'camera_capture_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // Show emotion detection dialog when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showEmotionDetectionDialog();
    });
  }

  Future<void> _showEmotionDetectionDialog() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Always show dialog every time user enters chat screen
    // Remove the check so it shows even if emotion was previously detected

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.photo_camera, color: primaryColor),
            const SizedBox(width: 10),
            const Text('Emotion Detection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'To provide you with better support, please take a selfie so we can understand your current emotional state.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/logo.png',
              height: 100,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Set default emotion when skipped
              chatProvider.setDefaultEmotion();
            },
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Close dialog first, then open camera
              Navigator.pop(context);
              // Small delay to ensure dialog is fully closed
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) {
                _captureImage();
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      // Open custom in-app camera
      final File? imageFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraCaptureScreen(),
        ),
      );

      if (imageFile != null && mounted) {
        // Detect emotion in background (non-blocking)
        // User can start chatting immediately with default emotion
        chatProvider.detectEmotion(imageFile).then((_) {
          // Emotion detected successfully - no notification needed
        }).catchError((e) {
          // Error detecting emotion - silently fallback to default
        });
      } else {
        // User cancelled camera, set default emotion
        chatProvider.setDefaultEmotion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Set default emotion on error
        chatProvider.setDefaultEmotion();
      }
    }
  }

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
                    text: m.text,
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
