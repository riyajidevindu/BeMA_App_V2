import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/connectivity_checker.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:bema_application/routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bema_application/features/authentication/screens/chat_screen/chat_provider.dart';
import 'package:bema_application/features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Try to load .env but don't crash if the file is missing in release/builds
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(".env not found or failed to load: $e");
  }
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => QuestionnaireProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Perform any additional initialization here
    await Future.delayed(
        const Duration(seconds: 3)); // Simulate a delay for the splash screen
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityCheck(
      child: MaterialApp.router(
        title: 'BeMA',
        routerConfig: goRouter,
        theme: ThemeData(
          scaffoldBackgroundColor: backgroundColor,
          primaryColor: primaryColor,
        ),
        // Display the SplashScreen if not initialized; otherwise, load the main app
        builder: (context, child) =>
            _isInitialized ? child! : const SplashScreen(),
      ),
    );
  }
}
