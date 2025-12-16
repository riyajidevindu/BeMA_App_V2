import '../models/pose_session.dart';
import 'exercise_logic.dart';

class PushupsLogic extends ExerciseLogic {
  @override
  String get exerciseName => 'Push-ups';

  @override
  String get exerciseId => 'pushups';

  int _repCount = 0;
  bool _isDown = false;
  bool _wasUp = true;
  List<double> _accuracyScores = [];

  @override
  int get repCount => _repCount;

  @override
  double get averageAccuracy {
    if (_accuracyScores.isEmpty) return 0.0;
    return _accuracyScores.reduce((a, b) => a + b) / _accuracyScores.length;
  }

  @override
  void initialize() {
    reset();
  }

  @override
  void reset() {
    _repCount = 0;
    _isDown = false;
    _wasUp = true;
    _accuracyScores.clear();
  }

  @override
  ExerciseAnalysisResult analyzePose(List<PoseLandmark> landmarks) {
    if (landmarks.length < 33) {
      return ExerciseAnalysisResult(
        isRepCompleted: false,
        feedbackLevel: FeedbackLevel.poor,
        feedback: 'Cannot detect full body. Adjust camera.',
        accuracy: 0.0,
      );
    }

    // Get key landmarks for push-ups
    final leftShoulder = landmarks[11];
    final rightShoulder = landmarks[12];
    final leftElbow = landmarks[13];
    final rightElbow = landmarks[14];
    final leftWrist = landmarks[15];
    final rightWrist = landmarks[16];
    final leftHip = landmarks[23];
    final rightHip = landmarks[24];
    final leftKnee = landmarks[25];
    final rightKnee = landmarks[26];

    // Calculate elbow angles (shoulder-elbow-wrist)
    final leftElbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    final rightElbowAngle =
        calculateAngle(rightShoulder, rightElbow, rightWrist);
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Calculate body alignment (shoulder-hip-knee should be straight)
    final leftBodyAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    final rightBodyAngle = calculateAngle(rightShoulder, rightHip, rightKnee);
    final avgBodyAngle = (leftBodyAngle + rightBodyAngle) / 2;

    // Determine if in down position (elbow angle < 100 degrees - STRICTER)
    final isInDownPosition = avgElbowAngle < 100;

    // Determine if in up position (elbow angle > 165 degrees - STRICTER)
    final isInUpPosition = avgElbowAngle > 165;

    // Form feedback
    String feedback = '';
    FeedbackLevel feedbackLevel = FeedbackLevel.good;
    double accuracy = 0.0;

    // Check form quality (STRICTER requirements)
    if (isInDownPosition) {
      if (avgElbowAngle >= 75 && avgElbowAngle <= 95) {
        feedback = 'Perfect depth! Now push up!';
        feedbackLevel = FeedbackLevel.excellent;
        accuracy = 95.0;
      } else if (avgElbowAngle < 75) {
        feedback = 'Too low! 90 degrees is enough.';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = 70.0;
      } else {
        feedback = 'Go lower, chest to ground!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = 70.0; // Reduced accuracy for shallow pushups
      }

      // Check body alignment (should maintain plank position) - STRICTER
      if (avgBodyAngle < 165) {
        feedback = 'Keep your body straight! No sagging hips.';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = accuracy * 0.65; // More penalty for bad form
      }
    } else if (isInUpPosition) {
      feedback = 'Arms extended, ready!';
      feedbackLevel = FeedbackLevel.good;
      accuracy = 90.0;

      // Still check alignment in up position - STRICTER
      if (avgBodyAngle < 165) {
        feedback = 'Maintain straight body line!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = 70.0; // Reduced accuracy
      }
    } else {
      feedback = 'Keep going...';
      feedbackLevel = FeedbackLevel.good;
      accuracy = 80.0;
    }

    // Count reps
    bool isRepCompleted = false;
    if (_wasUp && isInDownPosition && !_isDown) {
      _isDown = true;
      _wasUp = false;
    } else if (_isDown && isInUpPosition) {
      _isDown = false;
      _wasUp = true;
      _repCount++;
      _accuracyScores.add(accuracy);
      isRepCompleted = true;
      feedback = 'Rep $_repCount complete! Excellent!';
      feedbackLevel = FeedbackLevel.excellent;
    }

    return ExerciseAnalysisResult(
      isRepCompleted: isRepCompleted,
      feedbackLevel: feedbackLevel,
      feedback: feedback,
      accuracy: accuracy,
      additionalData: {
        'leftElbowAngle': leftElbowAngle,
        'rightElbowAngle': rightElbowAngle,
        'avgElbowAngle': avgElbowAngle,
        'bodyAlignment': avgBodyAngle,
      },
    );
  }

  @override
  List<String> getFormTips() {
    return [
      '✓ Start in plank position, hands shoulder-width',
      '✓ Keep your body in a straight line',
      '✓ Lower your chest to the ground',
      '✓ Elbows at 90 degrees at bottom',
      '✓ Push back up to starting position',
      '✓ Don\'t let your hips sag or pike up',
    ];
  }
}
