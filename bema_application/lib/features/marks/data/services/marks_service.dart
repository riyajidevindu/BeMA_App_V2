import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Fetches the daily, weekly, and monthly points and today's tasks
  Future<Map<String, dynamic>> fetchTaskSummary() async {
    final dailyTasks = await fetchUserTasks([]);
    final dailyPoints = _calculatePoints(dailyTasks);
    final weeklyPoints = await calculateWeeklyPoints();
    final monthlyPoints = await calculateMonthlyPoints();

    return {
      'dailyTasks': dailyTasks,
      'dailyPoints': dailyPoints,
      'weeklyPoints': weeklyPoints,
      'monthlyPoints': monthlyPoints,
    };
  }

  /// Fetches today's tasks for the user; if none exist, returns an empty list.
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

      // If tasks are found, map them to TaskModel objects; otherwise, return defaultTasks
      if (taskSnapshot.docs.isNotEmpty) {
        return taskSnapshot.docs.map((doc) {
          return TaskModel.fromFirestore(doc.data() as Map<String, dynamic>);
        }).toList();
      }
    }
    return defaultTasks;
  }

  /// Calculate points for completed tasks in a list
  double _calculatePoints(List<TaskModel> tasks) {
    return tasks.where((task) => task.completed).length * 10.0;
  }

  /// Calculate points earned over the past 7 days
  Future<double> calculateWeeklyPoints() async {
    return _fetchPointsForPeriod(days: 7);
  }

  /// Calculate points earned over the past 30 days
  Future<double> calculateMonthlyPoints() async {
    return _fetchPointsForPeriod(days: 30);
  }

  /// Helper function to fetch points for a specified number of days
  Future<double> _fetchPointsForPeriod({required int days}) async {
    if (currentUser == null) return 0;

    final userId = currentUser!.uid;
    final now = DateTime.now();
    double points = 0.0;

    // Loop through each day in the specified period to fetch completed tasks and calculate points
    for (int i = 0; i < days; i++) {
      final date =
          now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
      final taskListSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(date)
          .collection('taskList')
          .get();

      // Count completed tasks and accumulate points
      final completedTasks = taskListSnapshot.docs
          .map((doc) =>
              TaskModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .where((task) => task.completed)
          .length;

      points += completedTasks * 10.0; // Assuming 10 points per completed task
    }

    return points;
  }

  /// Fetch user profile name from Firestore
  Future<String> getUserName() async {
    final userId = currentUser?.uid;
    if (userId == null) return 'User';

    final userSnapshot =
        await _firestore.collection('userProfiles').doc(userId).get();
    return userSnapshot.data()?['name'] ?? 'User';
  }
}
