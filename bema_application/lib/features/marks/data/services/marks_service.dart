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
    final monthlyTotalPoints = await calculateTotalMonthlyMarks();

    return {
      'dailyTasks': dailyTasks,
      'dailyPoints': double.parse(dailyPoints.toStringAsFixed(1)),
      'weeklyPoints': double.parse(weeklyPoints.toStringAsFixed(1)),
      'monthlyPoints': double.parse(monthlyPoints.toStringAsFixed(1)),
      'monthlyTotalPoints': double.parse(monthlyTotalPoints.toStringAsFixed(2)),
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

  /// Calculate points for completed tasks in a list for the day
  double _calculatePoints(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0;
    double totalDailyMarks = 100; // Total marks for a day
    double taskMarks = totalDailyMarks / tasks.length;
    return tasks.where((task) => task.completed).length * taskMarks;
  }

  /// Calculate points earned over the past 7 days
  Future<double> calculateWeeklyPoints() async {
    return _fetchPointsForPeriod(days: 7);
  }

  /// Function to calculate total possible marks for the current month based on days with tasks.
  Future<double> calculateTotalMonthlyMarks() async {
    if (currentUser == null) return 0.0;

    String userId = currentUser!.uid;
    DateTime now = DateTime.now();
    int daysWithTasks = 0;

    // Start from the first day to the last day of the current month
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

    for (DateTime date = startOfMonth;
        date.isBefore(endOfMonth) || date.isAtSameMomentAs(endOfMonth);
        date = date.add(Duration(days: 1))) {

      String dateString = date.toIso8601String().split('T')[0];
      QuerySnapshot taskSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(dateString)
          .collection('taskList')
          .get();

      if (taskSnapshot.docs.isNotEmpty) {
        daysWithTasks += 1;
      }
    }

    return daysWithTasks * 100.0; // Each day contributes 100 points
  }


  /// Calculate marks for the current month based on completed tasks
  Future<double> calculateMonthlyPoints() async {
    if (currentUser == null) return 0;

    String userId = currentUser!.uid;
    DateTime now = DateTime.now();
    double monthlyMarks = 0;

    // Get the start and end of the current month
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0); // Last day of the month

    // Loop through each day of the month
    for (DateTime date = startOfMonth;
        date.isBefore(endOfMonth) || date.isAtSameMomentAs(endOfMonth);
        date = date.add(Duration(days: 1))) {
      
      String dateString = date.toIso8601String().split('T')[0];
      
      // Fetch tasks for the current date
      QuerySnapshot taskSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(dateString)
          .collection('taskList')
          .get();

      if (taskSnapshot.docs.isNotEmpty) {
        List<TaskModel> tasks = taskSnapshot.docs.map((doc) {
          return TaskModel.fromFirestore(doc.data() as Map<String, dynamic>);
        }).toList();

        // Calculate daily marks and add to monthly total
        double dailyMarks = _calculatePoints(tasks);
        monthlyMarks += dailyMarks;
      }
    }

    // Cap the monthly marks at 100 if you want a max limit for the month
    return monthlyMarks;
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

      // Calculate daily points and add to the cumulative total
      if (completedTasks > 0) {
        double dailyPoints = _calculatePoints(taskListSnapshot.docs
            .map((doc) =>
                TaskModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
        points += dailyPoints;
      }
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
