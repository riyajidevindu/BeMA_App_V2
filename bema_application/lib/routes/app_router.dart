import 'package:bema_application/features/authentication/screens/login_screen.dart';
import 'package:bema_application/features/authentication/screens/profile_screen.dart';
import 'package:bema_application/features/authentication/screens/question_screens/welcome_question_screen.dart';
import 'package:bema_application/features/authentication/screens/signup_screen.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_2.dart';
import 'package:bema_application/routes/authendication_wrapper.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final goRouter = GoRouter(initialLocation: '/${RouteNames.wrapper}', routes: [
  GoRoute(
    path: '/${RouteNames.wrapper}',
    name: RouteNames.wrapper,
    pageBuilder: (context, builder) => const MaterialPage(
      child: AuthenticationWrapper(),
    ),
  ),
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
  GoRoute(
    path: '/${RouteNames.userWelcomeScreen}',
    name: RouteNames.userWelcomeScreen,
    pageBuilder: (context, state) => MaterialPage(
      child: UserWelcomeScreen(),
    ),
  ),
  GoRoute(
      path: '/${RouteNames.profileScreen}',
      name: RouteNames.profileScreen,
      pageBuilder: (context, state) {
        return const MaterialPage(
          child: ProfileViewScreen(),
        );
      }),
  GoRoute(
    path: '/${RouteNames.questionScreen2}',
    name: RouteNames.questionScreen2,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen2(),
    ),
  ),
]);
