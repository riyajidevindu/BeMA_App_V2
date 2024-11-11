import 'package:bema_application/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';
import 'package:flutter/material.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ApiService apiService = ApiService();

  Future<bool> _hasTasksForToday() async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      print("Current User Id: ${userId} ");
      print("Current date: ${currentDate} ");

      DocumentSnapshot taskDocument = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .get();


       print("Current tasks: ${taskDocument} ");
       print("Current tasks exixsts: ${taskDocument.exists} ");

      if (taskDocument.exists) {
        QuerySnapshot taskListSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(currentDate)
            .collection('taskList')
            .get();

        //print("Task document exists for today: ${taskDocument.exists}");
        //print("Number of tasks in 'taskList': ${taskListSnapshot.docs.length}");

        return taskListSnapshot.docs.isNotEmpty;
      } else {
        print("No task document exists for today.");
      }
    }
    return false;
  }

  Future<void> generateDailyTasksIfNeeded(List<TaskModel> defaultTasks) async {
    bool hasTasks = await _hasTasksForToday();

    if (hasTasks) {
      print("Tasks for today already exist. Skipping task generation.");
      return;
    }

    print("No tasks found for today. Generating new tasks...");

    Map<String, dynamic>? medicalData = await fetchUserMedicalData();

    if (medicalData != null) {
      List<TaskModel>? recommendedTasks =
          await fetchDailyTaskRecommendations(medicalData);

      if (recommendedTasks != null && recommendedTasks.isNotEmpty) {
        for (var task in recommendedTasks) {
          await saveTask(task);
        }
      } else {
        for (var task in defaultTasks) {
          await saveTask(task);
        }
      }
    } else {
      for (var task in defaultTasks) {
        await saveTask(task);
      }
    }
  }

  Future<List<TaskModel>> fetchUserTasks(List<TaskModel> defaultTasks) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      print("Fetching tasks for date: $currentDate");

      QuerySnapshot taskSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .collection('taskList')
          .get();

      if (taskSnapshot.docs.isNotEmpty) {
        //print("Tasks found for today. Task count: ${taskSnapshot.docs.length}");
        return taskSnapshot.docs.map((doc) {
          return TaskModel.fromFirestore(doc.data() as Map<String, dynamic>);
        }).toList();
      }
    }
    return defaultTasks;
  }

  Future<void> saveTask(TaskModel task) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .collection('taskList')
          .doc(task.title)
          .set(task.toFirestore());

      print("Saved task: ${task.title}");
    }
  }

  Future<Map<String, dynamic>?> fetchUserMedicalData() async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      DocumentSnapshot medicalDataSnapshot =
          await _firestore.collection('userBasicData').doc(userId).get();

      if (medicalDataSnapshot.exists) {
        return medicalDataSnapshot.data() as Map<String, dynamic>?;
      }
    }
    return null;
  }

  Future<List<TaskModel>?> fetchDailyTaskRecommendations(
      Map<String, dynamic> medicalData) async {
    Map<String, dynamic>? apiData = await apiService.sendAgentData(medicalData);

    if (apiData != null) {
      return apiData.entries.map((entry) {
        String key = entry.key;
        Map<String, dynamic> data = entry.value;

        return TaskModel(
          title: data['title'] ?? key,
          detail: data['detail'] ?? '',
          icon: _getIconForTask(key),
          type: data['type'] ?? 'regular',
          total: data['total'] as int? ?? 0,
          progress: data['progress'] as int? ?? 0,
          stepAmount: data['stepAmount'] as int? ??
              (data['type'] == 'stepwise' ? 1 : null),
          completed: data['completed'] as bool? ?? false,
        );
      }).toList();
    }
    return null;
  }

  IconData _getIconForTask(String key) {
    const Map<String, IconData> iconMapping = {
      "water_intake": Icons.local_drink,
      "walking_duration": Icons.directions_walk,
      "stretching_time": Icons.accessibility_new,
      "mindfulness_exercise": Icons.self_improvement,
      "nutrition_tip": Icons.local_dining,
      "sleep_reminder": Icons.bedtime,
    };
    return iconMapping[key] ?? Icons.help_outline;
  }
}
