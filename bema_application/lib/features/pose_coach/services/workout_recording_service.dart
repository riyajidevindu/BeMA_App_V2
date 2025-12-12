import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/pose_session.dart';

/// Frame data with pose landmarks and timestamp
class RecordedFrame {
  final int frameIndex;
  final DateTime timestamp;
  final List<PoseLandmark>? userLandmarks;
  final String? imagePath;
  final int imageWidth;
  final int imageHeight;

  RecordedFrame({
    required this.frameIndex,
    required this.timestamp,
    this.userLandmarks,
    this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
  });

  Map<String, dynamic> toJson() => {
        'frameIndex': frameIndex,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'userLandmarks': userLandmarks
            ?.map((l) =>
                {'x': l.x, 'y': l.y, 'z': l.z, 'visibility': l.visibility})
            .toList(),
        'imagePath': imagePath,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
      };

  factory RecordedFrame.fromJson(Map<String, dynamic> json) {
    return RecordedFrame(
      frameIndex: json['frameIndex'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      userLandmarks: json['userLandmarks'] != null
          ? (json['userLandmarks'] as List)
              .map((m) => PoseLandmark.fromMap(m))
              .toList()
          : null,
      imagePath: json['imagePath'],
      imageWidth: json['imageWidth'],
      imageHeight: json['imageHeight'],
    );
  }
}

/// Service for recording workout frames during exercise
class WorkoutRecordingService {
  static const int _targetFps = 15; // Target frame rate for recording
  static const int _frameIntervalMs = 1000 ~/ _targetFps;

  Directory? _sessionDir;
  List<RecordedFrame> _frames = [];
  int _frameCounter = 0;
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  DateTime? _lastFrameTime;

  // Camera info for proper image conversion
  int _sensorOrientation = 0;
  bool _isFrontCamera = true;

  bool get isRecording => _isRecording;
  int get frameCount => _frames.length;
  List<RecordedFrame> get frames => List.unmodifiable(_frames);

  /// Set camera info for proper image rotation
  void setCameraInfo(int sensorOrientation, CameraLensDirection direction) {
    _sensorOrientation = sensorOrientation;
    _isFrontCamera = direction == CameraLensDirection.front;
  }

  /// Start a new recording session
  Future<bool> startRecording(String exerciseName) async {
    if (_isRecording) return false;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _sessionDir =
          Directory(p.join(tempDir.path, 'workout_recording_$timestamp'));
      await _sessionDir!.create(recursive: true);

      _frames = [];
      _frameCounter = 0;
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _lastFrameTime = null;

      debugPrint(
          'WorkoutRecordingService: Started recording to ${_sessionDir!.path}');
      return true;
    } catch (e) {
      debugPrint('WorkoutRecordingService: Error starting recording: $e');
      return false;
    }
  }

  /// Capture a frame from CameraImage with pose landmarks
  /// Returns true if frame was captured, false if skipped (rate limiting)
  Future<bool> captureFrame(
    CameraImage cameraImage,
    List<PoseLandmark>? landmarks,
  ) async {
    if (!_isRecording || _sessionDir == null) return false;

    // Rate limiting - only capture at target FPS
    final now = DateTime.now();
    if (_lastFrameTime != null &&
        now.difference(_lastFrameTime!).inMilliseconds < _frameIntervalMs) {
      return false;
    }
    _lastFrameTime = now;

    try {
      final frameIndex = _frameCounter++;
      final imagePath = p.join(_sessionDir!.path, 'frame_$frameIndex.jpg');

      // Log first frame for debugging
      if (frameIndex == 0) {
        debugPrint(
            'WorkoutRecordingService: First frame - ${cameraImage.width}x${cameraImage.height}, planes: ${cameraImage.planes.length}');
        if (cameraImage.planes.isNotEmpty) {
          debugPrint(
              'WorkoutRecordingService: Plane 0 bytesPerRow: ${cameraImage.planes[0].bytesPerRow}, length: ${cameraImage.planes[0].bytes.length}');
        }
      }

      // Convert CameraImage to JPEG in isolate to avoid blocking UI
      final imageBytes = await compute(_convertCameraImageToJpeg, {
        'planes': cameraImage.planes.map((p) => p.bytes).toList(),
        'width': cameraImage.width,
        'height': cameraImage.height,
        'bytesPerRow': cameraImage.planes.isNotEmpty
            ? cameraImage.planes[0].bytesPerRow
            : 0,
        'sensorOrientation': _sensorOrientation,
        'isFrontCamera': _isFrontCamera,
      });

      if (imageBytes != null) {
        await File(imagePath).writeAsBytes(imageBytes);
        // Log every 30th frame (about every 2 seconds at 15fps)
        if (frameIndex % 30 == 0) {
          debugPrint(
              'WorkoutRecordingService: Frame $frameIndex saved (${imageBytes.length} bytes)');
        }
      } else {
        debugPrint(
            'WorkoutRecordingService: Frame $frameIndex - image conversion returned null');
      }

      final frame = RecordedFrame(
        frameIndex: frameIndex,
        timestamp: now,
        userLandmarks: landmarks,
        imagePath: imageBytes != null ? imagePath : null,
        imageWidth: cameraImage.width,
        imageHeight: cameraImage.height,
      );

      _frames.add(frame);

      return true;
    } catch (e) {
      debugPrint('WorkoutRecordingService: Error capturing frame: $e');
      return false;
    }
  }

  /// Stop recording and return the session directory path
  Future<String?> stopRecording() async {
    if (!_isRecording || _sessionDir == null) return null;

    _isRecording = false;

    // Count frames with valid images
    final framesWithImages = _frames.where((f) => f.imagePath != null).length;
    debugPrint(
        'WorkoutRecordingService: Stopping - Total frames: ${_frames.length}, Frames with images: $framesWithImages');

    try {
      // Save frames metadata
      final metadataPath = p.join(_sessionDir!.path, 'frames_metadata.json');
      final metadata = {
        'frameCount': _frames.length,
        'startTime': _recordingStartTime?.millisecondsSinceEpoch,
        'endTime': DateTime.now().millisecondsSinceEpoch,
        'targetFps': _targetFps,
        'frames': _frames.map((f) => f.toJson()).toList(),
      };
      await File(metadataPath).writeAsString(jsonEncode(metadata));

      debugPrint(
          'WorkoutRecordingService: Stopped recording. ${_frames.length} frames saved');
      return _sessionDir!.path;
    } catch (e) {
      debugPrint('WorkoutRecordingService: Error stopping recording: $e');
      return null;
    }
  }

  /// Clean up temporary recording files
  Future<void> cleanup() async {
    if (_sessionDir != null && await _sessionDir!.exists()) {
      try {
        await _sessionDir!.delete(recursive: true);
        debugPrint('WorkoutRecordingService: Cleaned up recording directory');
      } catch (e) {
        debugPrint('WorkoutRecordingService: Error cleaning up: $e');
      }
    }
    _frames = [];
    _frameCounter = 0;
    _sessionDir = null;
    _isRecording = false;
  }

  /// Get recording duration in seconds
  int getRecordingDuration() {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }
}

/// Convert CameraImage (YUV420/NV21) to JPEG bytes
/// This runs in an isolate to avoid blocking the main thread
/// Handles various Android camera formats including YUV_420_888 and NV21
Uint8List? _convertCameraImageToJpeg(Map<String, dynamic> params) {
  try {
    final planes = params['planes'] as List<Uint8List>;
    final width = params['width'] as int;
    final height = params['height'] as int;
    final bytesPerRow = params['bytesPerRow'] as int;
    final sensorOrientation = params['sensorOrientation'] as int;
    final isFrontCamera = params['isFrontCamera'] as bool;

    if (planes.isEmpty) {
      debugPrint('_convertCameraImageToJpeg: No planes available');
      return null;
    }

    // YUV420 to RGB conversion
    final yPlane = planes[0];

    // Create image
    final image = img.Image(width: width, height: height);

    // Check if we have UV planes
    if (planes.length >= 2) {
      // Android YUV_420_888 format - UV planes may be interleaved
      final uvPlane =
          planes[1]; // On many devices, this contains interleaved UV
      final hasThirdPlane = planes.length > 2;
      final vPlane = hasThirdPlane ? planes[2] : null;

      // Detect if UV is interleaved (pixel stride > 1 indicates interleaved)
      // For NV12/NV21: UV are interleaved in a single plane
      // For I420/YV12: UV are in separate planes
      final isInterleaved = !hasThirdPlane ||
          (uvPlane.length > (width * height / 4) &&
              vPlane != null &&
              vPlane.length > (width * height / 4));

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * bytesPerRow + x;
          if (yIndex >= yPlane.length) continue;

          int yValue = yPlane[yIndex];
          int uValue = 128;
          int vValue = 128;

          final uvRow = y ~/ 2;
          final uvCol = x ~/ 2;

          if (isInterleaved && uvPlane.length > 0) {
            // NV21/NV12 format - UV interleaved
            // NV21: VUVUVU... NV12: UVUVUV...
            final uvIndex = uvRow * bytesPerRow + uvCol * 2;
            if (uvIndex + 1 < uvPlane.length) {
              // Most Android devices use NV21 (VU order)
              vValue = uvPlane[uvIndex];
              uValue = uvPlane[uvIndex + 1];
            }
          } else if (vPlane != null) {
            // I420/YV12 format - separate U and V planes
            final uvBytesPerRow = bytesPerRow ~/ 2;
            final uvIndex = uvRow * uvBytesPerRow + uvCol;
            if (uvIndex < uvPlane.length) {
              uValue = uvPlane[uvIndex];
            }
            if (uvIndex < vPlane.length) {
              vValue = vPlane[uvIndex];
            }
          }

          // YUV to RGB conversion (BT.601 standard)
          final yNorm = yValue - 16;
          final uNorm = uValue - 128;
          final vNorm = vValue - 128;

          int r = ((298 * yNorm + 409 * vNorm + 128) >> 8).clamp(0, 255);
          int g = ((298 * yNorm - 100 * uNorm - 208 * vNorm + 128) >> 8)
              .clamp(0, 255);
          int b = ((298 * yNorm + 516 * uNorm + 128) >> 8).clamp(0, 255);

          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    } else {
      // Only Y plane available - create grayscale image
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * bytesPerRow + x;
          if (yIndex >= yPlane.length) continue;
          int yValue = yPlane[yIndex].clamp(0, 255);
          image.setPixelRgba(x, y, yValue, yValue, yValue, 255);
        }
      }
    }

    // Apply rotation based on sensor orientation
    img.Image rotatedImage;
    if (sensorOrientation == 90) {
      rotatedImage = img.copyRotate(image, angle: 90);
    } else if (sensorOrientation == 270) {
      rotatedImage = img.copyRotate(image, angle: -90);
    } else if (sensorOrientation == 180) {
      rotatedImage = img.copyRotate(image, angle: 180);
    } else {
      rotatedImage = image;
    }

    // Mirror for front camera
    if (isFrontCamera) {
      rotatedImage = img.flipHorizontal(rotatedImage);
    }

    // Encode to JPEG
    return Uint8List.fromList(img.encodeJpg(rotatedImage, quality: 80));
  } catch (e) {
    debugPrint('Error converting camera image: $e');
    return null;
  }
}
