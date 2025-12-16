import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/pose_session.dart';

class PoseCoachProvider with ChangeNotifier {
  // Workout state
  bool _isWorkoutActive = false;
  String _currentExercise = 'squat';
  int _repCount = 0;
  double _accuracy = 0.0;
  List<String> _feedbackHistory = [];
  DateTime? _workoutStartTime;

  // Squat state tracking
  bool _isInDownPosition = false;
  bool _isInUpPosition = true;
  int _consecutiveGoodReps = 0;

  // Real-time feedback
  String _currentFeedback = 'Ready to start!';
  bool _showVisualFeedback = false;

  // Getters
  bool get isWorkoutActive => _isWorkoutActive;
  String get currentExercise => _currentExercise;
  int get repCount => _repCount;
  double get accuracy => _accuracy;
  List<String> get feedbackHistory => _feedbackHistory;
  String get currentFeedback => _currentFeedback;
  bool get showVisualFeedback => _showVisualFeedback;
  int get consecutiveGoodReps => _consecutiveGoodReps;

  // Start workout
  void startWorkout(String exercise) {
    _currentExercise = exercise;
    _isWorkoutActive = true;
    _repCount = 0;
    _accuracy = 0.0;
    _feedbackHistory = [];
    _workoutStartTime = DateTime.now();
    _isInDownPosition = false;
    _isInUpPosition = true;
    _consecutiveGoodReps = 0;
    _currentFeedback = 'Let\'s begin! Get into position';
    notifyListeners();
  }

  // Stop workout
  PoseSession stopWorkout(String userId) {
    _isWorkoutActive = false;
    final duration = _workoutStartTime != null
        ? DateTime.now().difference(_workoutStartTime!).inSeconds
        : 0;

    final session = PoseSession(
      userId: userId,
      exercise: _currentExercise,
      reps: _repCount,
      accuracy: _accuracy,
      timestamp: DateTime.now(),
      duration: duration,
      feedbackPoints: _feedbackHistory,
    );

    // Reset state
    _currentFeedback = 'Workout completed!';
    notifyListeners();

    return session;
  }

  // Analyze squat pose and update rep count
  void analyzeSquatPose(List<PoseLandmark> landmarks) {
    if (!_isWorkoutActive || landmarks.length < 33) {
      return;
    }

    // Calculate angles for squat analysis
    final analysis = _calculateSquatAngles(landmarks);

    // Check squat depth and form
    final isGoodForm = _checkSquatForm(analysis);

    // Update feedback
    _updateFeedback(analysis, isGoodForm);

    // Count reps based on position transitions
    _updateRepCount(analysis, isGoodForm);

    // Update accuracy (running average)
    if (_repCount > 0) {
      _accuracy =
          (_accuracy * (_repCount - 1) + (isGoodForm ? 1.0 : 0.6)) / _repCount;
      _accuracy = _accuracy.clamp(0.0, 1.0);
    }

    notifyListeners();
  }

  // Calculate joint angles for squat
  SquatAnalysis _calculateSquatAngles(List<PoseLandmark> landmarks) {
    // Key landmarks for squat analysis
    // 23: left hip, 24: right hip
    // 25: left knee, 26: right knee
    // 27: left ankle, 28: right ankle
    // 11: left shoulder, 12: right shoulder

    // Use right side for analysis (can be improved to use both sides)
    final shoulder = landmarks[12];
    final hip = landmarks[24];
    final knee = landmarks[26];
    final ankle = landmarks[28];

    // Calculate angles
    final hipAngle = _calculateAngle(shoulder, hip, knee);
    final kneeAngle = _calculateAngle(hip, knee, ankle);
    final ankleAngle = _calculateAngle(
        knee,
        ankle,
        PoseLandmark(
            x: ankle.x,
            y: ankle.y + 0.1,
            z: ankle.z,
            visibility: 1.0)); // Virtual point below ankle

    // Check if form is correct
    // Good squat: hip angle < 100°, knee angle < 110°, knee not going past toes
    final isCorrectForm = hipAngle < 100 &&
        kneeAngle > 70 &&
        kneeAngle < 110 &&
        _checkKneeAlignment(knee, ankle);

    String? feedback;
    if (!isCorrectForm) {
      if (hipAngle > 100) {
        feedback = 'Go deeper! Squat lower';
      } else if (kneeAngle < 70) {
        feedback = 'Don\'t bend knees too much';
      } else if (!_checkKneeAlignment(knee, ankle)) {
        feedback = 'Keep knees behind toes';
      }
    }

    return SquatAnalysis(
      hipAngle: hipAngle,
      kneeAngle: kneeAngle,
      ankleAngle: ankleAngle,
      isCorrectForm: isCorrectForm,
      feedback: feedback,
    );
  }

  // Calculate angle between three points
  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    double angle = radians.abs() * 180.0 / pi;

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }

    return angle;
  }

  // Check if knee is properly aligned (not going past toes)
  bool _checkKneeAlignment(PoseLandmark knee, PoseLandmark ankle) {
    // Knee x-coordinate should not be significantly ahead of ankle
    return (knee.x - ankle.x).abs() < 0.1; // Threshold can be adjusted
  }

  // Check overall squat form
  bool _checkSquatForm(SquatAnalysis analysis) {
    return analysis.isCorrectForm && analysis.hipAngle < 100;
  }

  // Update feedback based on analysis
  void _updateFeedback(SquatAnalysis analysis, bool isGoodForm) {
    if (isGoodForm) {
      if (_isInDownPosition) {
        _currentFeedback = 'Perfect squat! Push up';
        _showVisualFeedback = true;
      } else {
        _currentFeedback = 'Great form! Lower down';
        _showVisualFeedback = true;
      }
    } else {
      _currentFeedback = analysis.feedback ?? 'Adjust your form';
      _showVisualFeedback = false;
    }
  }

  // Update rep count based on position transitions
  void _updateRepCount(SquatAnalysis analysis, bool isGoodForm) {
    // Detect down position (hip angle < 100°)
    if (analysis.hipAngle < 100 && !_isInDownPosition && _isInUpPosition) {
      _isInDownPosition = true;
      _isInUpPosition = false;
    }

    // Detect up position (hip angle > 160°) - complete rep
    if (analysis.hipAngle > 160 && _isInDownPosition && !_isInUpPosition) {
      _isInUpPosition = true;
      _isInDownPosition = false;

      // Count rep
      _repCount++;

      // Track consecutive good reps
      if (isGoodForm) {
        _consecutiveGoodReps++;
        _feedbackHistory.add('Rep $_repCount: Excellent form!');
      } else {
        _consecutiveGoodReps = 0;
        _feedbackHistory.add('Rep $_repCount: Form needs improvement');
      }

      // Milestone feedback
      if (_repCount % 5 == 0) {
        _feedbackHistory.add('🎉 ${_repCount} reps completed!');
      }
    }
  }

  // Update feedback for any exercise (used by exercise logic)
  void updateExerciseFeedback(
      String feedback, double accuracy, bool isGoodForm) {
    _currentFeedback = feedback;
    _showVisualFeedback = isGoodForm;

    // Update running accuracy
    if (_repCount > 0) {
      _accuracy = (_accuracy * _repCount + accuracy / 100.0) / (_repCount + 1);
      _accuracy = _accuracy.clamp(0.0, 1.0);
    }

    notifyListeners();
  }

  // Increment rep count (called by exercise logic when rep is completed)
  void incrementRep() {
    _repCount++;
    _feedbackHistory.add('Rep $_repCount completed!');

    // Milestone feedback
    if (_repCount % 5 == 0) {
      _feedbackHistory.add('🎉 ${_repCount} reps completed!');
    }

    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _isWorkoutActive = false;
    _repCount = 0;
    _accuracy = 0.0;
    _feedbackHistory = [];
    _workoutStartTime = null;
    _isInDownPosition = false;
    _isInUpPosition = true;
    _consecutiveGoodReps = 0;
    _currentFeedback = 'Ready to start!';
    _showVisualFeedback = false;
    notifyListeners();
  }
}
