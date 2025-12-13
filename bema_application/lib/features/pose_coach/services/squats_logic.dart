import '../models/pose_session.dart';
import 'exercise_logic.dart';

/// Detailed analysis for each repetition
class RepAnalysis {
  final int repNumber;
  final double accuracy;
  final double lowestKneeAngle;
  final List<String> issues;
  final List<String> suggestions;
  final DateTime timestamp;

  RepAnalysis({
    required this.repNumber,
    required this.accuracy,
    required this.lowestKneeAngle,
    required this.issues,
    required this.suggestions,
    required this.timestamp,
  });
}

class SquatsLogic extends ExerciseLogic {
  @override
  String get exerciseName => 'Squats';

  @override
  String get exerciseId => 'squats';

  int _repCount = 0;
  bool _isSquatting = false;
  bool _wasStanding = true;
  List<double> _accuracyScores = [];

  // Track the best squat depth accuracy during each rep
  double _currentRepBestAccuracy = 0.0;
  double _currentRepLowestKneeAngle = 180.0;

  // Track issues during current rep for specific feedback
  List<String> _currentRepIssues = [];
  bool _hadBackIssue = false;
  bool _hadDepthIssue = false;
  bool _hadHipIssue = false;

  // Body size tracking to detect camera proximity changes
  double _lastBodyHeight = 0.0;
  double _stableBodyHeight = 0.0;
  int _stableFrameCount = 0;
  static const int _minStableFrames = 5; // Need 5 stable frames before tracking

  // Squat hold time tracking to prevent false reps
  DateTime? _squatStartTime;
  static const Duration _minSquatHoldTime = Duration(
      milliseconds:
          150); // Min 150ms in squat position (reduced for easier counting)

  // Standing hold time to confirm rep completion
  DateTime? _standingStartTime;
  static const Duration _minStandingHoldTime =
      Duration(milliseconds: 100); // Min 100ms standing (reduced)

  // Per-rep analysis history
  List<RepAnalysis> _repAnalyses = [];

  // Phase tracking for voice coaching
  ExercisePhase _currentPhase = ExercisePhase.standing;
  ExercisePhase _previousPhase = ExercisePhase.standing;
  double _previousKneeAngle = 180.0;
  bool _hasReachedBottom =
      false; // Track if we've been to bottom position this rep
  DateTime? _lastPhaseChangeTime;

  // Voice cue tracking
  bool _needsGoDownCue = true; // Ready to give "go down" cue
  bool _needsComeUpCue = false; // Ready to give "come up" cue
  bool _gaveComeUpCue = false; // Already gave "come up" for this rep

  // Getters
  @override
  int get repCount => _repCount;

  List<RepAnalysis> get repAnalyses => List.unmodifiable(_repAnalyses);

  RepAnalysis? get lastRepAnalysis =>
      _repAnalyses.isNotEmpty ? _repAnalyses.last : null;

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
    _isSquatting = false;
    _wasStanding = true;
    _accuracyScores.clear();
    _currentRepBestAccuracy = 0.0;
    _currentRepLowestKneeAngle = 180.0;
    _currentRepIssues.clear();
    _hadBackIssue = false;
    _hadDepthIssue = false;
    _hadHipIssue = false;
    _lastBodyHeight = 0.0;
    _stableBodyHeight = 0.0;
    _stableFrameCount = 0;
    _squatStartTime = null;
    _standingStartTime = null;
    _repAnalyses.clear();
    // Reset phase tracking
    _currentPhase = ExercisePhase.standing;
    _previousPhase = ExercisePhase.standing;
    _previousKneeAngle = 180.0;
    _hasReachedBottom = false;
    _lastPhaseChangeTime = null;
    _needsGoDownCue = true;
    _needsComeUpCue = false;
    _gaveComeUpCue = false;
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
    final leftHeel = landmarks[29];
    final rightHeel = landmarks[30];

    // === BODY SIZE VALIDATION ===
    // Calculate current body height (shoulder to ankle distance)
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final ankleMidY = (leftAnkle.y + rightAnkle.y) / 2;
    final currentBodyHeight = (ankleMidY - shoulderMidY).abs();

    // Check for sudden body size changes (person moving toward/away from camera)
    bool isBodySizeStable = _validateBodySize(currentBodyHeight);

    if (!isBodySizeStable) {
      // Person is moving toward or away from camera - don't count as exercise
      return ExerciseAnalysisResult(
        isRepCompleted: false,
        feedbackLevel: FeedbackLevel.good,
        feedback: 'Stay in position. Avoid moving closer or further.',
        accuracy: 0.0,
        additionalData: {'bodyMovement': true},
      );
    }

    // Check user orientation
    final orientation = _detectOrientation(
        leftShoulder, rightShoulder, leftHip, rightHip, nose);
    final isIdealOrientation = orientation == 'sideways';
    String orientationHint = '';
    if (!isIdealOrientation && orientation == 'facing') {
      orientationHint = 'Tip: Turn sideways for better tracking';
    }

    // === ANGLE CALCULATIONS ===
    // Calculate knee angles (hip-knee-ankle)
    final leftKneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle);
    final rightKneeAngle = calculateAngle(rightHip, rightKnee, rightAnkle);
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    // Calculate hip angles (shoulder-hip-knee)
    final leftHipAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    final rightHipAngle = calculateAngle(rightShoulder, rightHip, rightKnee);
    final avgHipAngle = (leftHipAngle + rightHipAngle) / 2;

    // Check back alignment
    final backAlignment =
        _calculateBackAlignment(leftShoulder, rightShoulder, leftHip, rightHip);

    // Calculate heel lift (feet should stay flat)
    final heelLift =
        _calculateHeelLift(leftHeel, rightHeel, leftAnkle, rightAnkle);

    // === POSITION DETECTION ===
    // Squat position: knee angle < 130 degrees (more lenient for easier detection)
    final isInSquatPosition = avgKneeAngle < 130;
    // Standing position: knee angle > 150 degrees (more lenient)
    final isStanding = avgKneeAngle > 150;

    // === FORM ANALYSIS ===
    String feedback = '';
    FeedbackLevel feedbackLevel = FeedbackLevel.good;
    double accuracy = 0.0;
    List<String> currentFrameIssues = [];

    if (isInSquatPosition) {
      // Analyze squat form
      final formAnalysis = _analyzeSquatForm(
        avgKneeAngle: avgKneeAngle,
        avgHipAngle: avgHipAngle,
        backAlignment: backAlignment,
        heelLift: heelLift,
        leftKneeAngle: leftKneeAngle,
        rightKneeAngle: rightKneeAngle,
      );

      accuracy = formAnalysis['accuracy'] as double;
      feedback = formAnalysis['feedback'] as String;
      feedbackLevel = formAnalysis['feedbackLevel'] as FeedbackLevel;
      currentFrameIssues = formAnalysis['issues'] as List<String>;

      // Track issues for this rep
      _trackRepIssues(currentFrameIssues);

      // Track the best accuracy at the deepest point
      if (avgKneeAngle < _currentRepLowestKneeAngle) {
        _currentRepLowestKneeAngle = avgKneeAngle;
        _currentRepBestAccuracy = accuracy;
      }

      // Track squat hold time
      _squatStartTime ??= DateTime.now();
      _standingStartTime = null;
    } else if (isStanding) {
      feedback = 'Stand tall, ready for next rep';
      feedbackLevel = FeedbackLevel.good;
      accuracy = _currentRepBestAccuracy > 0 ? _currentRepBestAccuracy : 0.0;

      // Track standing hold time
      _standingStartTime ??= DateTime.now();
    } else {
      // Transitioning
      feedback = 'Keep going...';
      feedbackLevel = FeedbackLevel.good;
      accuracy = _currentRepBestAccuracy > 0 ? _currentRepBestAccuracy : 0.0;

      // Reset timers during transition
      if (!_isSquatting) {
        _squatStartTime = null;
      }
      _standingStartTime = null;
    }

    // === REP COUNTING WITH VALIDATION ===
    bool isRepCompleted = false;
    String repFeedback = feedback;

    // Going down - start tracking this rep
    if (_wasStanding && isInSquatPosition && !_isSquatting) {
      // Validate it's a real squat start, not just noise
      if (_squatStartTime != null) {
        _isSquatting = true;
        _wasStanding = false;
        // Reset tracking for new rep
        _currentRepBestAccuracy = accuracy;
        _currentRepLowestKneeAngle = avgKneeAngle;
        _currentRepIssues.clear();
        _hadBackIssue = false;
        _hadDepthIssue = false;
        _hadHipIssue = false;
        _trackRepIssues(currentFrameIssues);

        print(
            'DEBUG SQUAT: ✓ Detected squat going DOWN (angle: ${avgKneeAngle.toStringAsFixed(1)}°)');
      }
    }
    // Coming up and completing rep
    else if (_isSquatting && isStanding && !_wasStanding) {
      // Validate the rep with multiple checks
      final isValidRep = _validateRepCompletion();

      if (isValidRep) {
        _isSquatting = false;
        _wasStanding = true;
        _repCount++;

        // Store the best accuracy from the squat phase
        final repAccuracy =
            _currentRepBestAccuracy > 0 ? _currentRepBestAccuracy : 70.0;
        _accuracyScores.add(repAccuracy);

        // Generate specific suggestions for this rep
        final suggestions = _generateRepSuggestions();

        // Create rep analysis
        final repAnalysis = RepAnalysis(
          repNumber: _repCount,
          accuracy: repAccuracy,
          lowestKneeAngle: _currentRepLowestKneeAngle,
          issues: List.from(_currentRepIssues),
          suggestions: suggestions,
          timestamp: DateTime.now(),
        );
        _repAnalyses.add(repAnalysis);

        isRepCompleted = true;

        // Generate detailed feedback
        repFeedback = _generateRepCompletionFeedback(repAccuracy, suggestions);
        feedbackLevel = repAccuracy >= 85
            ? FeedbackLevel.excellent
            : repAccuracy >= 70
                ? FeedbackLevel.good
                : FeedbackLevel.needsImprovement;

        print(
            'DEBUG SQUAT: ✓✓ Rep $_repCount completed! Accuracy: ${repAccuracy.toStringAsFixed(1)}%, '
            'Depth: ${_currentRepLowestKneeAngle.toStringAsFixed(1)}°, Issues: $_currentRepIssues');

        // Reset for next rep
        _currentRepBestAccuracy = 0.0;
        _currentRepLowestKneeAngle = 180.0;
        _currentRepIssues.clear();
        _squatStartTime = null;
        _standingStartTime = null;
        // Reset phase tracking for next rep
        _hasReachedBottom = false;
        _needsGoDownCue = true;
        _needsComeUpCue = false;
        _gaveComeUpCue = false;
      } else {
        // Invalid rep - don't count, provide feedback
        print('DEBUG SQUAT: ✗ Rep validation failed');
        repFeedback = 'Hold the squat longer for it to count.';
        feedbackLevel = FeedbackLevel.needsImprovement;
      }
    }

    // === PHASE DETECTION FOR VOICE COACHING ===
    _previousPhase = _currentPhase;
    VoiceCueType? suggestedCue;

    // Determine current phase based on knee angle and movement direction
    final isGoingDown =
        avgKneeAngle < _previousKneeAngle - 3; // 3 degree threshold
    final isGoingUp = avgKneeAngle > _previousKneeAngle + 3;

    if (isStanding) {
      _currentPhase = ExercisePhase.standing;

      // If we just completed a rep, suggest rep count cue
      if (isRepCompleted) {
        _currentPhase = ExercisePhase.repComplete;
        if (_currentRepBestAccuracy >= 85 ||
            _accuracyScores.isNotEmpty && _accuracyScores.last >= 85) {
          suggestedCue = VoiceCueType.excellentRep;
        } else if (_currentRepBestAccuracy >= 70 ||
            _accuracyScores.isNotEmpty && _accuracyScores.last >= 70) {
          suggestedCue = VoiceCueType.goodRep;
        } else {
          suggestedCue = VoiceCueType.needsWork;
        }
      }
      // Ready for next rep - suggest "go down" after completing a rep
      else if (_needsGoDownCue && _repCount > 0) {
        suggestedCue = VoiceCueType.getReady;
      }
      // First rep - suggest "go down"
      else if (_needsGoDownCue && _repCount == 0) {
        suggestedCue = VoiceCueType.goDown;
        _needsGoDownCue = false; // Only cue once until next rep
      }
    } else if (isInSquatPosition) {
      _currentPhase = ExercisePhase.atBottom;
      _hasReachedBottom = true;
      _needsGoDownCue = false;

      // At bottom - ready for "come up" cue
      if (!_gaveComeUpCue) {
        _needsComeUpCue = true;
        suggestedCue = VoiceCueType.comeUp;
        _gaveComeUpCue = true;
      }

      // Check for form issues at bottom
      if (currentFrameIssues.isNotEmpty && suggestedCue == null) {
        suggestedCue = VoiceCueType.formCorrection;
      }
    } else {
      // Transitioning
      if (isGoingDown && !_hasReachedBottom) {
        _currentPhase = ExercisePhase.goingDown;
        _needsGoDownCue = false;

        // Encourage to keep going
        if (avgKneeAngle > 130 && avgKneeAngle < 145) {
          suggestedCue = VoiceCueType.keepGoing;
        }
      } else if (isGoingUp && _hasReachedBottom) {
        _currentPhase = ExercisePhase.comingUp;

        // Encourage during ascent
        if (avgKneeAngle > 130 && avgKneeAngle < 150) {
          suggestedCue = VoiceCueType.encouragement;
        }
      }
    }

    _previousKneeAngle = avgKneeAngle;

    // Record phase change time
    if (_currentPhase != _previousPhase) {
      _lastPhaseChangeTime = DateTime.now();
    }

    // Debug logging
    print('DEBUG SQUAT: avgKneeAngle=${avgKneeAngle.toStringAsFixed(1)}°, '
        'isStanding=$isStanding, isSquatting=$isInSquatPosition, '
        '_wasStanding=$_wasStanding, _isSquatting=$_isSquatting, '
        'phase=$_currentPhase, cue=$suggestedCue');

    return ExerciseAnalysisResult(
      isRepCompleted: isRepCompleted,
      feedbackLevel: feedbackLevel,
      feedback: repFeedback,
      accuracy: accuracy,
      currentPhase: _currentPhase,
      previousPhase: _previousPhase,
      suggestedVoiceCue: suggestedCue,
      additionalData: {
        'leftKneeAngle': leftKneeAngle,
        'rightKneeAngle': rightKneeAngle,
        'avgKneeAngle': avgKneeAngle,
        'avgHipAngle': avgHipAngle,
        'backAlignment': backAlignment,
        'heelLift': heelLift,
        'orientation': orientation,
        'orientationHint': orientationHint,
        'isIdealOrientation': isIdealOrientation,
        'repAccuracy': _currentRepBestAccuracy,
        'lowestKneeAngle': _currentRepLowestKneeAngle,
        'currentRepIssues': _currentRepIssues,
        'lastRepAnalysis': lastRepAnalysis,
      },
    );
  }

  /// Validate body size to detect if person is moving toward/away from camera
  bool _validateBodySize(double currentBodyHeight) {
    if (_stableBodyHeight == 0.0) {
      // First frame - establish baseline
      _lastBodyHeight = currentBodyHeight;
      _stableBodyHeight = currentBodyHeight;
      _stableFrameCount = 1;
      return true;
    }

    // Calculate size change percentage
    final sizeChange =
        ((currentBodyHeight - _stableBodyHeight) / _stableBodyHeight).abs();

    // If size changed more than 15%, person is likely moving toward/away from camera
    if (sizeChange > 0.15) {
      _stableFrameCount = 0;
      _lastBodyHeight = currentBodyHeight;
      return false;
    }

    // Size is stable, update tracking
    _stableFrameCount++;
    if (_stableFrameCount >= _minStableFrames) {
      // Update stable baseline with gradual adjustment
      _stableBodyHeight = _stableBodyHeight * 0.9 + currentBodyHeight * 0.1;
    }
    _lastBodyHeight = currentBodyHeight;
    return true;
  }

  /// Analyze squat form and return detailed feedback
  Map<String, dynamic> _analyzeSquatForm({
    required double avgKneeAngle,
    required double avgHipAngle,
    required double backAlignment,
    required double heelLift,
    required double leftKneeAngle,
    required double rightKneeAngle,
  }) {
    double accuracy = 0.0;
    String feedback = '';
    FeedbackLevel feedbackLevel = FeedbackLevel.good;
    List<String> issues = [];

    // 1. DEPTH SCORING (40% of total)
    double depthScore = 0.0;
    if (avgKneeAngle >= 70 && avgKneeAngle <= 95) {
      // Perfect depth - thighs parallel or slightly below
      depthScore = 100.0;
      feedback = 'Perfect squat depth!';
      feedbackLevel = FeedbackLevel.excellent;
    } else if (avgKneeAngle > 95 && avgKneeAngle <= 105) {
      // Good depth
      depthScore = 85.0;
      feedback = 'Good depth!';
      feedbackLevel = FeedbackLevel.good;
    } else if (avgKneeAngle > 105 && avgKneeAngle < 110) {
      // Partial squat
      depthScore = 65.0;
      feedback = 'Go lower - aim for thighs parallel to ground.';
      feedbackLevel = FeedbackLevel.needsImprovement;
      issues.add('shallow_depth');
    } else if (avgKneeAngle < 70) {
      // Too deep
      depthScore = 70.0;
      feedback = 'Slightly too deep. Stop at 90 degrees.';
      feedbackLevel = FeedbackLevel.needsImprovement;
      issues.add('too_deep');
    }

    // 2. BACK ALIGNMENT SCORING (25% of total)
    double backScore = 0.0;
    if (backAlignment >= 0.75) {
      backScore = 100.0;
    } else if (backAlignment >= 0.65) {
      backScore = 85.0;
      if (issues.isEmpty) {
        feedback = 'Keep chest up a bit more.';
      }
    } else if (backAlignment >= 0.55) {
      backScore = 65.0;
      feedback = 'Keep your back straighter!';
      feedbackLevel = FeedbackLevel.needsImprovement;
      issues.add('back_lean');
    } else {
      backScore = 50.0;
      feedback = 'Back is leaning too far forward!';
      feedbackLevel = FeedbackLevel.poor;
      issues.add('severe_back_lean');
    }

    // 3. HIP HINGE SCORING (20% of total)
    double hipScore = 0.0;
    if (avgHipAngle >= 70 && avgHipAngle <= 120) {
      hipScore = 100.0;
    } else if (avgHipAngle > 120 && avgHipAngle <= 140) {
      hipScore = 75.0;
      if (issues.isEmpty) {
        feedback = 'Push hips back more!';
        feedbackLevel = FeedbackLevel.needsImprovement;
      }
      issues.add('hips_not_back');
    } else if (avgHipAngle < 70) {
      hipScore = 70.0;
      if (issues.isEmpty) {
        feedback = 'Keep torso more upright!';
        feedbackLevel = FeedbackLevel.needsImprovement;
      }
      issues.add('excessive_lean');
    } else {
      hipScore = 60.0;
      issues.add('poor_hip_position');
    }

    // 4. KNEE SYMMETRY SCORING (10% of total)
    double symmetryScore = 0.0;
    final kneeDifference = (leftKneeAngle - rightKneeAngle).abs();
    if (kneeDifference <= 10) {
      symmetryScore = 100.0;
    } else if (kneeDifference <= 20) {
      symmetryScore = 80.0;
    } else {
      symmetryScore = 60.0;
      issues.add('knee_asymmetry');
    }

    // 5. HEEL SCORING (5% of total)
    double heelScore = 0.0;
    if (heelLift < 0.02) {
      heelScore = 100.0;
    } else if (heelLift < 0.05) {
      heelScore = 80.0;
    } else {
      heelScore = 60.0;
      issues.add('heels_lifting');
    }

    // Calculate weighted accuracy
    accuracy = (depthScore * 0.40) +
        (backScore * 0.25) +
        (hipScore * 0.20) +
        (symmetryScore * 0.10) +
        (heelScore * 0.05);

    return {
      'accuracy': accuracy,
      'feedback': feedback,
      'feedbackLevel': feedbackLevel,
      'issues': issues,
      'depthScore': depthScore,
      'backScore': backScore,
      'hipScore': hipScore,
      'symmetryScore': symmetryScore,
      'heelScore': heelScore,
    };
  }

  /// Track issues that occurred during this rep
  void _trackRepIssues(List<String> frameIssues) {
    for (final issue in frameIssues) {
      if (!_currentRepIssues.contains(issue)) {
        _currentRepIssues.add(issue);
      }
      // Track specific issue categories
      if (issue.contains('back') || issue.contains('lean')) {
        _hadBackIssue = true;
      }
      if (issue.contains('depth') || issue.contains('deep')) {
        _hadDepthIssue = true;
      }
      if (issue.contains('hip')) {
        _hadHipIssue = true;
      }
    }
  }

  /// Validate that a rep completion is legitimate
  bool _validateRepCompletion() {
    // Check 1: Squat was held long enough (lenient check)
    if (_squatStartTime == null) {
      // Allow rep if we detected squat position at some point
      print('DEBUG SQUAT: Warning - no squat start time, but allowing rep');
    } else {
      final squatDuration = DateTime.now().difference(_squatStartTime!);
      if (squatDuration < _minSquatHoldTime) {
        print(
            'DEBUG SQUAT: Rep rejected - squat hold too short: ${squatDuration.inMilliseconds}ms');
        return false;
      }
    }

    // Check 2: Actually reached some squat depth (very lenient - 140 degrees)
    // This ensures user actually bent their knees somewhat
    if (_currentRepLowestKneeAngle > 145) {
      print(
          'DEBUG SQUAT: Rep rejected - insufficient depth: ${_currentRepLowestKneeAngle.toStringAsFixed(1)}°');
      return false;
    }

    // Note: Removed standing stability check as it was too strict
    // The fact that we detected standing position is enough

    return true;
  }

  /// Generate specific suggestions based on rep issues
  List<String> _generateRepSuggestions() {
    List<String> suggestions = [];

    if (_currentRepIssues.contains('shallow_depth')) {
      suggestions.add('Go deeper - aim for thighs parallel to ground');
    }
    if (_currentRepIssues.contains('too_deep')) {
      suggestions.add('Stop when thighs are parallel, avoid going too low');
    }
    if (_currentRepIssues.contains('back_lean') ||
        _currentRepIssues.contains('severe_back_lean')) {
      suggestions.add('Keep your chest up and back straight');
    }
    if (_currentRepIssues.contains('hips_not_back')) {
      suggestions.add('Push your hips back as you lower down');
    }
    if (_currentRepIssues.contains('excessive_lean')) {
      suggestions.add('Keep your torso more upright');
    }
    if (_currentRepIssues.contains('knee_asymmetry')) {
      suggestions.add('Keep both knees bending evenly');
    }
    if (_currentRepIssues.contains('heels_lifting')) {
      suggestions.add('Keep your heels firmly on the ground');
    }

    // If no issues, give positive reinforcement
    if (suggestions.isEmpty && _currentRepBestAccuracy >= 85) {
      suggestions.add('Excellent form! Keep it up!');
    } else if (suggestions.isEmpty) {
      suggestions.add('Good rep! Focus on depth for better results.');
    }

    return suggestions;
  }

  /// Generate completion feedback for the rep
  String _generateRepCompletionFeedback(
      double accuracy, List<String> suggestions) {
    String baseFeedback;
    if (accuracy >= 90) {
      baseFeedback =
          'Rep $_repCount: Excellent! ${accuracy.toStringAsFixed(0)}%';
    } else if (accuracy >= 80) {
      baseFeedback = 'Rep $_repCount: Great! ${accuracy.toStringAsFixed(0)}%';
    } else if (accuracy >= 70) {
      baseFeedback = 'Rep $_repCount: Good! ${accuracy.toStringAsFixed(0)}%';
    } else {
      baseFeedback = 'Rep $_repCount: ${accuracy.toStringAsFixed(0)}%';
    }

    // Add first suggestion if there's room
    if (suggestions.isNotEmpty && accuracy < 90) {
      baseFeedback += ' - ${suggestions.first}';
    }

    return baseFeedback;
  }

  /// Calculate heel lift
  double _calculateHeelLift(
    PoseLandmark leftHeel,
    PoseLandmark rightHeel,
    PoseLandmark leftAnkle,
    PoseLandmark rightAnkle,
  ) {
    // Check if heels are higher than they should be relative to ankles
    final leftLift = (leftAnkle.y - leftHeel.y).abs();
    final rightLift = (rightAnkle.y - rightHeel.y).abs();
    return (leftLift + rightLift) / 2;
  }

  String _detectOrientation(
    PoseLandmark leftShoulder,
    PoseLandmark rightShoulder,
    PoseLandmark leftHip,
    PoseLandmark rightHip,
    PoseLandmark nose,
  ) {
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final hipWidth = (leftHip.x - rightHip.x).abs();
    final avgBodyWidth = (shoulderWidth + hipWidth) / 2;

    if (avgBodyWidth < 0.20) {
      return 'sideways';
    } else if (avgBodyWidth > 0.30) {
      return 'facing';
    } else {
      return 'sideways'; // Treat partial as acceptable
    }
  }

  double _calculateBackAlignment(
    PoseLandmark leftShoulder,
    PoseLandmark rightShoulder,
    PoseLandmark leftHip,
    PoseLandmark rightHip,
  ) {
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
