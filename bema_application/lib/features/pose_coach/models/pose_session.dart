// Model for pose session data
class PoseSession {
  final String userId;
  final String exercise;
  final int reps;
  final double accuracy;
  final DateTime timestamp;
  final int duration; // in seconds
  final List<String>? feedbackPoints;
  final String? videoPath; // optional local video file path
  final String? reportPath; // optional workout report JSON path

  PoseSession({
    required this.userId,
    required this.exercise,
    required this.reps,
    required this.accuracy,
    required this.timestamp,
    required this.duration,
    this.feedbackPoints,
    this.videoPath,
    this.reportPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'exercise': exercise,
      'reps': reps,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration,
      'feedback_points': feedbackPoints,
      'video_path': videoPath,
      'report_path': reportPath,
    };
  }

  factory PoseSession.fromJson(Map<String, dynamic> json) {
    return PoseSession(
      userId: json['user_id'],
      exercise: json['exercise'],
      reps: json['reps'],
      accuracy: json['accuracy'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      duration: json['duration'],
      feedbackPoints: json['feedback_points'] != null
          ? List<String>.from(json['feedback_points'])
          : null,
      videoPath: json['video_path'],
      reportPath: json['report_path'],
    );
  }
}

// Model for pose landmarks
class PoseLandmark {
  final double x;
  final double y;
  final double z;
  final double visibility;

  PoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  factory PoseLandmark.fromMap(Map<String, dynamic> map) {
    return PoseLandmark(
      x: (map['x'] ?? 0.0).toDouble(),
      y: (map['y'] ?? 0.0).toDouble(),
      z: (map['z'] ?? 0.0).toDouble(),
      visibility: (map['visibility'] ?? 0.0).toDouble(),
    );
  }
}

// Model for squat analysis
class SquatAnalysis {
  final double hipAngle;
  final double kneeAngle;
  final double ankleAngle;
  final bool isCorrectForm;
  final String? feedback;

  SquatAnalysis({
    required this.hipAngle,
    required this.kneeAngle,
    required this.ankleAngle,
    required this.isCorrectForm,
    this.feedback,
  });
}
