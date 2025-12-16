import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/workout_report.dart';
import 'exercise_logic.dart';

/// Service to generate detailed workout reports with form analysis
class WorkoutReportService {
  final List<RepAnalysis> _repAnalyses = [];
  final Map<String, int> _issueFrequency = {};
  DateTime? _startTime;
  String _exerciseType = 'Squats';
  int _currentRepNumber = 0;

  // Current rep tracking
  double _currentRepAccuracy = 0.0;
  double _currentKneeAngle = 0.0;
  double _currentHipAngle = 0.0;
  double _currentBackAlignment = 0.0;
  final List<FormIssue> _currentRepIssues = [];

  /// Start tracking a new workout
  void startWorkout(String exerciseType) {
    _exerciseType = exerciseType;
    _startTime = DateTime.now();
    _repAnalyses.clear();
    _issueFrequency.clear();
    _currentRepNumber = 0;
    _clearCurrentRep();
    debugPrint('WorkoutReportService: Started tracking $exerciseType workout');
  }

  void _clearCurrentRep() {
    _currentRepAccuracy = 0.0;
    _currentKneeAngle = 0.0;
    _currentHipAngle = 0.0;
    _currentBackAlignment = 0.0;
    _currentRepIssues.clear();
  }

  /// Process analysis result from exercise logic
  void processAnalysisResult(ExerciseAnalysisResult result) {
    if (result.additionalData == null) return;

    final data = result.additionalData!;

    // Update current rep metrics
    _currentKneeAngle = (data['avgKneeAngle'] as num?)?.toDouble() ?? 0.0;
    _currentHipAngle = (data['avgHipAngle'] as num?)?.toDouble() ?? 0.0;
    _currentBackAlignment = (data['backAlignment'] as num?)?.toDouble() ?? 0.0;
    _currentRepAccuracy = result.accuracy;

    // Check for form issues and record them
    _checkAndRecordFormIssues(data, result);

    // If rep completed, save the analysis
    if (result.isRepCompleted) {
      _completeRep(result.feedback);
    }
  }

  void _checkAndRecordFormIssues(
      Map<String, dynamic> data, ExerciseAnalysisResult result) {
    final kneeAngle = (data['avgKneeAngle'] as num?)?.toDouble() ?? 180.0;
    final hipAngle = (data['avgHipAngle'] as num?)?.toDouble() ?? 90.0;
    final backAlignment = (data['backAlignment'] as num?)?.toDouble() ?? 1.0;

    // Check for insufficient depth
    if (kneeAngle > 105 && kneeAngle < 160) {
      _addFormIssue(
        SquatFormIssues.insufficientDepth,
        SquatFormIssues.insufficientDepthDesc,
        SquatFormIssues.insufficientDepthFix,
        0.6,
      );
    }

    // Check for excessive depth
    if (kneeAngle < 70) {
      _addFormIssue(
        SquatFormIssues.excessiveDepth,
        SquatFormIssues.excessiveDepthDesc,
        SquatFormIssues.excessiveDepthFix,
        0.5,
      );
    }

    // Check for back rounding
    if (backAlignment < 0.65) {
      _addFormIssue(
        SquatFormIssues.backRounding,
        SquatFormIssues.backRoundingDesc,
        SquatFormIssues.backRoundingFix,
        0.8,
      );
    }

    // Check for forward lean (hip angle too small)
    if (hipAngle < 50) {
      _addFormIssue(
        SquatFormIssues.forwardLean,
        SquatFormIssues.forwardLeanDesc,
        SquatFormIssues.forwardLeanFix,
        0.7,
      );
    }

    // Check for knees going too far forward (approximated)
    if (hipAngle > 120 && kneeAngle < 90) {
      _addFormIssue(
        SquatFormIssues.kneeOverToe,
        SquatFormIssues.kneeOverToeDesc,
        SquatFormIssues.kneeOverToeFix,
        0.6,
      );
    }
  }

  void _addFormIssue(
    String issueType,
    String description,
    String correction,
    double severity,
  ) {
    // Check if this issue already exists for current rep
    if (_currentRepIssues.any((i) => i.issueType == issueType)) return;

    _currentRepIssues.add(FormIssue(
      issueType: issueType,
      description: description,
      correction: correction,
      severity: severity,
      repNumber: _currentRepNumber + 1,
      timestamp: DateTime.now(),
    ));

    // Track frequency
    _issueFrequency[description] = (_issueFrequency[description] ?? 0) + 1;
  }

  void _completeRep(String feedback) {
    _currentRepNumber++;

    final repAnalysis = RepAnalysis(
      repNumber: _currentRepNumber,
      accuracy: _currentRepAccuracy,
      kneeAngle: _currentKneeAngle,
      hipAngle: _currentHipAngle,
      backAlignment: _currentBackAlignment,
      issues: List.from(_currentRepIssues),
      overallFeedback: feedback,
      timestamp: DateTime.now(),
    );

    _repAnalyses.add(repAnalysis);
    debugPrint(
        'WorkoutReportService: Rep $_currentRepNumber completed - Accuracy: ${_currentRepAccuracy.toStringAsFixed(1)}%, Issues: ${_currentRepIssues.length}');

    _clearCurrentRep();
  }

  /// Generate the final workout report
  WorkoutReport generateReport() {
    final endTime = DateTime.now();
    final durationSeconds =
        _startTime != null ? endTime.difference(_startTime!).inSeconds : 0;

    // Calculate average accuracy
    double avgAccuracy = 0.0;
    if (_repAnalyses.isNotEmpty) {
      avgAccuracy =
          _repAnalyses.map((r) => r.accuracy).reduce((a, b) => a + b) /
              _repAnalyses.length;
    }

    // Generate strengths
    final strengths = _generateStrengths(avgAccuracy);

    // Generate areas to improve
    final areasToImprove = _generateAreasToImprove();

    // Generate overall assessment
    final overallAssessment = _generateOverallAssessment(avgAccuracy);

    // Generate coaching tips
    final coachingTips = _generateCoachingTips();

    final report = WorkoutReport(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      exerciseType: _exerciseType,
      startTime: _startTime ?? DateTime.now(),
      endTime: endTime,
      totalReps: _repAnalyses.length,
      averageAccuracy: avgAccuracy,
      repAnalyses: List.from(_repAnalyses),
      issueFrequency: Map.from(_issueFrequency),
      strengths: strengths,
      areasToImprove: areasToImprove,
      overallAssessment: overallAssessment,
      coachingTips: coachingTips,
      durationSeconds: durationSeconds,
    );

    debugPrint(
        'WorkoutReportService: Generated report - ${report.totalReps} reps, ${avgAccuracy.toStringAsFixed(1)}% accuracy');

    return report;
  }

  List<String> _generateStrengths(double avgAccuracy) {
    final strengths = <String>[];

    if (avgAccuracy >= 80) {
      strengths.add('Good overall form consistency');
    }

    final perfectReps =
        _repAnalyses.where((r) => r.accuracy >= 90 && !r.hasIssues).length;
    if (perfectReps > 0) {
      strengths.add('$perfectReps perfect reps with excellent form');
    }

    // Check if back was mostly straight
    final goodBackReps =
        _repAnalyses.where((r) => r.backAlignment >= 0.7).length;
    if (goodBackReps >= _repAnalyses.length * 0.7) {
      strengths.add('Good back posture throughout the workout');
    }

    // Check for proper depth
    final properDepthReps = _repAnalyses
        .where((r) => r.kneeAngle >= 70 && r.kneeAngle <= 105)
        .length;
    if (properDepthReps >= _repAnalyses.length * 0.6) {
      strengths.add('Consistent squat depth');
    }

    // Check completion
    if (_repAnalyses.length >= 5) {
      strengths.add('Good workout volume with ${_repAnalyses.length} reps');
    }

    if (strengths.isEmpty) {
      strengths.add('Completed the workout - keep practicing!');
    }

    return strengths;
  }

  List<String> _generateAreasToImprove() {
    final improvements = <String>[];

    // Sort issues by frequency
    final sortedIssues = _issueFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 3 most common issues
    for (int i = 0; i < sortedIssues.length && i < 3; i++) {
      final issue = sortedIssues[i];
      if (issue.value >= 2) {
        // Only report issues that occurred multiple times
        improvements.add('${issue.key} (occurred ${issue.value} times)');
      }
    }

    // Check average accuracy
    final avgAccuracy = _repAnalyses.isNotEmpty
        ? _repAnalyses.map((r) => r.accuracy).reduce((a, b) => a + b) /
            _repAnalyses.length
        : 0.0;

    if (avgAccuracy < 70) {
      improvements.add('Focus on form over speed');
    }

    if (improvements.isEmpty) {
      improvements.add('Keep up the good work! Minor refinements only.');
    }

    return improvements;
  }

  String _generateOverallAssessment(double avgAccuracy) {
    final totalReps = _repAnalyses.length;
    final perfectReps =
        _repAnalyses.where((r) => r.accuracy >= 90 && !r.hasIssues).length;

    if (avgAccuracy >= 90) {
      return 'Outstanding workout! Your form is excellent. You completed $totalReps reps '
          'with $perfectReps perfect reps. Your technique shows great consistency and control.';
    } else if (avgAccuracy >= 80) {
      return 'Great workout! You showed good form overall with $totalReps completed reps. '
          'There are a few minor areas to refine, but your foundation is solid.';
    } else if (avgAccuracy >= 70) {
      return 'Good effort! You completed $totalReps reps. Focus on the improvement areas below '
          'to enhance your form and get more out of each rep.';
    } else if (avgAccuracy >= 60) {
      return 'Keep practicing! You completed $totalReps reps. Review the form corrections below '
          'and try focusing on one improvement at a time in your next workout.';
    } else {
      return 'You completed $totalReps reps. Form needs attention - consider watching tutorial videos '
          'or working with a trainer to improve your technique. Safety first!';
    }
  }

  String _generateCoachingTips() {
    final tips = <String>[];

    // Based on most common issues
    if (_issueFrequency.containsKey(SquatFormIssues.backRoundingDesc)) {
      tips.add(
          '💡 To keep your back straight: Look slightly up, engage your core before descending, '
          'and imagine pulling your shoulder blades together.');
    }

    if (_issueFrequency.containsKey(SquatFormIssues.insufficientDepthDesc)) {
      tips.add(
          '💡 For better depth: Work on hip mobility, try box squats to learn the proper depth, '
          'and ensure your heels stay planted.');
    }

    if (_issueFrequency.containsKey(SquatFormIssues.forwardLeanDesc)) {
      tips.add(
          '💡 To prevent forward lean: Push your hips back first, keep your chest proud, '
          'and think about sitting into a chair behind you.');
    }

    if (_issueFrequency.containsKey(SquatFormIssues.excessiveDepthDesc)) {
      tips.add('💡 Stop at parallel: Going too deep can round your lower back. '
          'Focus on thighs parallel to the ground.');
    }

    if (_issueFrequency.containsKey(SquatFormIssues.kneeOverToeDesc)) {
      tips.add(
          '💡 Knees over toes: Sit back more into your hips, keep weight on heels, '
          'and ensure knees track over your toes, not past them.');
    }

    // General tips if no specific issues
    if (tips.isEmpty) {
      tips.add('💡 Great form! To continue improving, try adding tempo squats '
          '(3 seconds down, 2 seconds up) to build more control.');
    }

    // Add breathing tip
    tips.add(
        '🌬️ Remember: Breathe in as you lower down, brace your core at the bottom, '
        'and exhale forcefully as you push up.');

    return tips.join('\n\n');
  }

  /// Save report to local storage
  Future<String?> saveReport(WorkoutReport report) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final reportsDir =
          Directory(p.join(appDir.path, 'bema', 'workout_reports'));
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final fileName = 'report_${report.startTime.millisecondsSinceEpoch}.json';
      final file = File(p.join(reportsDir.path, fileName));
      await file.writeAsString(report.toJsonString());

      debugPrint('WorkoutReportService: Saved report to ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('WorkoutReportService: Error saving report: $e');
      return null;
    }
  }

  /// Load report from file path
  static Future<WorkoutReport?> loadReport(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        return WorkoutReport.fromJsonString(content);
      }
    } catch (e) {
      debugPrint('WorkoutReportService: Error loading report: $e');
    }
    return null;
  }

  /// Get voice feedback for current analysis - improved and more specific
  String getVoiceFeedback(ExerciseAnalysisResult result) {
    if (result.additionalData == null) return result.feedback;

    final data = result.additionalData!;
    final kneeAngle = (data['avgKneeAngle'] as num?)?.toDouble() ?? 180.0;
    final backAlignment = (data['backAlignment'] as num?)?.toDouble() ?? 1.0;
    final hipAngle = (data['avgHipAngle'] as num?)?.toDouble() ?? 90.0;

    // Priority-based voice feedback for real-time coaching
    // 1. Safety issues first
    if (backAlignment < 0.55) {
      return 'Stop! Straighten your back. Risk of injury.';
    }

    // 2. Depth guidance during descent
    if (kneeAngle > 130 && kneeAngle < 160) {
      return 'Keep going down. Push hips back.';
    }

    if (kneeAngle > 105 && kneeAngle < 130) {
      return 'Lower. Almost at parallel.';
    }

    // 3. At bottom position
    if (kneeAngle >= 70 && kneeAngle <= 105) {
      if (backAlignment >= 0.7) {
        return 'Perfect depth! Push through heels.';
      } else if (backAlignment >= 0.55) {
        return 'Good depth. Keep chest up!';
      }
    }

    // 4. Too deep
    if (kneeAngle < 70) {
      return 'Too deep! Stop at parallel.';
    }

    // 5. Forward lean check
    if (hipAngle < 50 && kneeAngle < 120) {
      return 'Leaning forward! Chest up!';
    }

    // 6. Coming up
    if (kneeAngle > 130 && result.feedback.contains('coming')) {
      return 'Drive up! Squeeze glutes.';
    }

    // 7. Rep completed - short feedback only
    if (result.isRepCompleted) {
      if (result.accuracy >= 90) {
        return 'Excellent!';
      } else if (result.accuracy >= 75) {
        return 'Good!';
      } else {
        return 'Done. Better form!';
      }
    }

    // Default to analysis feedback
    return result.feedback;
  }

  /// Get detailed correction cue for specific issues
  String getCorrectionCue(String issueType) {
    switch (issueType) {
      case SquatFormIssues.kneeValgus:
        return 'Push knees out!';
      case SquatFormIssues.insufficientDepth:
        return 'Go deeper!';
      case SquatFormIssues.excessiveDepth:
        return 'Stop at parallel!';
      case SquatFormIssues.backRounding:
        return 'Chest up! Back straight!';
      case SquatFormIssues.forwardLean:
        return 'Sit back more!';
      case SquatFormIssues.heelsLifting:
        return 'Heels down!';
      case SquatFormIssues.kneeOverToe:
        return 'Hips back! Knees stay behind toes!';
      default:
        return 'Check your form!';
    }
  }

  /// Reset the service for a new workout
  void reset() {
    _repAnalyses.clear();
    _issueFrequency.clear();
    _startTime = null;
    _currentRepNumber = 0;
    _clearCurrentRep();
  }
}
