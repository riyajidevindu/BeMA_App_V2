import 'package:bema_application/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';
import 'package:flutter/material.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ApiService apiService = ApiService(); // Instance of ApiService

  /// Check if tasks for today already exist
  Future<bool> _hasTasksForToday() async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      DocumentSnapshot taskSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .get();

      print("Checking for existing tasks for today: ${taskSnapshot.exists}");
      return taskSnapshot.exists;
    }
    return false;
  }

  /// Fetch user's medical data from Firestore
  Future<Map<String, dynamic>?> fetchUserMedicalData() async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      DocumentSnapshot medicalDataSnapshot =
          await _firestore.collection('userBasicData').doc(userId).get();

      if (medicalDataSnapshot.exists) {
        print("Fetched user medical data: ${medicalDataSnapshot.data()}");
        return medicalDataSnapshot.data() as Map<String, dynamic>?;
      }
    }
    print("No medical data found for the user.");
    return null;
  }

  /// Fetch daily task recommendations by calling the API
  Future<List<TaskModel>?> fetchDailyTaskRecommendations(
      Map<String, dynamic> medicalData) async {
    // Call the API service function to get daily task recommendations
    Map<String, dynamic>? apiData = await apiService.sendAgentData(medicalData);

    if (apiData != null) {
      print("Received data from API: $apiData");

      // Map the API response to TaskModel instances, handling potential null values
      return apiData.entries.map((entry) {
        String key = entry.key;
        Map<String, dynamic> data = entry.value;

        // Safely extract values, providing default values if null
        String title = data['title'] ?? key;
        String detail = data['detail'] ?? '';
        String type = data['type'] ?? 'regular';
        int? total = data['total'] as int? ?? 0; // Default to 0 if null
        int progress = data['progress'] as int? ?? 0;
        int? stepAmount = data['stepAmount'] as int? ??
            (type == 'stepwise' ? 1 : null); // Default stepAmount for stepwise

        return TaskModel(
          title: title,
          detail: detail,
          icon: _getIconForTask(key),
          type: type,
          total: total,
          progress: progress,
          stepAmount: stepAmount,
          completed: data['completed'] as bool? ?? false,
        );
      }).toList();
    } else {
      print("Failed to retrieve task recommendations from the API.");
      return null;
    }
  }

  /// Helper to get the icon based on task key
  IconData _getIconForTask(String key) {
    const Map<String, IconData> iconMapping = {
      "water_intake": Icons.local_drink,
      "walking_duration": Icons.directions_walk,
      "stretching_time": Icons.accessibility_new,
      "stretching_duration": Icons.accessibility_new,
      "mindfulness_exercise": Icons.self_improvement,
      "nutrition_tip": Icons.local_dining,
      "sleep_reminder": Icons.bedtime,
      "screen_time_break": Icons.tv_off,
      "special_task": Icons.no_food,
      "social_interaction": Icons.group,
      "posture_reminder": Icons.accessibility,
    };
    return iconMapping[key] ?? Icons.help_outline;
  }

  /// Generate daily tasks if not set for today
  Future<void> generateDailyTasksIfNeeded(List<TaskModel> defaultTasks) async {
    bool hasTasks = await _hasTasksForToday();

    if (!hasTasks) {
      // Fetch user medical data
      Map<String, dynamic>? medicalData = await fetchUserMedicalData();
      print("User Exisitng medical data : $medicalData");

      if (medicalData != null) {
        // Fetch task recommendations based on medical data
        List<TaskModel>? recommendedTasks =
            await fetchDailyTaskRecommendations(medicalData);
        print("Api tasks : $recommendedTasks");

        if (recommendedTasks != null) {
          print("Saving recommended tasks to Firestore...");
          for (var task in recommendedTasks) {
            await saveTask(task);
          }
        } else {
          print("API failed; saving default tasks instead.");
          for (var task in defaultTasks) {
            await saveTask(task);
          }
        }
      } else {
        print("No medical data found; using default tasks.");
        for (var task in defaultTasks) {
          await saveTask(task);
        }
      }
    } else {
      print("Tasks for today already exist.");
    }
  }

  /// Save a task for the current user
  Future<void> saveTask(TaskModel task) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate =
          DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .set({
        task.title: task.toFirestore(),
      }, SetOptions(merge: true)); // Use merge to avoid overwriting other tasks
      print("Saved task: ${task.title}");
    }
  }

  /// Fetch tasks for the current user for today's date
  Future<List<TaskModel>> fetchUserTasks(List<TaskModel> defaultTasks) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      print("Current date $currentDate");

      DocumentSnapshot taskSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .get();

      if (taskSnapshot.exists) {
        Map<String, dynamic> data = taskSnapshot.data() as Map<String, dynamic>;
        print("Tasks found for today");

        // Update default tasks with saved Firestore data
        return defaultTasks.map((task) {
          if (data.containsKey(task.title)) {
            return TaskModel.fromFirestore(data[task.title]);
          }
          return task;
        }).toList();
      } else {
        print("No tasks found for today; returning default tasks.");
      }
    }
    return defaultTasks;
  }
}
