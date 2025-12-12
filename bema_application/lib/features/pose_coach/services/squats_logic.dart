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

  // Track the best squat depth accuracy during each rep
  double _currentRepBestAccuracy = 0.0;
  double _currentRepLowestKneeAngle = 180.0;

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
    _currentRepBestAccuracy = 0.0;
    _currentRepLowestKneeAngle = 180.0;
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

    // Store orientation for reference but don't block exercise
    // Orientation detection is informational only
    final isIdealOrientation = orientation == 'sideways';
    String orientationHint = '';

    if (!isIdealOrientation && orientation == 'facing') {
      orientationHint = 'Tip: Turn sideways for better tracking';
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

    // STRICTER thresholds for squat detection to prevent false positives
    // Determine if in squat position (knee angle < 110 degrees - STRICTER)
    final isInSquatPosition = avgKneeAngle < 110;

    // Determine if standing (knee angle > 160 degrees - STRICTER)
    final isStanding = avgKneeAngle > 160;

    // Form feedback with priorities
    String feedback = '';
    FeedbackLevel feedbackLevel = FeedbackLevel.good;
    double accuracy = 0.0;
    bool hasFormIssue = false;

    // Check form quality during squat
    if (isInSquatPosition) {
      // Calculate depth score based on knee angle
      // Perfect depth: 70-95 degrees (thighs parallel or slightly below)
      // Good depth: 95-105 degrees
      // Partial squat: 105-110 degrees
      // Too deep: < 70 degrees

      double depthScore = 0.0;

      if (avgKneeAngle >= 70 && avgKneeAngle <= 95) {
        // Perfect squat depth - thighs parallel or slightly below
        depthScore = 100.0;
        feedback = 'Perfect squat depth!';
        feedbackLevel = FeedbackLevel.excellent;
      } else if (avgKneeAngle > 95 && avgKneeAngle <= 105) {
        // Good depth but could go slightly lower
        depthScore = 85.0;
        feedback = 'Good depth!';
        feedbackLevel = FeedbackLevel.good;
      } else if (avgKneeAngle > 105 && avgKneeAngle < 110) {
        // Partial squat - still counts but not ideal
        depthScore = 70.0;
        feedback = 'Go a bit lower for full squat.';
        feedbackLevel = FeedbackLevel.good;
      } else if (avgKneeAngle < 70) {
        // Too deep - risk of knee strain
        depthScore = 75.0;
        feedback = 'Slightly too deep. Aim for 90 degrees.';
        feedbackLevel = FeedbackLevel.needsImprovement;
        hasFormIssue = true;
      }

      // Start with depth score as base accuracy
      accuracy = depthScore;

      // Apply penalties for form issues (multiplicative)

      // Back alignment penalty (leaning too far forward)
      if (backAlignment < 0.60) {
        feedback = 'Keep your back straighter!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = accuracy * 0.75; // 25% penalty for poor back
        hasFormIssue = true;
      } else if (backAlignment < 0.70) {
        if (!hasFormIssue) {
          feedback = 'Try to keep chest up more.';
        }
        accuracy = accuracy * 0.90; // 10% penalty for slight lean
      }

      // Hip hinge check - proper squat requires hip angle around 80-120 degrees
      // Too upright (>130) means not pushing hips back
      // Too bent (<70) means excessive forward lean
      if (avgHipAngle > 130 && !hasFormIssue) {
        feedback = 'Push your hips back more!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = accuracy * 0.85; // 15% penalty
        hasFormIssue = true;
      } else if (avgHipAngle < 60 && !hasFormIssue) {
        feedback = 'Keep your torso more upright!';
        feedbackLevel = FeedbackLevel.needsImprovement;
        accuracy = accuracy * 0.85;
        hasFormIssue = true;
      }

      // Track the best accuracy during this squat (lowest point)
      // We want to record the form quality at the deepest point
      if (avgKneeAngle < _currentRepLowestKneeAngle) {
        _currentRepLowestKneeAngle = avgKneeAngle;
        _currentRepBestAccuracy = accuracy;
      }
    } else if (isStanding) {
      feedback = 'Stand tall, ready for next rep';
      feedbackLevel = FeedbackLevel.good;
      // Don't assign accuracy for standing - we use the squat phase accuracy
      accuracy = _currentRepBestAccuracy > 0 ? _currentRepBestAccuracy : 0.0;
    } else {
      // Transitioning
      feedback = 'Keep going...';
      feedbackLevel = FeedbackLevel.good;
      accuracy = _currentRepBestAccuracy > 0 ? _currentRepBestAccuracy : 0.0;
    }

    // Count reps - simplified logic
    bool isRepCompleted = false;

    // Debug logging for rep counting with actual angles
    print('DEBUG SQUAT: avgKneeAngle=${avgKneeAngle.toStringAsFixed(1)}°, '
        'leftKnee=${leftKneeAngle.toStringAsFixed(1)}°, '
        'rightKnee=${rightKneeAngle.toStringAsFixed(1)}°, '
        'isStanding=$isStanding (>160°), '
        'isSquatting=$isInSquatPosition (<110°), '
        '_wasStanding=$_wasStanding, _isSquatting=$_isSquatting, '
        'repAccuracy=${_currentRepBestAccuracy.toStringAsFixed(1)}%');

    // Going down - start tracking this rep
    if (_wasStanding && isInSquatPosition && !_isSquatting) {
      _isSquatting = true;
      _wasStanding = false;
      // Reset tracking for new rep
      _currentRepBestAccuracy = accuracy;
      _currentRepLowestKneeAngle = avgKneeAngle;
      print(
          'DEBUG SQUAT: ✓ Detected squat going DOWN (angle: ${avgKneeAngle.toStringAsFixed(1)}°)');
    }
    // Coming up and completing rep
    else if (_isSquatting && isStanding && !_wasStanding) {
      _isSquatting = false;
      _wasStanding = true;
      _repCount++;

      // Store the best accuracy from the squat phase (at lowest point)
      final repAccuracy =
          _currentRepBestAccuracy > 0 ? _currentRepBestAccuracy : 70.0;
      _accuracyScores.add(repAccuracy);

      isRepCompleted = true;
      feedback =
          'Rep $_repCount done! ${repAccuracy >= 85 ? "Great form!" : repAccuracy >= 70 ? "Good!" : "Keep practicing!"}';
      feedbackLevel = repAccuracy >= 85
          ? FeedbackLevel.excellent
          : repAccuracy >= 70
              ? FeedbackLevel.good
              : FeedbackLevel.needsImprovement;

      print(
          'DEBUG SQUAT: ✓✓ Rep completed! Total: $_repCount, Accuracy: ${repAccuracy.toStringAsFixed(1)}%');

      // Reset for next rep
      _currentRepBestAccuracy = 0.0;
      _currentRepLowestKneeAngle = 180.0;
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
        'orientation': orientation,
        'orientationHint': orientationHint,
        'isIdealOrientation': isIdealOrientation,
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

    // Debug logging
    print('DEBUG ORIENTATION: shoulderWidth=$shoulderWidth, '
        'hipWidth=$hipWidth, avgBodyWidth=$avgBodyWidth');

    // Thresholds for orientation detection (made more lenient)
    // - Sideways: narrow width, high depth difference
    // - Facing: wide width, low depth difference
    // - Back: wide width, low depth difference (+ nose visibility)

    if (avgBodyWidth < 0.20) {
      // Lenient threshold - likely sideways (CORRECT for squats)
      print('DEBUG ORIENTATION: Detected SIDEWAYS');
      return 'sideways';
    } else if (avgBodyWidth > 0.30) {
      // Wide - either facing or back to camera
      print('DEBUG ORIENTATION: Detected FACING');
      return 'facing';
    } else {
      // In between - partially turned (consider as acceptable)
      print('DEBUG ORIENTATION: Detected PARTIAL (treating as sideways)');
      return 'sideways'; // Changed to treat partial as acceptable
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
