import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For Size
import '../models/pose_session.dart'
    as models; // Prefix to avoid naming conflict

class PoseDetectionService {
  PoseDetector? _poseDetector;
  bool _isProcessing = false;

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
      final landmarks = <models.PoseLandmark>[];
      for (final landmark in pose.landmarks.values) {
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

      final imageRotation = InputImageRotation.rotation0deg;

      final inputImageFormat = InputImageFormat.nv21;

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

  void dispose() {
    _poseDetector?.close();
  }
}
