import 'package:bema_application/features/authentication/screens/login_screen.dart';
import 'package:bema_application/features/authentication/screens/signup_screen.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final goRouter = GoRouter(
  initialLocation: '/${RouteNames.registerScreen}',
  routes: [
    GoRoute(
      path: '/${RouteNames.registerScreen}',
      name: RouteNames.registerScreen,
      pageBuilder: (context, state) => const MaterialPage(
        child: SignupScreen(),
      ),
    ),
    GoRoute(
      path: '/${RouteNames.loginScreen}',
      name: RouteNames.loginScreen,
      pageBuilder: (context, state) => const MaterialPage(
        child: LoginScreen(),
      ),
    ),
  ]
);
