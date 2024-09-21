import 'package:bema_application/features/authentication/screens/login_screen.dart';
import 'package:bema_application/features/authentication/screens/profile_screen.dart';
import 'package:bema_application/features/authentication/screens/question_screens/welcome_question_screen.dart';
import 'package:bema_application/features/authentication/screens/signup_screen.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_2.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_4.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_5.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_6.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_7.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_8.dart';
import 'package:bema_application/routes/authendication_wrapper.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final goRouter = GoRouter(
   initialLocation: '/${RouteNames.wrapper}',
  routes: [
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
      pageBuilder: (context, state) => const MaterialPage(
        child: UserWelcomeScreen(),
      ),
    ),
      GoRoute(
        path: '/${RouteNames.profileScreen}',
        name: RouteNames.profileScreen,
        pageBuilder: (context, state) => const MaterialPage(
            child: ProfileViewScreen(),
          ),
      ),
       GoRoute(
        path: '/${RouteNames.questionScreen2}',
        name: RouteNames.questionScreen2,
        pageBuilder: (context, state) => const MaterialPage(
          child: QuestionScreen2(),
        ),
      ),
      GoRoute(
        path: '/${RouteNames.questionScreen4}',
        name: RouteNames.questionScreen4,
        pageBuilder: (context, state) => const MaterialPage(
          child: QuestionScreen4(),
        ),
      ),
      GoRoute(
        path: '/${RouteNames.questionScreen5}',
        name: RouteNames.questionScreen5,
        pageBuilder: (context, state) => const MaterialPage(
          child: QuestionScreen5(),
        ),
      ),
      GoRoute(
        path: '/${RouteNames.questionScreen6}',
        name: RouteNames.questionScreen6,
        pageBuilder: (context, state) => const MaterialPage(
          child: QuestionScreen6(),
        ),
      ),
      GoRoute(
        path: '/${RouteNames.questionScreen7}',
        name: RouteNames.questionScreen7,
        pageBuilder: (context, state) => const MaterialPage(
          child: QuestionScreen7(),
        ),
      ),
      GoRoute(
        path: '/${RouteNames.questionScreen8}',
        name: RouteNames.questionScreen8,
        pageBuilder: (context, state) => const MaterialPage(
          child: QuestionScreen8(),
        ),
      ),
// final goRouter = GoRouter(initialLocation: '/${RouteNames.wrapper}', routes: [
//   GoRoute(
//     path: '/${RouteNames.wrapper}',
//     name: RouteNames.wrapper,
//     pageBuilder: (context, builder) => const MaterialPage(
//       child: AuthenticationWrapper(),
//     ),
//   ),
//   GoRoute(
//     path: '/${RouteNames.registerScreen}',
//     name: RouteNames.registerScreen,
//     pageBuilder: (context, state) => const MaterialPage(
//       child: SignupScreen(),
//     ),
//   ),
//   GoRoute(
//     path: '/${RouteNames.loginScreen}',
//     name: RouteNames.loginScreen,
//     pageBuilder: (context, state) => const MaterialPage(
//       child: LoginScreen(),
//     ),
//   ),
//   GoRoute(
//     path: '/${RouteNames.userWelcomeScreen}',
//     name: RouteNames.userWelcomeScreen,
//     pageBuilder: (context, state) => MaterialPage(
//       child: UserWelcomeScreen(),
//     ),
//   ),
//   GoRoute(
//       path: '/${RouteNames.profileScreen}',
//       name: RouteNames.profileScreen,
//       pageBuilder: (context, state) {
//         return const MaterialPage(
//           child: ProfileViewScreen(),
//         );
//       }),
//   GoRoute(
//     path: '/${RouteNames.questionScreen2}',
//     name: RouteNames.questionScreen2,
//     pageBuilder: (context, state) => const MaterialPage(
//       child: QuestionScreen2(),
//     ),
//   ),
]);
