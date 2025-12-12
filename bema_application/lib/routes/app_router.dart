import 'package:bema_application/features/authentication/screens/chat_screen/chat_screen.dart';
import 'package:bema_application/features/authentication/screens/login_screen.dart';
import 'package:bema_application/features/authentication/screens/profile_screen.dart';
import 'package:bema_application/features/authentication/screens/question_screens/welcome_question_screen.dart';
import 'package:bema_application/features/authentication/screens/signup_screen.dart';
import 'package:bema_application/features/daily_suggestions/screens/daily_suggestions_screen.dart';
import 'package:bema_application/features/dive_reflex/screens/dive_reflex_screen.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_10.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_11.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_12.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_13.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_14.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_15.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_16.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_17.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_18.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_19.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_2.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_20.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_3.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_4.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_5.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_6.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_7.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_8.dart';
import 'package:bema_application/features/general_questions/screens/question_screen_9.dart';
import 'package:bema_application/features/general_questions/screens/thank_you_screen.dart';
import 'package:bema_application/features/home/screens/home_screen.dart';
import 'package:bema_application/features/instant_stress_release/screens/instant_stress_release_screen.dart';
import 'package:bema_application/features/navbar/bottom_navbar.dart';
import 'package:bema_application/features/workout_plan/screens/workout_screen.dart';
import 'package:bema_application/features/pose_coach/screens/pose_coach_screen.dart';
import 'package:bema_application/features/pose_coach/screens/pose_session_gallery_screen.dart';
import 'package:bema_application/features/pose_coach/screens/workout_report_screen.dart';
import 'package:bema_application/features/pose_coach/models/workout_report.dart';
import 'package:bema_application/routes/authendication_wrapper.dart';
import 'package:bema_application/features/authentication/screens/mood_screen/mood_friend.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final goRouter = GoRouter(initialLocation: '/${RouteNames.wrapper}', routes: [
  GoRoute(
    path: '/${RouteNames.bottomNavigationBarScreen}',
    name: RouteNames.bottomNavigationBarScreen,
    pageBuilder: (context, state) {
      int id = state.extra as int; // Pass index for initial tab
      return MaterialPage(
        child: BNavbarScreen(initialIndex: id),
      );
    },
  ),
  GoRoute(
    path: '/${RouteNames.wrapper}',
    name: RouteNames.wrapper,
    pageBuilder: (context, state) => const MaterialPage(
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
    path: '/${RouteNames.questionScreen3}',
    name: RouteNames.questionScreen3,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen3(),
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
  GoRoute(
    path: '/${RouteNames.questionScreen9}',
    name: RouteNames.questionScreen9,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen9(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen10}',
    name: RouteNames.questionScreen10,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen10(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen11}',
    name: RouteNames.questionScreen11,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen11(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen12}',
    name: RouteNames.questionScreen12,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen12(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen13}',
    name: RouteNames.questionScreen13,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen13(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen14}',
    name: RouteNames.questionScreen14,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen14(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen15}',
    name: RouteNames.questionScreen15,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen15(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen16}',
    name: RouteNames.questionScreen16,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen16(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen17}',
    name: RouteNames.questionScreen17,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen17(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen18}',
    name: RouteNames.questionScreen18,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen18(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen19}',
    name: RouteNames.questionScreen19,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen19(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.questionScreen20}',
    name: RouteNames.questionScreen20,
    pageBuilder: (context, state) => const MaterialPage(
      child: QuestionScreen20(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.thankYouScreen}',
    name: RouteNames.thankYouScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: ThankYouScreen(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.homeScreen}',
    name: RouteNames.homeScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: HomeScreen(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.chatScreen}',
    name: RouteNames.chatScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: ChatScreen(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.dailyTaskScreen}',
    name: RouteNames.dailyTaskScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: DailytaskScreen(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.stressReleaseScreen}',
    name: RouteNames.stressReleaseScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: StressReleaseScreen(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.moodFriendScreen}',
    name: RouteNames.moodFriendScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: MoodFriend(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.WorkoutPlanScreen}',
    name: RouteNames.WorkoutPlanScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: WorkoutPlanScreen(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.diveReflexScreen}',
    name: RouteNames.diveReflexScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: DiveReflexScreen(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.poseCoachScreen}',
    name: RouteNames.poseCoachScreen,
    pageBuilder: (context, state) => const MaterialPage(
      child: PoseCoachScreen(),
    ),
  ),
  GoRoute(
    path: '/${RouteNames.poseSessionGalleryScreen}',
    name: RouteNames.poseSessionGalleryScreen,
    pageBuilder: (context, state) {
      // Get optional exercise filter from extra
      final exerciseFilter = state.extra as String?;
      return MaterialPage(
        child: PoseSessionGalleryScreen(exerciseFilter: exerciseFilter),
      );
    },
  ),
  GoRoute(
    path: WorkoutReportScreen.routePath,
    name: 'workoutReport',
    pageBuilder: (context, state) {
      final report = state.extra as WorkoutReport?;
      if (report == null) {
        return const MaterialPage(
            child: Scaffold(body: Center(child: Text('Report missing'))));
      }
      return MaterialPage(
        child: WorkoutReportScreen(report: report),
      );
    },
  ),
]);
