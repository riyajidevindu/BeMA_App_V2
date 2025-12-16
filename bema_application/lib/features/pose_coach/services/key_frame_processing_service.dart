import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/pose_session.dart';
import 'key_frame_service.dart';

/// Service for processing key frames with skeleton overlays
class KeyFrameProcessingService {
  // Skeleton connections for body pose
  static const List<List<int>> _skeletonConnections = [
    // Torso
    [11, 12], // shoulders
    [11, 23], [12, 24], // shoulders to hips
    [23, 24], // hips
    // Left arm
    [11, 13], [13, 15], // shoulder to wrist
    // Right arm
    [12, 14], [14, 16], // shoulder to wrist
    // Left leg
    [23, 25], [25, 27], // hip to ankle
    // Right leg
    [24, 26], [26, 28], // hip to ankle
  ];

  /// Get reference pose for a squat phase
  List<PoseLandmark> getReferencePose(SquatPhase phase) {
    switch (phase) {
      case SquatPhase.standing:
        return _generateStandingPose();
      case SquatPhase.goingDown:
        return _generateGoingDownPose();
      case SquatPhase.bottomPosition:
        return _generateBottomPose();
      case SquatPhase.comingUp:
        return _generateComingUpPose();
    }
  }

  /// Process key frames with skeleton overlays
  /// Returns the path to the processed output directory
  Future<String?> processKeyFrames({
    required KeyFramePack keyFramePack,
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      onProgress(0.0, 'Processing key frames...');
      debugPrint(
          'KeyFrameProcessing: Starting with ${keyFramePack.keyFrames.length} frames');

      if (keyFramePack.keyFrames.isEmpty) {
        debugPrint('KeyFrameProcessing: No key frames to process');
        return null;
      }

      // Create output directory
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputDir =
          Directory(p.join(appDir.path, 'workouts', 'keyframes_$timestamp'));
      await outputDir.create(recursive: true);

      final processedFrames = <KeyFrame>[];
      int processedCount = 0;

      for (final frame in keyFramePack.keyFrames) {
        if (!File(frame.imagePath).existsSync()) {
          debugPrint('KeyFrameProcessing: Frame not found: ${frame.imagePath}');
          continue;
        }

        final outputPath = p.join(
          outputDir.path,
          'frame_${frame.repNumber}_${frame.phase.name}.jpg',
        );

        // Process frame with skeleton overlay
        final success = await _processFrameWithSkeleton(
          inputPath: frame.imagePath,
          outputPath: outputPath,
          userLandmarks: frame.userLandmarks,
          referenceLandmarks: getReferencePose(frame.phase),
          phase: frame.phase,
        );

        if (success) {
          processedFrames.add(KeyFrame(
            phase: frame.phase,
            phaseName: frame.phaseName,
            imagePath: outputPath,
            userLandmarks: frame.userLandmarks,
            kneeAngle: frame.kneeAngle,
            accuracy: frame.accuracy,
            timestamp: frame.timestamp,
            repNumber: frame.repNumber,
          ));
        }

        processedCount++;
        final progress = processedCount / keyFramePack.keyFrames.length;
        onProgress(progress * 0.9,
            'Processing frame $processedCount/${keyFramePack.keyFrames.length}...');
      }

      if (processedFrames.isEmpty) {
        debugPrint('KeyFrameProcessing: No frames processed successfully');
        return null;
      }

      // Save metadata
      final processedPack = KeyFramePack(
        outputDir: outputDir.path,
        keyFrames: processedFrames,
        exerciseType: keyFramePack.exerciseType,
        totalReps: keyFramePack.totalReps,
        averageAccuracy: keyFramePack.averageAccuracy,
        recordedAt: keyFramePack.recordedAt,
        durationSeconds: keyFramePack.durationSeconds,
      );

      final metaPath = p.join(outputDir.path, 'keyframes_metadata.json');
      await File(metaPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(processedPack.toJson()),
      );

      onProgress(1.0, 'Processing complete!');
      debugPrint(
          'KeyFrameProcessing: Processed ${processedFrames.length} frames to ${outputDir.path}');

      return outputDir.path;
    } catch (e) {
      debugPrint('KeyFrameProcessing: Error: $e');
      return null;
    }
  }

  /// Process a single frame with skeleton overlay
  Future<bool> _processFrameWithSkeleton({
    required String inputPath,
    required String outputPath,
    List<PoseLandmark>? userLandmarks,
    List<PoseLandmark>? referenceLandmarks,
    required SquatPhase phase,
  }) async {
    try {
      final imageBytes = await File(inputPath).readAsBytes();
      var image = img.decodeImage(imageBytes);
      if (image == null) return false;

      final width = image.width;
      final height = image.height;

      // Draw reference skeleton (GREEN) first - correct form
      if (referenceLandmarks != null && referenceLandmarks.isNotEmpty) {
        _drawSkeleton(
          image,
          referenceLandmarks,
          width,
          height,
          img.ColorRgba8(0, 220, 0, 200), // Green
          lineThickness: 6,
          jointRadius: 8,
        );
      }

      // Draw user skeleton (RED) on top - actual pose
      if (userLandmarks != null && userLandmarks.isNotEmpty) {
        _drawSkeleton(
          image,
          userLandmarks,
          width,
          height,
          img.ColorRgba8(255, 50, 50, 255), // Red
          lineThickness: 4,
          jointRadius: 6,
        );
      }

      // Add phase label at the top
      _drawPhaseLabel(image, phase);

      // Save processed image with high quality
      await File(outputPath).writeAsBytes(img.encodeJpg(image, quality: 95));
      return true;
    } catch (e) {
      debugPrint('Error processing frame: $e');
      return false;
    }
  }

  void _drawSkeleton(
    img.Image image,
    List<PoseLandmark> landmarks,
    int width,
    int height,
    img.Color color, {
    int lineThickness = 4,
    int jointRadius = 6,
  }) {
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
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: color,
          thickness: lineThickness);
    }

    // Draw joints
    final jointIndices = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28];
    for (final i in jointIndices) {
      if (i >= landmarks.length) continue;
      final landmark = landmarks[i];
      if (landmark.visibility < 0.5) continue;

      final x = (landmark.x * width).round().clamp(0, width - 1);
      final y = (landmark.y * height).round().clamp(0, height - 1);

      img.fillCircle(image, x: x, y: y, radius: jointRadius, color: color);
    }
  }

  void _drawPhaseLabel(img.Image image, SquatPhase phase) {
    // Draw a semi-transparent background at the top
    const labelHeight = 40;
    final bgColor = img.ColorRgba8(0, 0, 0, 180);

    for (int y = 0; y < labelHeight; y++) {
      for (int x = 0; x < image.width; x++) {
        image.setPixel(x, y, bgColor);
      }
    }
  }

  // Generate reference poses for each squat phase
  static List<PoseLandmark> _generateStandingPose() {
    return _createReferenceLandmarks(
      hipHeight: 0.50,
      kneeHeight: 0.70,
      ankleHeight: 0.90,
      kneeBend: 0.0,
    );
  }

  static List<PoseLandmark> _generateGoingDownPose() {
    return _createReferenceLandmarks(
      hipHeight: 0.55,
      kneeHeight: 0.72,
      ankleHeight: 0.90,
      kneeBend: 0.04,
    );
  }

  static List<PoseLandmark> _generateBottomPose() {
    return _createReferenceLandmarks(
      hipHeight: 0.68,
      kneeHeight: 0.76,
      ankleHeight: 0.90,
      kneeBend: 0.10,
    );
  }

  static List<PoseLandmark> _generateComingUpPose() {
    return _createReferenceLandmarks(
      hipHeight: 0.58,
      kneeHeight: 0.73,
      ankleHeight: 0.90,
      kneeBend: 0.05,
    );
  }

  static List<PoseLandmark> _createReferenceLandmarks({
    required double hipHeight,
    required double kneeHeight,
    required double ankleHeight,
    required double kneeBend,
  }) {
    final landmarks = <PoseLandmark>[];
    const centerX = 0.5;
    const shoulderWidth = 0.30;

    // 0-10: Face landmarks (placeholders)
    for (int i = 0; i <= 10; i++) {
      landmarks.add(PoseLandmark(x: centerX, y: 0.15, z: 0, visibility: 0.5));
    }

    // 11-12: Shoulders
    landmarks.add(PoseLandmark(
        x: centerX - shoulderWidth / 2, y: 0.28, z: 0, visibility: 1));
    landmarks.add(PoseLandmark(
        x: centerX + shoulderWidth / 2, y: 0.28, z: 0, visibility: 1));

    // 13-16: Arms
    landmarks.add(PoseLandmark(
        x: centerX - shoulderWidth / 2 - 0.05, y: 0.38, z: 0, visibility: 1));
    landmarks.add(PoseLandmark(
        x: centerX + shoulderWidth / 2 + 0.05, y: 0.38, z: 0, visibility: 1));
    landmarks.add(PoseLandmark(
        x: centerX - shoulderWidth / 2 - 0.02, y: 0.48, z: 0, visibility: 1));
    landmarks.add(PoseLandmark(
        x: centerX + shoulderWidth / 2 + 0.02, y: 0.48, z: 0, visibility: 1));

    // 17-22: Hands (placeholders)
    for (int i = 17; i <= 22; i++) {
      landmarks.add(PoseLandmark(x: centerX, y: 0.50, z: 0, visibility: 0.5));
    }

    // 23-24: Hips
    landmarks.add(
        PoseLandmark(x: centerX - 0.12, y: hipHeight, z: 0, visibility: 1));
    landmarks.add(
        PoseLandmark(x: centerX + 0.12, y: hipHeight, z: 0, visibility: 1));

    // 25-26: Knees
    landmarks.add(PoseLandmark(
        x: centerX - 0.12 - kneeBend, y: kneeHeight, z: 0, visibility: 1));
    landmarks.add(PoseLandmark(
        x: centerX + 0.12 + kneeBend, y: kneeHeight, z: 0, visibility: 1));

    // 27-28: Ankles
    landmarks.add(
        PoseLandmark(x: centerX - 0.12, y: ankleHeight, z: 0, visibility: 1));
    landmarks.add(
        PoseLandmark(x: centerX + 0.12, y: ankleHeight, z: 0, visibility: 1));

    // 29-32: Feet (placeholders)
    for (int i = 29; i <= 32; i++) {
      landmarks.add(PoseLandmark(x: centerX, y: 0.92, z: 0, visibility: 0.5));
    }

    return landmarks;
  }
}
