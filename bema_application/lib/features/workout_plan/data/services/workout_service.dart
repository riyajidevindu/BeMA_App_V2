import 'package:bema_application/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bema_application/features/workout_plan/data/models/workout_plan.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ApiService apiService = ApiService();

  /// Checks if workout plan for the current date is already created
  Future<bool> _hasWorkoutPlanForToday() async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      DocumentSnapshot workoutDocument = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlans')
          .doc(currentDate)
          .get();

      if (workoutDocument.exists) {
        bool workoutPlanCreated =
            workoutDocument.get('workoutPlanCreated') ?? false;
        if (workoutPlanCreated) {
          print("Workout plan has already been created for today.");
          return true;
        }
      }
    }
    return false;
  }

  /// Generates workout plan if it hasn't been created today
  Future<void> generateWorkoutPlanIfNeeded(
      List<WorkoutPlan> defaultWorkouts) async {
    bool hasWorkoutPlan = await _hasWorkoutPlanForToday();

    if (hasWorkoutPlan) {
      print("Workout plan for today already exists. Skipping generation.");
      return;
    }

    print("No workout plan found for today. Generating new plan...");

    try {
      // Fetch workout plan from API
      List<WorkoutPlan>? recommendedWorkouts = await fetchWorkoutPlanFromApi();

      if (recommendedWorkouts != null && recommendedWorkouts.isNotEmpty) {
        for (var workout in recommendedWorkouts) {
          await saveWorkoutPlan(workout);
        }
      } else {
        // Use default workouts if API fails
        for (var workout in defaultWorkouts) {
          await saveWorkoutPlan(workout);
        }
      }
    } catch (error) {
      print("Error fetching workout plan from API: $error");
      // Save default workouts on error
      for (var workout in defaultWorkouts) {
        await saveWorkoutPlan(workout);
      }
    }

    // After creating workout plan, set workoutPlanCreated to true
    await _setWorkoutPlanCreatedFlag();
  }

  /// Sets the workoutPlanCreated flag to true in Firestore
  Future<void> _setWorkoutPlanCreatedFlag() async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlans')
          .doc(currentDate)
          .set({'workoutPlanCreated': true}, SetOptions(merge: true));

      print("Set workoutPlanCreated to true for today's workout plan.");
    }
  }

  /// Fetches workout plans for the current date
  Future<List<WorkoutPlan>> fetchUserWorkoutPlans(
      List<WorkoutPlan> defaultWorkouts) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      print("Fetching workout plans for date: $currentDate");

      QuerySnapshot workoutSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlans')
          .doc(currentDate)
          .collection('workoutList')
          .get();

      if (workoutSnapshot.docs.isNotEmpty) {
        return workoutSnapshot.docs.map((doc) {
          return WorkoutPlan.fromFirestore(doc.data() as Map<String, dynamic>);
        }).toList();
      }
    }
    return defaultWorkouts;
  }

  /// Saves an individual workout plan to Firestore
  Future<void> saveWorkoutPlan(WorkoutPlan workout) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlans')
          .doc(currentDate)
          .collection('workoutList')
          .doc(workout.exerciseType)
          .set(workout.toFirestore());

      print("Saved workout plan: ${workout.exerciseType}");
    }
  }

  /// Fetches workout plan from API
  Future<List<WorkoutPlan>?> fetchWorkoutPlanFromApi() async {
    if (currentUser != null) {
      String userId = currentUser!.uid;

      try {
        Map<String, dynamic>? apiResponse =
            await apiService.getWorkoutPlan(userId);

        if (apiResponse != null) {
          return convertApiOutputToWorkoutPlans(apiResponse);
        }
      } catch (e) {
        print("Error fetching workout plan from API: $e");
        return null;
      }
    }
    return null;
  }

  /// Update workout plan (for user edits)
  Future<void> updateWorkoutPlan(WorkoutPlan workout) async {
    await saveWorkoutPlan(workout);
  }
}
