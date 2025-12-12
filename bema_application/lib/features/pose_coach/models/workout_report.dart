import 'dart:convert';

/// Represents a specific form issue detected during exercise
class FormIssue {
  final String issueType;
  final String description;
  final String correction;
  final double severity; // 0.0 to 1.0
  final int repNumber;
  final DateTime timestamp;

  FormIssue({
    required this.issueType,
    required this.description,
    required this.correction,
    required this.severity,
    required this.repNumber,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'issueType': issueType,
        'description': description,
        'correction': correction,
        'severity': severity,
        'repNumber': repNumber,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FormIssue.fromJson(Map<String, dynamic> json) => FormIssue(
        issueType: json['issueType'] as String,
        description: json['description'] as String,
        correction: json['correction'] as String,
        severity: (json['severity'] as num).toDouble(),
        repNumber: json['repNumber'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Analysis data for a single repetition
class RepAnalysis {
  final int repNumber;
  final double accuracy;
  final double kneeAngle;
  final double hipAngle;
  final double backAlignment;
  final List<FormIssue> issues;
  final String overallFeedback;
  final DateTime timestamp;

  RepAnalysis({
    required this.repNumber,
    required this.accuracy,
    required this.kneeAngle,
    required this.hipAngle,
    required this.backAlignment,
    required this.issues,
    required this.overallFeedback,
    required this.timestamp,
  });

  bool get hasIssues => issues.isNotEmpty;

  String get grade {
    if (accuracy >= 90) return 'Excellent';
    if (accuracy >= 80) return 'Good';
    if (accuracy >= 70) return 'Fair';
    if (accuracy >= 60) return 'Needs Work';
    return 'Poor';
  }

  Map<String, dynamic> toJson() => {
        'repNumber': repNumber,
        'accuracy': accuracy,
        'kneeAngle': kneeAngle,
        'hipAngle': hipAngle,
        'backAlignment': backAlignment,
        'issues': issues.map((i) => i.toJson()).toList(),
        'overallFeedback': overallFeedback,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RepAnalysis.fromJson(Map<String, dynamic> json) => RepAnalysis(
        repNumber: json['repNumber'] as int,
        accuracy: (json['accuracy'] as num).toDouble(),
        kneeAngle: (json['kneeAngle'] as num).toDouble(),
        hipAngle: (json['hipAngle'] as num).toDouble(),
        backAlignment: (json['backAlignment'] as num).toDouble(),
        issues: (json['issues'] as List)
            .map((i) => FormIssue.fromJson(i as Map<String, dynamic>))
            .toList(),
        overallFeedback: json['overallFeedback'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Common form issues for squats
class SquatFormIssues {
  static const String kneeValgus = 'knee_valgus';
  static const String kneeValgusDesc = 'Knees caving inward';
  static const String kneeValgusFix = 'Push your knees out over your toes';

  static const String insufficientDepth = 'insufficient_depth';
  static const String insufficientDepthDesc = 'Not going deep enough';
  static const String insufficientDepthFix =
      'Lower until thighs are parallel to ground';

  static const String excessiveDepth = 'excessive_depth';
  static const String excessiveDepthDesc = 'Going too deep';
  static const String excessiveDepthFix = 'Stop when thighs are parallel';

  static const String backRounding = 'back_rounding';
  static const String backRoundingDesc = 'Back is rounding forward';
  static const String backRoundingFix = 'Keep chest up and back straight';

  static const String forwardLean = 'forward_lean';
  static const String forwardLeanDesc = 'Leaning too far forward';
  static const String forwardLeanFix = 'Keep weight on heels, chest up';

  static const String hipShift = 'hip_shift';
  static const String hipShiftDesc = 'Hips shifting to one side';
  static const String hipShiftFix = 'Keep weight evenly distributed';

  static const String heelsLifting = 'heels_lifting';
  static const String heelsLiftingDesc = 'Heels coming off the ground';
  static const String heelsLiftingFix = 'Push through your heels';

  static const String kneeOverToe = 'knee_over_toe';
  static const String kneeOverToeDesc = 'Knees going too far over toes';
  static const String kneeOverToeFix = 'Sit back into your hips more';

  static const String fastMovement = 'fast_movement';
  static const String fastMovementDesc = 'Moving too quickly';
  static const String fastMovementFix =
      'Control the movement, 2-3 seconds each way';
}

/// Complete workout report
class WorkoutReport {
  final String id;
  final String exerciseType;
  final DateTime startTime;
  final DateTime endTime;
  final int totalReps;
  final double averageAccuracy;
  final List<RepAnalysis> repAnalyses;
  final Map<String, int> issueFrequency;
  final List<String> strengths;
  final List<String> areasToImprove;
  final String overallAssessment;
  final String coachingTips;
  final int durationSeconds;

  WorkoutReport({
    required this.id,
    required this.exerciseType,
    required this.startTime,
    required this.endTime,
    required this.totalReps,
    required this.averageAccuracy,
    required this.repAnalyses,
    required this.issueFrequency,
    required this.strengths,
    required this.areasToImprove,
    required this.overallAssessment,
    required this.coachingTips,
    required this.durationSeconds,
  });

  String get overallGrade {
    if (averageAccuracy >= 90) return 'A';
    if (averageAccuracy >= 80) return 'B';
    if (averageAccuracy >= 70) return 'C';
    if (averageAccuracy >= 60) return 'D';
    return 'F';
  }

  String get performanceLevel {
    if (averageAccuracy >= 90) return 'Excellent';
    if (averageAccuracy >= 80) return 'Good';
    if (averageAccuracy >= 70) return 'Fair';
    if (averageAccuracy >= 60) return 'Needs Improvement';
    return 'Keep Practicing';
  }

  int get perfectReps =>
      repAnalyses.where((r) => r.accuracy >= 90 && !r.hasIssues).length;

  int get goodReps =>
      repAnalyses.where((r) => r.accuracy >= 70 && r.accuracy < 90).length;

  int get poorReps => repAnalyses.where((r) => r.accuracy < 70).length;

  String get mostCommonIssue {
    if (issueFrequency.isEmpty) return 'None';
    final sorted = issueFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseType': exerciseType,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'totalReps': totalReps,
        'averageAccuracy': averageAccuracy,
        'repAnalyses': repAnalyses.map((r) => r.toJson()).toList(),
        'issueFrequency': issueFrequency,
        'strengths': strengths,
        'areasToImprove': areasToImprove,
        'overallAssessment': overallAssessment,
        'coachingTips': coachingTips,
        'durationSeconds': durationSeconds,
      };

  factory WorkoutReport.fromJson(Map<String, dynamic> json) => WorkoutReport(
        id: json['id'] as String,
        exerciseType: json['exerciseType'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        totalReps: json['totalReps'] as int,
        averageAccuracy: (json['averageAccuracy'] as num).toDouble(),
        repAnalyses: (json['repAnalyses'] as List)
            .map((r) => RepAnalysis.fromJson(r as Map<String, dynamic>))
            .toList(),
        issueFrequency: Map<String, int>.from(json['issueFrequency'] as Map),
        strengths: List<String>.from(json['strengths'] as List),
        areasToImprove: List<String>.from(json['areasToImprove'] as List),
        overallAssessment: json['overallAssessment'] as String,
        coachingTips: json['coachingTips'] as String,
        durationSeconds: json['durationSeconds'] as int,
      );

  String toJsonString() => jsonEncode(toJson());

  static WorkoutReport fromJsonString(String jsonString) =>
      WorkoutReport.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
