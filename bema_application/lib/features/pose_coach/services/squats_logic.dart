import '../models/pose_session.dart';
import 'exercise_logic.dart';

class SquatsLogic extends ExerciseLogic {
  @override
  String get exerciseName => 'Squats';

  @override
  String get exerciseId => 'squats';

  int _repCount = 0;
  double _totalAccuracy = 0.0;
  bool _isSquatting = false;
  bool _wasStanding = true;
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
    _totalAccuracy = 0.0;
    _isSquatting = false;
    _wasStanding = true;
    _accuracyScores.clear();
  }

  @override
  ExerciseAnalysisResult analyzePose(List<PoseLandmark> landmarks) {
    if (landmarks.length < 33) {
      return ExerciseAnalysisResult(
        isRepCompleted: false,
        feedbackLevel: FeedbackLevel.poor,
        feedback: 'Cannot detect full body. Please step back.',
        accuracy: 0.0,
      );
    }

    // Get key landmarks for squats
    final leftHip = landmarks[23];
    final leftKnee = landmarks[25];
    final leftAnkle = landmarks[27];
    final rightHip = landmarks[24];
    final rightKnee = landmarks[26];
    final rightAnkle = landmarks[28];
    final leftShoulder = landmarks[11];
    final rightShoulder = landmarks[12];
    final nose = landmarks[0];

    // Check user orientation (facing, sideways, or back to camera)
    final orientation = _detectOrientation(
        leftShoulder, rightShoulder, leftHip, rightHip, nose);

    // If not in correct orientation (sideways), return orientation feedback
    if (orientation != 'sideways') {
      String orientationFeedback = '';
      if (orientation == 'facing') {
        orientationFeedback =
            'Turn sideways to the camera. Stand with your side facing the camera.';
      } else if (orientation == 'back') {
        orientationFeedback =
            'I can see your back. Please turn to face sideways to the camera.';
      } else {
        orientationFeedback =
            'Please position yourself sideways to the camera for proper tracking.';
      }

      return ExerciseAnalysisResult(
        isRepCompleted: false,
        feedbackLevel: FeedbackLevel.needsImprovement,
        feedback: orientationFeedback,
        accuracy: 0.0,
        additionalData: {
          'orientation': orientation,
          'needsOrientationFix': true,
        },
      );
    }

    // Calculate knee angles (hip-knee-ankle)
    final leftKneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle);
    final rightKneeAngle = calculateAngle(rightHip, rightKnee, rightAnkle);
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // Calculate hip angles (shoulder-hip-knee)
    final leftHipAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    final rightHipAngle = calculateAngle(rightShoulder, rightHip, rightKnee);
    final avgHipAngle = (leftHipAngle + rightHipAngle) / 2;

    // Check if back is straight (shoulders should be relatively aligned with hips)
    final backAlignment =
        _calculateBackAlignment(leftShoulder, rightShoulder, leftHip, rightHip);

    // Determine if in squat position (knee angle < 110 degrees)
    final isInSquatPosition = avgKneeAngle < 110;

    // Determine if standing (knee angle > 160 degrees)
    final isStanding = avgKneeAngle > 160;

    // Form feedback with priorities
    String feedback = '';
    FeedbackLevel feedbackLevel = FeedbackLevel.good;
    double accuracy = 0.0;
    bool hasFormIssue = false;

    // Check form quality during squat
    if (isInSquatPosition) {
      // First priority: Good depth
      if (avgKneeAngle >= 70 && avgKneeAngle <= 100) {
        feedback = 'Perfect squat depth!';
        feedbackLevel = FeedbackLevel.excellent;
        accuracy = 95.0;
      } else if (avgKneeAngle < 70) {
        feedback = 'Too deep. Knees at 90 degrees.';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = 70.0;
        hasFormIssue = true;
      } else {
        feedback = 'Go lower for full squat.';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = 75.0;
      }

      // Second priority: Check back alignment
      if (backAlignment < 0.7) {
        feedback = 'Keep your back straight!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = accuracy * 0.75;
        hasFormIssue = true;
      }

      // Third priority: Check hip position (less strict threshold)
      // Only warn if hips are significantly not pushed back
      if (avgHipAngle < 50 && !hasFormIssue) {
        feedback = 'Push hips back more!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = accuracy * 0.85;
        hasFormIssue = true;
      }
    } else if (isStanding) {
      feedback = 'Stand tall, ready for next rep';
      feedbackLevel = FeedbackLevel.good;
      accuracy = 90.0;
    } else {
      // Transitioning
      feedback = 'Keep going...';
      feedbackLevel = FeedbackLevel.good;
      accuracy = 80.0;
    }

    // Count reps - simplified logic
    bool isRepCompleted = false;

    // Going down
    if (_wasStanding && isInSquatPosition && !_isSquatting) {
      _isSquatting = true;
      _wasStanding = false;
    }
    // Coming up and completing rep
    else if (_isSquatting && isStanding && !_wasStanding) {
      _isSquatting = false;
      _wasStanding = true;
      _repCount++;
      _accuracyScores.add(accuracy);
      isRepCompleted = true;
      feedback = 'Rep $_repCount completed! Excellent!';
      feedbackLevel = FeedbackLevel.excellent;
    }

    return ExerciseAnalysisResult(
      isRepCompleted: isRepCompleted,
      feedbackLevel: feedbackLevel,
      feedback: feedback,
      accuracy: accuracy,
      additionalData: {
        'leftKneeAngle': leftKneeAngle,
        'rightKneeAngle': rightKneeAngle,
        'avgKneeAngle': avgKneeAngle,
        'avgHipAngle': avgHipAngle,
        'backAlignment': backAlignment,
        'hasFormIssue': hasFormIssue,
      },
    );
  }

  String _detectOrientation(
    PoseLandmark leftShoulder,
    PoseLandmark rightShoulder,
    PoseLandmark leftHip,
    PoseLandmark rightHip,
    PoseLandmark nose,
  ) {
    // Calculate shoulder width (horizontal distance)
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();

    // Calculate hip width
    final hipWidth = (leftHip.x - rightHip.x).abs();

    // Calculate average body width
    final avgBodyWidth = (shoulderWidth + hipWidth) / 2;

    // Thresholds for orientation detection
    // - Sideways: narrow width, high depth difference
    // - Facing: wide width, low depth difference
    // - Back: wide width, low depth difference (+ nose visibility)

    if (avgBodyWidth < 0.15) {
      // Very narrow - likely sideways (CORRECT for squats)
      return 'sideways';
    } else if (avgBodyWidth > 0.25) {
      // Wide - either facing or back to camera
      // Could check nose.z for back detection but simplified for now
      return 'facing';
    } else {
      // In between - partially turned
      return 'partial';
    }
  }

  double _calculateBackAlignment(
    PoseLandmark leftShoulder,
    PoseLandmark rightShoulder,
    PoseLandmark leftHip,
    PoseLandmark rightHip,
  ) {
    // Calculate if torso is relatively vertical
    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidX = (leftHip.x + rightHip.x) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;

    final verticalDist = (shoulderMidY - hipMidY).abs();
    final horizontalDist = (shoulderMidX - hipMidX).abs();

    if (verticalDist == 0) return 0.0;
    return (verticalDist / (verticalDist + horizontalDist));
  }

  @override
  List<String> getFormTips() {
    return [
      '✓ Keep your feet shoulder-width apart',
      '✓ Push your hips back as you lower down',
      '✓ Keep your chest up and back straight',
      '✓ Lower until thighs are parallel to ground',
      '✓ Push through your heels to stand up',
      '✓ Keep your knees aligned with your toes',
    ];
  }
}
