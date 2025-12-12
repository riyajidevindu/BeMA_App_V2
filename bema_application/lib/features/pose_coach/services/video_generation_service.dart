import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/pose_session.dart';
import 'workout_recording_service.dart';

/// Reference pose data for correct exercise form
class ReferencePose {
  final String phaseName; // e.g., "standing", "squat_down"
  final List<PoseLandmark> landmarks;
  final double progressPercentage; // 0.0 to 1.0 in exercise cycle

  ReferencePose({
    required this.phaseName,
    required this.landmarks,
    required this.progressPercentage,
  });
}

/// Processed workout data with skeleton overlays (frame-by-frame playback)
class ProcessedWorkout {
  final String outputDir;
  final List<String> framePaths;
  final int fps;
  final Duration totalDuration;
  final String exerciseType;
  final DateTime recordedAt;

  ProcessedWorkout({
    required this.outputDir,
    required this.framePaths,
    required this.fps,
    required this.totalDuration,
    required this.exerciseType,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'outputDir': outputDir,
        'framePaths': framePaths,
        'fps': fps,
        'totalDurationMs': totalDuration.inMilliseconds,
        'exerciseType': exerciseType,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory ProcessedWorkout.fromJson(Map<String, dynamic> json) {
    return ProcessedWorkout(
      outputDir: json['outputDir'] as String,
      framePaths: (json['framePaths'] as List).cast<String>(),
      fps: json['fps'] as int,
      totalDuration: Duration(milliseconds: json['totalDurationMs'] as int),
      exerciseType: json['exerciseType'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }
}

/// Service for generating processed workout frames with skeleton overlays
/// Uses frame-by-frame image processing instead of video encoding
class VideoGenerationService {
  static const int _outputFps = 10; // Playback FPS

  // Skeleton connections for body pose
  static const List<List<int>> _skeletonConnections = [
    // Torso
    [11, 12], // shoulders
    [11, 23],
    [12, 24], // shoulders to hips
    [23, 24], // hips
    // Left arm
    [11, 13],
    [13, 15], // shoulder to wrist
    // Right arm
    [12, 14],
    [14, 16], // shoulder to wrist
    // Left leg
    [23, 25],
    [25, 27], // hip to ankle
    // Right leg
    [24, 26],
    [26, 28], // hip to ankle
  ];

  /// Reference squat poses for different phases
  List<ReferencePose> _squatReferencePoses = [];

  VideoGenerationService() {
    _initializeReferencePoses();
  }

  void _initializeReferencePoses() {
    _squatReferencePoses = [
      // Standing phase (0%)
      ReferencePose(
        phaseName: 'standing',
        progressPercentage: 0.0,
        landmarks: _generateStandingPose(),
      ),
      // Quarter squat (25%)
      ReferencePose(
        phaseName: 'quarter_squat',
        progressPercentage: 0.25,
        landmarks: _generateQuarterSquatPose(),
      ),
      // Half squat (50%)
      ReferencePose(
        phaseName: 'half_squat',
        progressPercentage: 0.5,
        landmarks: _generateHalfSquatPose(),
      ),
      // Full squat (100%)
      ReferencePose(
        phaseName: 'full_squat',
        progressPercentage: 1.0,
        landmarks: _generateFullSquatPose(),
      ),
    ];
  }

  // Generate reference poses with normalized coordinates (0-1 range)
  List<PoseLandmark> _generateStandingPose() {
    return _createReferenceLandmarks(
      shoulderWidth: 0.3,
      hipHeight: 0.5,
      kneeHeight: 0.7,
      ankleHeight: 0.9,
      kneeBend: 0.0,
    );
  }

  List<PoseLandmark> _generateQuarterSquatPose() {
    return _createReferenceLandmarks(
      shoulderWidth: 0.3,
      hipHeight: 0.55,
      kneeHeight: 0.72,
      ankleHeight: 0.9,
      kneeBend: 0.05,
    );
  }

  List<PoseLandmark> _generateHalfSquatPose() {
    return _createReferenceLandmarks(
      shoulderWidth: 0.32,
      hipHeight: 0.62,
      kneeHeight: 0.75,
      ankleHeight: 0.9,
      kneeBend: 0.08,
    );
  }

  List<PoseLandmark> _generateFullSquatPose() {
    return _createReferenceLandmarks(
      shoulderWidth: 0.35,
      hipHeight: 0.72,
      kneeHeight: 0.78,
      ankleHeight: 0.9,
      kneeBend: 0.12,
    );
  }

  List<PoseLandmark> _createReferenceLandmarks({
    required double shoulderWidth,
    required double hipHeight,
    required double kneeHeight,
    required double ankleHeight,
    required double kneeBend,
  }) {
    final landmarks = <PoseLandmark>[];
    const centerX = 0.5;

    // Create 33 landmarks for MediaPipe Pose
    // 0-10: Face landmarks
    for (int i = 0; i <= 10; i++) {
      landmarks.add(PoseLandmark(
          x: centerX, y: 0.15, z: 0, visibility: 0.5)); // Face placeholders
    }

    // 11-12: Shoulders
    landmarks.add(PoseLandmark(
        x: centerX - shoulderWidth / 2,
        y: 0.28,
        z: 0,
        visibility: 1)); // 11: left shoulder
    landmarks.add(PoseLandmark(
        x: centerX + shoulderWidth / 2,
        y: 0.28,
        z: 0,
        visibility: 1)); // 12: right shoulder

    // 13-16: Arms (elbows and wrists)
    landmarks.add(PoseLandmark(
        x: centerX - shoulderWidth / 2 - 0.05,
        y: 0.38,
        z: 0,
        visibility: 1)); // 13: left elbow
    landmarks.add(PoseLandmark(
        x: centerX + shoulderWidth / 2 + 0.05,
        y: 0.38,
        z: 0,
        visibility: 1)); // 14: right elbow
    landmarks.add(PoseLandmark(
        x: centerX - shoulderWidth / 2 - 0.02,
        y: 0.48,
        z: 0,
        visibility: 1)); // 15: left wrist
    landmarks.add(PoseLandmark(
        x: centerX + shoulderWidth / 2 + 0.02,
        y: 0.48,
        z: 0,
        visibility: 1)); // 16: right wrist

    // 17-22: Hands (placeholders)
    for (int i = 17; i <= 22; i++) {
      landmarks.add(
          PoseLandmark(x: centerX, y: 0.50, z: 0, visibility: 0.5)); // Hands
    }

    // 23-24: Hips
    landmarks.add(PoseLandmark(
        x: centerX - 0.12, y: hipHeight, z: 0, visibility: 1)); // 23: left hip
    landmarks.add(PoseLandmark(
        x: centerX + 0.12, y: hipHeight, z: 0, visibility: 1)); // 24: right hip

    // 25-26: Knees
    landmarks.add(PoseLandmark(
        x: centerX - 0.12 - kneeBend,
        y: kneeHeight,
        z: 0,
        visibility: 1)); // 25: left knee
    landmarks.add(PoseLandmark(
        x: centerX + 0.12 + kneeBend,
        y: kneeHeight,
        z: 0,
        visibility: 1)); // 26: right knee

    // 27-28: Ankles
    landmarks.add(PoseLandmark(
        x: centerX - 0.12,
        y: ankleHeight,
        z: 0,
        visibility: 1)); // 27: left ankle
    landmarks.add(PoseLandmark(
        x: centerX + 0.12,
        y: ankleHeight,
        z: 0,
        visibility: 1)); // 28: right ankle

    // 29-32: Feet (placeholders)
    for (int i = 29; i <= 32; i++) {
      landmarks.add(
          PoseLandmark(x: centerX, y: 0.92, z: 0, visibility: 0.5)); // Feet
    }

    return landmarks;
  }

  /// Get reference pose based on user's current squat depth
  ReferencePose? getReferencePoseForUserPose(
      List<PoseLandmark>? userLandmarks) {
    if (userLandmarks == null || userLandmarks.length < 28) {
      return _squatReferencePoses.first;
    }

    try {
      final leftHip = userLandmarks[23];
      final leftKnee = userLandmarks[25];
      final leftAnkle = userLandmarks[27];

      // Calculate knee angle
      final angle = _calculateAngle(
        leftHip.x,
        leftHip.y,
        leftKnee.x,
        leftKnee.y,
        leftAnkle.x,
        leftAnkle.y,
      );

      // Map angle to squat depth
      final depth = ((180 - angle) / 90).clamp(0.0, 1.0);

      // Find closest reference pose
      ReferencePose? closest;
      double minDiff = double.infinity;
      for (final ref in _squatReferencePoses) {
        final diff = (ref.progressPercentage - depth).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = ref;
        }
      }

      return closest;
    } catch (e) {
      return _squatReferencePoses.first;
    }
  }

  double _calculateAngle(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    final v1x = x1 - x2;
    final v1y = y1 - y2;
    final v2x = x3 - x2;
    final v2y = y3 - y2;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = (v1x * v1x + v1y * v1y);
    final mag2 = (v2x * v2x + v2y * v2y);

    if (mag1 == 0 || mag2 == 0) return 180;

    final cosAngle = dot / (mag1 * mag2).abs();
    final angle = _acos(cosAngle.clamp(-1.0, 1.0)) * 180 / 3.14159265359;
    return angle;
  }

  double _acos(double x) {
    return 1.5707963267948966 - _asin(x);
  }

  double _asin(double x) {
    return x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
  }

  /// Process recorded frames with skeleton overlays
  /// Returns ProcessedWorkout with paths to all processed frames
  Future<ProcessedWorkout?> generateProcessedFrames({
    required String recordingDir,
    required String exerciseType,
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      onProgress(0.0, 'Loading frame data...');
      debugPrint('VideoGeneration: Starting from recording dir: $recordingDir');

      // Load frames metadata
      final metadataFile = File(p.join(recordingDir, 'frames_metadata.json'));
      if (!await metadataFile.exists()) {
        debugPrint(
            'VideoGeneration: Metadata file not found at ${metadataFile.path}');
        return null;
      }

      final metadataJson = await metadataFile.readAsString();
      final metadata = Map<String, dynamic>.from(
        jsonDecode(metadataJson) as Map,
      );

      debugPrint(
          'VideoGeneration: Metadata loaded - frameCount: ${metadata['frameCount']}');

      final framesData = (metadata['frames'] as List)
          .map((f) => RecordedFrame.fromJson(Map<String, dynamic>.from(f)))
          .toList();

      if (framesData.isEmpty) {
        debugPrint('VideoGeneration: No frames to process');
        return null;
      }

      // Count frames with valid images
      final framesWithImages =
          framesData.where((f) => f.imagePath != null).length;
      debugPrint(
          'VideoGeneration: Total frames: ${framesData.length}, Frames with images: $framesWithImages');

      if (framesWithImages == 0) {
        debugPrint('VideoGeneration: No frames have valid image paths!');
        return null;
      }

      onProgress(0.1, 'Processing ${framesData.length} frames...');

      // Create output directory for processed frames
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputDir =
          Directory(p.join(appDir.path, 'workouts', 'processed_$timestamp'));
      await outputDir.create(recursive: true);
      debugPrint(
          'VideoGeneration: Output directory created: ${outputDir.path}');

      final processedPaths = <String>[];
      int processedCount = 0;
      int skippedCount = 0;

      for (final frame in framesData) {
        if (frame.imagePath == null) {
          skippedCount++;
          continue;
        }

        final inputFile = File(frame.imagePath!);
        if (!inputFile.existsSync()) {
          debugPrint(
              'VideoGeneration: Frame ${frame.frameIndex} - file not found: ${frame.imagePath}');
          skippedCount++;
          continue;
        }

        final outputPath = p.join(
          outputDir.path,
          'frame_${frame.frameIndex.toString().padLeft(5, '0')}.jpg',
        );

        // Get reference pose for this frame
        final referencePose = getReferencePoseForUserPose(frame.userLandmarks);

        // Process frame with skeletons
        final success = await _processFrameWithSkeletons(
          inputPath: frame.imagePath!,
          outputPath: outputPath,
          userLandmarks: frame.userLandmarks,
          referenceLandmarks: referencePose?.landmarks,
        );

        if (success) {
          processedPaths.add(outputPath);
        }

        processedCount++;
        final progress = 0.1 + (0.85 * processedCount / framesData.length);
        onProgress(progress,
            'Processing frame $processedCount/${framesData.length}...');
      }

      debugPrint(
          'VideoGeneration: Processed $processedCount frames, skipped $skippedCount, success: ${processedPaths.length}');

      if (processedPaths.isEmpty) {
        debugPrint('VideoGeneration: No frames processed successfully');
        return null;
      }

      // Calculate total duration based on original recording
      final totalDuration = Duration(
          milliseconds: (framesData.length * 1000 / _outputFps).round());

      // Save processed workout metadata
      final workout = ProcessedWorkout(
        outputDir: outputDir.path,
        framePaths: processedPaths,
        fps: _outputFps,
        totalDuration: totalDuration,
        exerciseType: exerciseType,
        recordedAt: DateTime.now(),
      );

      final workoutMetaPath = p.join(outputDir.path, 'workout_metadata.json');
      await File(workoutMetaPath).writeAsString(
          const JsonEncoder.withIndent('  ').convert(workout.toJson()));

      onProgress(1.0, 'Processing complete!');
      debugPrint(
          'VideoGeneration: Processed ${processedPaths.length} frames to ${outputDir.path}');

      return workout;
    } catch (e) {
      debugPrint('VideoGeneration: Error processing frames: $e');
      return null;
    }
  }

  /// Process a single frame with skeleton overlays
  Future<bool> _processFrameWithSkeletons({
    required String inputPath,
    required String outputPath,
    List<PoseLandmark>? userLandmarks,
    List<PoseLandmark>? referenceLandmarks,
  }) async {
    try {
      // Load image
      final imageBytes = await File(inputPath).readAsBytes();
      var image = img.decodeImage(imageBytes);
      if (image == null) return false;

      final width = image.width;
      final height = image.height;

      // Draw reference skeleton (GREEN) first (behind user skeleton)
      if (referenceLandmarks != null && referenceLandmarks.isNotEmpty) {
        _drawSkeleton(image, referenceLandmarks, width, height,
            img.ColorRgba8(0, 255, 0, 180)); // Green with transparency
      }

      // Draw user skeleton (RED) on top
      if (userLandmarks != null && userLandmarks.isNotEmpty) {
        _drawSkeleton(image, userLandmarks, width, height,
            img.ColorRgba8(255, 0, 0, 255)); // Red, full opacity
      }

      // Save processed image
      await File(outputPath).writeAsBytes(img.encodeJpg(image, quality: 85));
      return true;
    } catch (e) {
      debugPrint('Error processing frame: $e');
      return false;
    }
  }

  /// Draw skeleton on image
  void _drawSkeleton(img.Image image, List<PoseLandmark> landmarks, int width,
      int height, img.Color color) {
    if (landmarks.isEmpty) return;

    // Draw connections
    for (final conn in _skeletonConnections) {
      if (conn[0] >= landmarks.length || conn[1] >= landmarks.length) continue;

      final p1 = landmarks[conn[0]];
      final p2 = landmarks[conn[1]];

      if (p1.visibility < 0.5 || p2.visibility < 0.5) continue;

      final x1 = (p1.x * width).round().clamp(0, width - 1);
      final y1 = (p1.y * height).round().clamp(0, height - 1);
      final x2 = (p2.x * width).round().clamp(0, width - 1);
      final y2 = (p2.y * height).round().clamp(0, height - 1);

      img.drawLine(image,
          x1: x1, y1: y1, x2: x2, y2: y2, color: color, thickness: 4);
    }

    // Draw joints as circles
    final jointIndices = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28];
    for (final i in jointIndices) {
      if (i >= landmarks.length) continue;
      final landmark = landmarks[i];
      if (landmark.visibility < 0.5) continue;

      final x = (landmark.x * width).round().clamp(0, width - 1);
      final y = (landmark.y * height).round().clamp(0, height - 1);

      img.fillCircle(image, x: x, y: y, radius: 6, color: color);
    }
  }

  /// Clean up temporary recording directory
  Future<void> cleanupRecordingDir(String recordingDir) async {
    try {
      final dir = Directory(recordingDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error cleaning up recording dir: $e');
    }
  }
}
