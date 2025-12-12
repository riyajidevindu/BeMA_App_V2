import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/pose_session.dart';

/// Represents a squat phase for key frame capture
enum SquatPhase {
  standing,
  goingDown,
  bottomPosition,
  comingUp,
}

/// A key frame captured at a specific squat phase
class KeyFrame {
  final SquatPhase phase;
  final String phaseName;
  final String imagePath;
  final List<PoseLandmark>? userLandmarks;
  final double kneeAngle;
  final double accuracy;
  final DateTime timestamp;
  final int repNumber;

  KeyFrame({
    required this.phase,
    required this.phaseName,
    required this.imagePath,
    this.userLandmarks,
    required this.kneeAngle,
    required this.accuracy,
    required this.timestamp,
    required this.repNumber,
  });

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'phaseName': phaseName,
        'imagePath': imagePath,
        'userLandmarks': userLandmarks
            ?.map((l) =>
                {'x': l.x, 'y': l.y, 'z': l.z, 'visibility': l.visibility})
            .toList(),
        'kneeAngle': kneeAngle,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'repNumber': repNumber,
      };

  factory KeyFrame.fromJson(Map<String, dynamic> json) {
    return KeyFrame(
      phase: SquatPhase.values.firstWhere((e) => e.name == json['phase']),
      phaseName: json['phaseName'] as String,
      imagePath: json['imagePath'] as String,
      userLandmarks: json['userLandmarks'] != null
          ? (json['userLandmarks'] as List)
              .map((m) => PoseLandmark.fromMap(m as Map<String, dynamic>))
              .toList()
          : null,
      kneeAngle: (json['kneeAngle'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      repNumber: json['repNumber'] as int,
    );
  }
}

/// A pack of key frames for one workout session
class KeyFramePack {
  final String outputDir;
  final List<KeyFrame> keyFrames;
  final String exerciseType;
  final int totalReps;
  final double averageAccuracy;
  final DateTime recordedAt;
  final int durationSeconds;

  KeyFramePack({
    required this.outputDir,
    required this.keyFrames,
    required this.exerciseType,
    required this.totalReps,
    required this.averageAccuracy,
    required this.recordedAt,
    required this.durationSeconds,
  });

  /// Get key frames grouped by rep number
  Map<int, List<KeyFrame>> get framesByRep {
    final map = <int, List<KeyFrame>>{};
    for (final frame in keyFrames) {
      map.putIfAbsent(frame.repNumber, () => []).add(frame);
    }
    return map;
  }

  /// Get the best frame for each phase (highest accuracy)
  List<KeyFrame> get bestFramesPerPhase {
    final phaseMap = <SquatPhase, KeyFrame>{};
    for (final frame in keyFrames) {
      final existing = phaseMap[frame.phase];
      if (existing == null || frame.accuracy > existing.accuracy) {
        phaseMap[frame.phase] = frame;
      }
    }
    return phaseMap.values.toList()
      ..sort((a, b) => a.phase.index.compareTo(b.phase.index));
  }

  Map<String, dynamic> toJson() => {
        'outputDir': outputDir,
        'keyFrames': keyFrames.map((f) => f.toJson()).toList(),
        'exerciseType': exerciseType,
        'totalReps': totalReps,
        'averageAccuracy': averageAccuracy,
        'recordedAt': recordedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  factory KeyFramePack.fromJson(Map<String, dynamic> json) {
    return KeyFramePack(
      outputDir: json['outputDir'] as String,
      keyFrames: (json['keyFrames'] as List)
          .map((f) => KeyFrame.fromJson(f as Map<String, dynamic>))
          .toList(),
      exerciseType: json['exerciseType'] as String,
      totalReps: json['totalReps'] as int,
      averageAccuracy: (json['averageAccuracy'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
    );
  }
}

/// Service for capturing key frames during squat exercise
class KeyFrameService {
  Directory? _sessionDir;
  final List<KeyFrame> _keyFrames = [];
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  // Camera info for proper image conversion
  int _sensorOrientation = 0;
  bool _isFrontCamera = true;

  // State tracking for squat phases
  SquatPhase _currentPhase = SquatPhase.standing;
  SquatPhase? _lastCapturedPhase;
  int _currentRepNumber = 0;
  double _lowestKneeAngle = 180.0;
  bool _capturedBottomThisRep = false;

  // Thresholds (based on squats_logic.dart)
  static const double _standingAngle = 160.0;
  static const double _squatAngle = 110.0;
  static const double _deepSquatAngle = 90.0;

  bool get isRecording => _isRecording;
  int get keyFrameCount => _keyFrames.length;
  List<KeyFrame> get keyFrames => List.unmodifiable(_keyFrames);

  /// Set camera info for proper image rotation
  void setCameraInfo(int sensorOrientation, CameraLensDirection direction) {
    _sensorOrientation = sensorOrientation;
    _isFrontCamera = direction == CameraLensDirection.front;
  }

  /// Start recording key frames
  Future<bool> startRecording(String exerciseName) async {
    if (_isRecording) return false;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _sessionDir = Directory(p.join(tempDir.path, 'keyframes_$timestamp'));
      await _sessionDir!.create(recursive: true);

      _keyFrames.clear();
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _currentPhase = SquatPhase.standing;
      _lastCapturedPhase = null;
      _currentRepNumber = 0;
      _lowestKneeAngle = 180.0;
      _capturedBottomThisRep = false;

      debugPrint('KeyFrameService: Started recording to ${_sessionDir!.path}');
      return true;
    } catch (e) {
      debugPrint('KeyFrameService: Error starting recording: $e');
      return false;
    }
  }

  /// Process a frame and capture key frame if at a significant phase
  /// Returns the captured KeyFrame if one was captured, null otherwise
  Future<KeyFrame?> processFrame({
    required CameraImage cameraImage,
    required List<PoseLandmark>? landmarks,
    required double kneeAngle,
    required double accuracy,
    required int repCount,
  }) async {
    if (!_isRecording || _sessionDir == null || landmarks == null) return null;

    // Detect current phase based on knee angle
    final newPhase = _detectPhase(kneeAngle);

    // Track lowest knee angle for this rep (best squat depth)
    if (kneeAngle < _lowestKneeAngle) {
      _lowestKneeAngle = kneeAngle;
    }

    // Check if rep count increased (rep completed)
    if (repCount > _currentRepNumber) {
      _currentRepNumber = repCount;
      _lowestKneeAngle = 180.0;
      _capturedBottomThisRep = false;
      _lastCapturedPhase = null; // Allow capturing phases again for new rep
    }

    // Determine if we should capture this frame
    bool shouldCapture = false;
    String phaseName = '';

    if (newPhase != _lastCapturedPhase) {
      switch (newPhase) {
        case SquatPhase.standing:
          if (_currentPhase != SquatPhase.standing) {
            shouldCapture = true;
            phaseName = 'Standing Position';
          }
          break;
        case SquatPhase.goingDown:
          // Capture once when starting to go down
          if (_currentPhase == SquatPhase.standing) {
            shouldCapture = true;
            phaseName = 'Going Down';
          }
          break;
        case SquatPhase.bottomPosition:
          // Capture the bottom position (most important frame)
          if (!_capturedBottomThisRep) {
            shouldCapture = true;
            phaseName = 'Bottom Position';
            _capturedBottomThisRep = true;
          }
          break;
        case SquatPhase.comingUp:
          // Capture once when coming up from bottom
          if (_currentPhase == SquatPhase.bottomPosition) {
            shouldCapture = true;
            phaseName = 'Coming Up';
          }
          break;
      }
    }

    _currentPhase = newPhase;

    if (!shouldCapture) return null;

    _lastCapturedPhase = newPhase;

    try {
      // Convert camera image to JPEG
      final frameIndex = _keyFrames.length;
      final imagePath = p.join(_sessionDir!.path, 'keyframe_$frameIndex.jpg');

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

      if (imageBytes == null) {
        debugPrint('KeyFrameService: Failed to convert image');
        return null;
      }

      await File(imagePath).writeAsBytes(imageBytes);

      final keyFrame = KeyFrame(
        phase: newPhase,
        phaseName: phaseName,
        imagePath: imagePath,
        userLandmarks: landmarks,
        kneeAngle: kneeAngle,
        accuracy: accuracy,
        timestamp: DateTime.now(),
        repNumber: _currentRepNumber,
      );

      _keyFrames.add(keyFrame);
      debugPrint(
          'KeyFrameService: Captured $phaseName (rep $_currentRepNumber, angle: ${kneeAngle.toStringAsFixed(1)}°)');

      return keyFrame;
    } catch (e) {
      debugPrint('KeyFrameService: Error capturing key frame: $e');
      return null;
    }
  }

  SquatPhase _detectPhase(double kneeAngle) {
    if (kneeAngle >= _standingAngle) {
      return SquatPhase.standing;
    } else if (kneeAngle <= _deepSquatAngle) {
      return SquatPhase.bottomPosition;
    } else if (kneeAngle < _squatAngle) {
      // Between deep squat and squat threshold
      if (_currentPhase == SquatPhase.standing ||
          _currentPhase == SquatPhase.goingDown) {
        return SquatPhase.goingDown;
      } else {
        return SquatPhase.comingUp;
      }
    } else {
      // Between squat and standing
      if (_currentPhase == SquatPhase.standing) {
        return SquatPhase.goingDown;
      } else if (_currentPhase == SquatPhase.bottomPosition ||
          _currentPhase == SquatPhase.comingUp) {
        return SquatPhase.comingUp;
      }
      return _currentPhase;
    }
  }

  /// Stop recording and return the session directory path
  Future<String?> stopRecording() async {
    if (!_isRecording || _sessionDir == null) return null;

    _isRecording = false;
    final endTime = DateTime.now();
    final duration = endTime.difference(_recordingStartTime!).inSeconds;

    debugPrint(
        'KeyFrameService: Stopped recording. ${_keyFrames.length} key frames captured');

    if (_keyFrames.isEmpty) {
      debugPrint('KeyFrameService: No key frames captured');
      return null;
    }

    return _sessionDir!.path;
  }

  /// Get key frame pack with metadata
  KeyFramePack? getKeyFramePack({
    required String exerciseType,
    required int totalReps,
    required double averageAccuracy,
  }) {
    if (_sessionDir == null || _keyFrames.isEmpty) return null;

    final duration = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!).inSeconds
        : 0;

    return KeyFramePack(
      outputDir: _sessionDir!.path,
      keyFrames: List.from(_keyFrames),
      exerciseType: exerciseType,
      totalReps: totalReps,
      averageAccuracy: averageAccuracy,
      recordedAt: _recordingStartTime ?? DateTime.now(),
      durationSeconds: duration,
    );
  }

  /// Clean up temporary recording files
  Future<void> cleanup() async {
    if (_sessionDir != null && await _sessionDir!.exists()) {
      try {
        await _sessionDir!.delete(recursive: true);
        debugPrint('KeyFrameService: Cleaned up recording directory');
      } catch (e) {
        debugPrint('KeyFrameService: Error cleaning up: $e');
      }
    }
    _keyFrames.clear();
    _sessionDir = null;
    _isRecording = false;
  }

  /// Reset state for new recording
  void reset() {
    _currentPhase = SquatPhase.standing;
    _lastCapturedPhase = null;
    _currentRepNumber = 0;
    _lowestKneeAngle = 180.0;
    _capturedBottomThisRep = false;
  }
}

/// Convert CameraImage (YUV420/NV21) to JPEG bytes
Uint8List? _convertCameraImageToJpeg(Map<String, dynamic> params) {
  try {
    final planes = params['planes'] as List<Uint8List>;
    final width = params['width'] as int;
    final height = params['height'] as int;
    final bytesPerRow = params['bytesPerRow'] as int;
    final sensorOrientation = params['sensorOrientation'] as int;
    final isFrontCamera = params['isFrontCamera'] as bool;

    if (planes.isEmpty) {
      return null;
    }

    final yPlane = planes[0];
    final image = img.Image(width: width, height: height);

    if (planes.length >= 2) {
      final uvPlane = planes[1];
      final hasThirdPlane = planes.length > 2;
      final vPlane = hasThirdPlane ? planes[2] : null;

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

          if (isInterleaved && uvPlane.isNotEmpty) {
            final uvIndex = uvRow * bytesPerRow + uvCol * 2;
            if (uvIndex + 1 < uvPlane.length) {
              vValue = uvPlane[uvIndex];
              uValue = uvPlane[uvIndex + 1];
            }
          } else if (vPlane != null) {
            final uvBytesPerRow = bytesPerRow ~/ 2;
            final uvIndex = uvRow * uvBytesPerRow + uvCol;
            if (uvIndex < uvPlane.length) {
              uValue = uvPlane[uvIndex];
            }
            if (uvIndex < vPlane.length) {
              vValue = vPlane[uvIndex];
            }
          }

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
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * bytesPerRow + x;
          if (yIndex >= yPlane.length) continue;
          int yValue = yPlane[yIndex].clamp(0, 255);
          image.setPixelRgba(x, y, yValue, yValue, yValue, 255);
        }
      }
    }

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

    if (isFrontCamera) {
      rotatedImage = img.flipHorizontal(rotatedImage);
    }

    return Uint8List.fromList(img.encodeJpg(rotatedImage, quality: 90));
  } catch (e) {
    debugPrint('Error converting camera image: $e');
    return null;
  }
}
