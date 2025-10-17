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

    // Determine if in squat position (knee angle < 100 degrees)
    final isInSquatPosition = avgKneeAngle < 100;

    // Determine if standing (knee angle > 160 degrees)
    final isStanding = avgKneeAngle > 160;

    // Form feedback
    String feedback = '';
    FeedbackLevel feedbackLevel = FeedbackLevel.good;
    double accuracy = 0.0;

    // Check form quality
    if (isInSquatPosition) {
      if (avgKneeAngle >= 70 && avgKneeAngle <= 100) {
        feedback = 'Perfect squat depth!';
        feedbackLevel = FeedbackLevel.excellent;
        accuracy = 95.0;
      } else if (avgKneeAngle < 70) {
        feedback = 'Too deep. Knees at 90 degrees.';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = 70.0;
      } else {
        feedback = 'Go lower for full squat.';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = 75.0;
      }

      // Check back alignment
      if (backAlignment < 0.8) {
        feedback = 'Keep your back straight!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = accuracy * 0.8;
      }

      // Check knee alignment (knees shouldn't go too far forward)
      if (avgHipAngle < 60) {
        feedback = 'Push hips back more!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = accuracy * 0.85;
      }
    } else if (isStanding) {
      feedback = 'Stand tall, ready for next rep';
      feedbackLevel = FeedbackLevel.good;
      accuracy = 90.0;
    } else {
      feedback = 'Keep going...';
      feedbackLevel = FeedbackLevel.good;
      accuracy = 80.0;
    }

    // Count reps
    bool isRepCompleted = false;
    if (_wasStanding && isInSquatPosition && !_isSquatting) {
      _isSquatting = true;
      _wasStanding = false;
    } else if (_isSquatting && isStanding) {
      _isSquatting = false;
      _wasStanding = true;
      _repCount++;
      _accuracyScores.add(accuracy);
      isRepCompleted = true;
      feedback = 'Rep $_repCount completed! Great form!';
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
        'backAlignment': backAlignment,
      },
    );
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
