import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';
import 'dart:convert';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Save task progress for the current user for the current date
  Future<void> saveTaskForToday(List<TaskModel> tasks) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format

      // Create a map for Firestore from task list
      Map<String, dynamic> tasksMap = {};
      for (var task in tasks) {
        tasksMap[task.title] = task.toFirestore();
      }

      // Save tasks for the current date
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .set(tasksMap);
    }
  }

   Future<void> saveTask(TaskModel task) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format

      await _firestore.collection('users').doc(userId).collection('tasks').doc(currentDate).set({
        task.title: task.toFirestore(),
      }, SetOptions(merge: true)); // Use merge to avoid overwriting other tasks
    }
  }

  /// Fetch all tasks for the current date for the user
  Future<List<TaskModel>> fetchUserTasksForToday(List<TaskModel> defaultTasks) async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      DocumentSnapshot taskSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .get();

      if (taskSnapshot.exists) {
        Map<String, dynamic> data = taskSnapshot.data() as Map<String, dynamic>;

        // Update the default task list with Firestore data
        List<TaskModel> updatedTasks = defaultTasks.map((task) {
          if (data.containsKey(task.title)) {
            return TaskModel.fromFirestore(data[task.title]);
          }
          return task;
        }).toList();

        return updatedTasks;
      }
    }
    return defaultTasks;
  }

  /// Check if tasks for today are saved in Firestore
  Future<bool> isTaskListSavedForToday() async {
    if (currentUser != null) {
      String userId = currentUser!.uid;
      String currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format

      DocumentSnapshot taskSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(currentDate)
          .get();

      return taskSnapshot.exists;
    }
    return false;
  }

  // Mock method to simulate fetching tasks from API (JSON format)
  Future<List<TaskModel>> fetchTasksFromAPI() async {
    String jsonResponse = '''{
      "tasks": [
        {
                 {
          "title": "Water Intake",
          "detail": "You should drink 2.5 liters of water today.",
          "type": "stepwise",
      " {
          "title": "Water Intake",
          "detail": "You should drink 2.5 liters of water today.",
          "type": "stepwise",
          "total": 2500,
          "progress": 1000,
          "stepAmount": 250,
          "completed": false
        },
        {
          "title": "Walking Duration",
          "detail": "Aim to walk for 45 minutes or complete 6000 steps today.",
          "type": "regular",
          "completed": false
        },
        {
          "title": "Stretching Time",
          "detail": "Spend 10 minutes doing flexibility exercises.",
          "type": "regular",
          "completed": true
        },
        {
          "title": "Mindfulness Exercise",
          "detail": "Try 10 minutes of mindfulness meditation today.",
          "type": "regular",
          "completed": false
        },
        {
          "title": "Nutrition Tip",
          "detail": "Eat at least 5 servings of fruits and vegetables.",
          "type": "regular",
          "completed": false
        },
        {
          "title": "Sleep Reminder",
          "detail": "Aim for at least 7 hours of sleep tonight.",
          "type": "regular",
          "completed": false
        },
        {
          "title": "Screen Time Break",
          "detail": "Take a 15-minute break after every hour of screen time.",
          "type": "stepwise",
          "total": 4,
          "progress": 1,
          "stepAmount": 1,
          "completed": false
        },
        {
          "title": "Special Task",
          "detail": "Today's challenge: Avoid sugary snacks.",
          "type": "regular",
          "completed": false
        },
        {
          "title": "Social Interaction",
          "detail": "Reach out to a friend for a quick chat.",
          "type": "regular",
          "completed": false
        },
        {
          "title": "Posture Check",
          "detail": "Make sure to check your posture every hour.",
          "type": "regular",
          "completed": false
        }
      ]
    }''';

    Map<String, dynamic> data = jsonDecode(jsonResponse);

    List<TaskModel> tasks = (data['tasks'] as List)
        .map((task) => TaskModel(
              title: task['title'],
              detail: task['detail'],
              type: task['type'],
              total: task['total'],
              progress: task['progress'],
              stepAmount: task['stepAmount'],
              completed: task['completed'],
            ))
        .toList();

    return tasks;
  }
}
