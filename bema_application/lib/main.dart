import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';
import 'package:bema_application/routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bema_application/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file before initializing Firebase
 await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthenticationProvider()), // Authentication
        ChangeNotifierProvider(
            create: (_) =>
                QuestionnaireProvider()), // Add QuestionnaireProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BeMA',
      routerConfig: goRouter, // Your GoRouter configuration
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: primaryColor,
      ),
    );
  }
}
