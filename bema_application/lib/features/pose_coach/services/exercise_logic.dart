import 'dart:math';
import '../models/pose_session.dart';

/// Feedback level for exercise form
enum FeedbackLevel {
  excellent,
  good,
  needsImprovement,
  poor,
}

/// Exercise phases for voice coaching
enum ExercisePhase {
  standing, // Ready position, standing tall
  goingDown, // Transitioning down (knee angle decreasing)
  atBottom, // In squat position (lowest point)
  comingUp, // Transitioning up (knee angle increasing)
  repComplete, // Just completed a rep
  outOfFrame, // User not visible
  adjustPosition, // User needs to adjust (too close/far)
}

/// Voice cue types for proper timing
enum VoiceCueType {
  goDown, // "Go down" - when standing ready
  keepGoing, // "Keep going" - during descent
  holdIt, // "Hold" - at bottom
  comeUp, // "Come up" / "Push up" - from bottom
  goodRep, // "Good!" - rep completed well
  excellentRep, // "Excellent!" - perfect rep
  needsWork, // Short feedback for poor rep
  formCorrection, // Form issue detected
  encouragement, // "You got this!" etc
  repCount, // "Rep 1", "Rep 2" etc
  getReady, // "Get ready for next rep"
}

/// Result of exercise analysis
class ExerciseAnalysisResult {
  final bool isRepCompleted;
  final FeedbackLevel feedbackLevel;
  final String feedback;
  final double accuracy;
  final Map<String, dynamic>? additionalData;
  final ExercisePhase? currentPhase;
  final ExercisePhase? previousPhase;
  final VoiceCueType? suggestedVoiceCue;

  ExerciseAnalysisResult({
    required this.isRepCompleted,
    required this.feedbackLevel,
    required this.feedback,
    required this.accuracy,
    this.additionalData,
    this.currentPhase,
    this.previousPhase,
    this.suggestedVoiceCue,
  });
}

/// Abstract base class for exercise-specific logic
abstract class ExerciseLogic {
  String get exerciseName;
  String get exerciseId;

  /// Initialize exercise-specific state
  void initialize();

  /// Reset exercise state
  void reset();

  /// Analyze pose landmarks and return feedback
  ExerciseAnalysisResult analyzePose(List<PoseLandmark> landmarks);

  /// Get current rep count
  int get repCount;

  /// Get average accuracy for the session
  double get averageAccuracy;

  /// Get detailed form tips
  List<String> getFormTips();

  /// Calculate angle between three points (point2 is the vertex)
  double calculateAngle(
    PoseLandmark point1,
    PoseLandmark point2,
    PoseLandmark point3,
  ) {
    // Create vectors from vertex (point2) to the other two points
    final vector1X = point1.x - point2.x;
    final vector1Y = point1.y - point2.y;
    final vector2X = point3.x - point2.x;
    final vector2Y = point3.y - point2.y;

    // Calculate dot product
    final dotProduct = vector1X * vector2X + vector1Y * vector2Y;

    // Calculate magnitudes (lengths) of the vectors
    final magnitude1 = sqrt(vector1X * vector1X + vector1Y * vector1Y);
    final magnitude2 = sqrt(vector2X * vector2X + vector2Y * vector2Y);

    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;

    // Calculate cosine of angle
    final cosAngle = dotProduct / (magnitude1 * magnitude2);

    // Clamp to valid range for acos
    final clampedCos = cosAngle.clamp(-1.0, 1.0);

    // Calculate angle in radians, then convert to degrees
    final angleRad = acos(clampedCos);
    final angleDeg = angleRad * 180.0 / pi;

    return angleDeg;
  }

  /// Calculate distance between two points
  double calculateDistance(PoseLandmark point1, PoseLandmark point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return (dx * dx + dy * dy).abs().toDouble();
  }
}
