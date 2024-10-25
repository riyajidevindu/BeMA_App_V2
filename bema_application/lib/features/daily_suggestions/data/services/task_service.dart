import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Save task progress for the current user
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
  Future<List<TaskModel>> fetchUserTasks(List<TaskModel> defaultTasks) async {
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
}
