import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For Size
import '../models/pose_session.dart'
    as models; // Prefix to avoid naming conflict

class PoseDetectionService {
  PoseDetector? _poseDetector;
  bool _isProcessing = false;
  int _sensorOrientation = 0;
  CameraLensDirection _lensDirection = CameraLensDirection.front;

  Future<void> initialize() async {
    try {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      );
      _poseDetector = PoseDetector(options: options);
    } catch (e) {
      debugPrint('Error initializing pose detector: $e');
      rethrow;
    }
  }

  /// Set camera info for proper rotation calculation
  void setCameraInfo(int sensorOrientation, CameraLensDirection lensDirection) {
    _sensorOrientation = sensorOrientation;
    _lensDirection = lensDirection;
    debugPrint(
        'PoseDetectionService: sensor=$_sensorOrientation, lens=$_lensDirection');
  }

  Future<List<models.PoseLandmark>?> detectPose(CameraImage image) async {
    if (_isProcessing || _poseDetector == null) {
      return null;
    }

    _isProcessing = true;

    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        return null;
      }

      // Process image
      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isEmpty) {
        return null;
      }

      // Get first detected pose
      final pose = poses.first;

      // Convert MLKit landmarks to our custom model
      // Sort by landmark type index to ensure consistent ordering
      final sortedEntries = pose.landmarks.entries.toList()
        ..sort((a, b) => a.key.index.compareTo(b.key.index));

      final landmarks = <models.PoseLandmark>[];
      for (final entry in sortedEntries) {
        final landmark = entry.value;
        landmarks.add(models.PoseLandmark(
          x: landmark.x,
          y: landmark.y,
          z: landmark.z,
          visibility: landmark.likelihood,
        ));
      }

      return landmarks;
    } catch (e) {
      debugPrint('Error detecting pose: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      // Calculate proper rotation based on platform and camera
      final imageRotation = _getImageRotation();

      // Use appropriate format based on platform
      final inputImageFormat = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Get the proper image rotation for MLKit based on device and camera
  InputImageRotation _getImageRotation() {
    if (Platform.isIOS) {
      // iOS handles rotation differently
      return InputImageRotation.rotation0deg;
    }

    // Android: Calculate rotation based on sensor orientation
    // Front camera needs to handle mirroring
    int rotationCompensation = _sensorOrientation;

    // For front camera on Android, we need to adjust the rotation
    if (_lensDirection == CameraLensDirection.front) {
      rotationCompensation = (360 - _sensorOrientation) % 360;
    }

    switch (rotationCompensation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void dispose() {
    _poseDetector?.close();
  }
}
