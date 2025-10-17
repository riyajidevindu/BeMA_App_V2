import '../models/pose_session.dart';

/// Feedback level for exercise form
enum FeedbackLevel {
  excellent,
  good,
  needsImprovement,
  poor,
}

/// Result of exercise analysis
class ExerciseAnalysisResult {
  final bool isRepCompleted;
  final FeedbackLevel feedbackLevel;
  final String feedback;
  final double accuracy;
  final Map<String, dynamic>? additionalData;

  ExerciseAnalysisResult({
    required this.isRepCompleted,
    required this.feedbackLevel,
    required this.feedback,
    required this.accuracy,
    this.additionalData,
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

  /// Calculate angle between three points
  double calculateAngle(
    PoseLandmark point1,
    PoseLandmark point2,
    PoseLandmark point3,
  ) {
    final vector1X = point1.x - point2.x;
    final vector1Y = point1.y - point2.y;
    final vector2X = point3.x - point2.x;
    final vector2Y = point3.y - point2.y;

    final dotProduct = vector1X * vector2X + vector1Y * vector2Y;
    final magnitude1 =
        (vector1X * vector1X + vector1Y * vector1Y).abs().toDouble();
    final magnitude2 =
        (vector2X * vector2X + vector2Y * vector2Y).abs().toDouble();

    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final angleRad = cosAngle.clamp(-1.0, 1.0);
    return angleRad * 57.2958; // Convert to degrees
  }

  /// Calculate distance between two points
  double calculateDistance(PoseLandmark point1, PoseLandmark point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return (dx * dx + dy * dy).abs().toDouble();
  }
}
