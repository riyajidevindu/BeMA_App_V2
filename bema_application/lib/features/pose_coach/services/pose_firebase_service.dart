import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bema_application/features/pose_coach/models/pose_session.dart';

class PoseFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save workout session to Firebase
  /// Path: users/{userId}/workoutSessions/{sessionId}
  Future<String?> saveWorkoutSession({
    required String userId,
    required PoseSession session,
  }) async {
    try {
      // Create a new document reference to get the auto-generated ID
      DocumentReference docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutSessions')
          .doc();

      // Convert session to JSON
      Map<String, dynamic> sessionData = {
        'sessionId': docRef.id,
        'userId': userId,
        'exercise': session.exercise,
        'reps': session.reps,
        'accuracy': session.accuracy,
        'timestamp': session.timestamp.toIso8601String(),
        'duration': session.duration,
        'feedbackPoints': session.feedbackPoints,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firebase
      await docRef.set(sessionData);
      
      print('Workout session saved to Firebase: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving workout session to Firebase: $e');
      return null;
    }
  }

  /// Fetch all workout sessions for a user
  Future<List<Map<String, dynamic>>> getUserWorkoutSessions(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutSessions')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'sessionId': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print('Error fetching workout sessions from Firebase: $e');
      return [];
    }
  }

  /// Fetch workout sessions for a specific date range
  Future<List<Map<String, dynamic>>> getUserWorkoutSessionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutSessions')
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'sessionId': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print('Error fetching workout sessions by date range: $e');
      return [];
    }
  }

  /// Get workout statistics for a user
  Future<Map<String, dynamic>> getUserWorkoutStats(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutSessions')
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalSessions': 0,
          'totalReps': 0,
          'averageAccuracy': 0.0,
          'totalDuration': 0,
        };
      }

      int totalSessions = snapshot.docs.length;
      int totalReps = 0;
      double totalAccuracy = 0.0;
      int totalDuration = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalReps += (data['reps'] as int?) ?? 0;
        totalAccuracy += (data['accuracy'] as num?)?.toDouble() ?? 0.0;
        totalDuration += (data['duration'] as int?) ?? 0;
      }

      return {
        'totalSessions': totalSessions,
        'totalReps': totalReps,
        'averageAccuracy': totalAccuracy / totalSessions,
        'totalDuration': totalDuration,
      };
    } catch (e) {
      print('Error calculating workout stats: $e');
      return {
        'totalSessions': 0,
        'totalReps': 0,
        'averageAccuracy': 0.0,
        'totalDuration': 0,
      };
    }
  }

  /// Delete a specific workout session
  Future<bool> deleteWorkoutSession({
    required String userId,
    required String sessionId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutSessions')
          .doc(sessionId)
          .delete();
      
      print('Workout session deleted from Firebase: $sessionId');
      return true;
    } catch (e) {
      print('Error deleting workout session: $e');
      return false;
    }
  }

  /// Get today's workout sessions
  Future<List<Map<String, dynamic>>> getTodayWorkoutSessions(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return await getUserWorkoutSessionsByDateRange(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      print('Error fetching today\'s workout sessions: $e');
      return [];
    }
  }

  /// Get this week's workout sessions
  Future<List<Map<String, dynamic>>> getWeekWorkoutSessions(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      return await getUserWorkoutSessionsByDateRange(
        userId: userId,
        startDate: startOfWeekDay,
        endDate: now,
      );
    } catch (e) {
      print('Error fetching this week\'s workout sessions: $e');
      return [];
    }
  }

  /// Get this month's workout sessions
  Future<List<Map<String, dynamic>>> getMonthWorkoutSessions(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);

      return await getUserWorkoutSessionsByDateRange(
        userId: userId,
        startDate: startOfMonth,
        endDate: now,
      );
    } catch (e) {
      print('Error fetching this month\'s workout sessions: $e');
      return [];
    }
  }
}
