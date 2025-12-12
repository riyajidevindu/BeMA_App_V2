import 'dart:io' show Platform;
import 'dart:math' show sqrt, acos, pi;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/common/config/colors.dart';
import '../providers/pose_coach_provider.dart';
import '../services/pose_detection_service.dart';
import '../services/pose_firebase_service.dart';
import '../services/pose_local_storage_service.dart';
import '../services/workout_report_service.dart';
import '../services/exercise_logic.dart';
import '../services/exercise_logic_factory.dart';
import '../models/pose_session.dart';
import '../models/workout_report.dart';
import 'package:go_router/go_router.dart';
import 'package:bema_application/routes/route_names.dart';
import '../models/exercise.dart';
import 'package:bema_application/services/api_service.dart';

class PoseCoachScreen extends StatefulWidget {
  final Exercise? exercise;

  const PoseCoachScreen({super.key, this.exercise});

  @override
  State<PoseCoachScreen> createState() => _PoseCoachScreenState();
}

class _PoseCoachScreenState extends State<PoseCoachScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  PoseDetectionService? _poseDetectionService;
  FlutterTts? _flutterTts;
  stt.SpeechToText? _speechToText;
  ExerciseLogic? _exerciseLogic;
  Exercise? _currentExercise;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _error;
  bool _isCheckingPermissions = true;
  final ApiService _apiService = ApiService();
  final PoseFirebaseService _firebaseService = PoseFirebaseService();

  // Voice queue management to prevent overlapping speech
  bool _isSpeaking = false;
  List<String> _speechQueue = [];
  DateTime? _lastSpeechTime;

  // Camera switching
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex =
      -1; // -1 means not initialized, will select front camera first
  bool _isSwitchingCamera = false;

  // Positioning and voice control
  bool _isPositioningMode = true;
  bool _isListening = false;
  String _positioningStatus = 'Getting ready...';
  DateTime? _lastPositionCheck;
  bool _hasSpokenPositionInstructions = false;

  // Track when user was last seen (to avoid annoying "cannot see you" messages)
  DateTime? _lastSeenInFrame;
  DateTime? _lastOutOfFrameWarning;

  // Track positioning states to avoid repeating "I can see you"
  bool _wasFullyVisible = false; // Was user fully visible in previous frame?
  bool _hasConfirmedVisibility = false; // Have we already said "I can see you"?

  // Pose overlay state
  List<PoseLandmark>? _lastLandmarks;
  Size? _lastImageSize;
  Size? _previewSize;
  DateTime? _lastOverlayUpdate;

  // Track orientation feedback to avoid repetition
  String _lastOrientation = '';
  DateTime? _lastOrientationWarning;
  String _lastFormFeedback = '';
  DateTime? _lastFormFeedbackTime;
  // ignore: unused_field - kept for backward compatibility with feedback debouncing
  String _lastSpokenFeedback = '';
  // ignore: unused_field - kept for backward compatibility with feedback debouncing
  DateTime? _lastFeedbackTime;

  // Workout saving state
  bool _isRecordingVideo = false;
  final PoseLocalStorageService _localStorageService =
      PoseLocalStorageService();

  // Workout report service for detailed feedback
  final WorkoutReportService _workoutReportService = WorkoutReportService();

  bool _isGeneratingVideo = false;
  String _videoGenerationStatus = '';
  double _videoGenerationProgress = 0.0;

  // Countdown timer state
  bool _isCountingDown = false;
  int _countdownSeconds = 5;

  @override
  void initState() {
    super.initState();
    // Initialize exercise logic based on passed exercise or default to squats
    _currentExercise = widget.exercise ?? Exercise.squats;
    _exerciseLogic = ExerciseLogicFactory.createLogic(_currentExercise!.type);
    _exerciseLogic?.initialize();

    WidgetsBinding.instance.addObserver(this);
    _checkAndRequestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _poseDetectionService?.dispose();
    _flutterTts?.stop();
    _speechToText?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Re-check permissions when app resumes
      _checkAndRequestPermissions();
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
      _error = null;
    });

    try {
      // Check camera permission
      var cameraStatus = await Permission.camera.status;

      // Check microphone permission for voice commands
      var micStatus = await Permission.microphone.status;

      // Request permissions if not granted
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
      }

      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
      }

      final hasRequiredPermissions = cameraStatus.isGranted;
      final hasMicPermission = micStatus.isGranted;

      setState(() {
        _isCheckingPermissions = false;
      });

      if (hasRequiredPermissions) {
        // Initialize camera and services
        await _initializeCamera();
        await _initializeTts();

        if (hasMicPermission) {
          await _initializeSpeechRecognition();
        } else {
          debugPrint('Microphone permission denied - voice commands disabled');
        }
      } else {
        setState(() {
          _error = 'Camera permission is required to use AI Coach';
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingPermissions = false;
        _error = 'Error checking permissions: $e';
      });
      debugPrint('Permission check error: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera available on this device';
          _isInitialized = false;
        });
        return;
      }

      // Store available cameras
      _availableCameras = cameras;

      // If first initialization (-1) or invalid index, find and use front camera
      // Otherwise use the current index (e.g., after camera switch)
      if (_currentCameraIndex < 0 ||
          _currentCameraIndex >= _availableCameras.length) {
        // Find front camera index
        _currentCameraIndex = _availableCameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
        // Fallback to first camera if no front camera found
        if (_currentCameraIndex < 0) {
          _currentCameraIndex = 0;
        }
      }

      _cameraController = CameraController(
        _availableCameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      _previewSize = _cameraController!.value.previewSize;

      // Initialize pose detection service
      _poseDetectionService = PoseDetectionService();
      await _poseDetectionService!.initialize();

      // Pass camera info for proper rotation calculation
      final camera = _availableCameras[_currentCameraIndex];
      _poseDetectionService!.setCameraInfo(
        camera.sensorOrientation,
        camera.lensDirection,
      );

      // Start image stream for pose detection
      _cameraController!.startImageStream(_processCameraImage);

      setState(() {
        _isInitialized = true;
        _isSwitchingCamera = false;
        _error = null; // Clear any previous errors
      });
    } on CameraException catch (e) {
      setState(() {
        _error = 'Camera error: ${e.description ?? e.code}';
        _isSwitchingCamera = false;
        _isInitialized = false;
      });
      debugPrint('Camera exception: ${e.code} - ${e.description}');
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera. Please check permissions.';
        _isSwitchingCamera = false;
        _isInitialized = false;
      });
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _initializeTts() async {
    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage("en-US");
      await _flutterTts!
          .setSpeechRate(0.35); // Slower for better user comprehension
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
      debugPrint('Text-to-Speech initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Text-to-Speech: $e');
      // Don't show error to user - TTS is optional
    }
  }

  Future<void> _initializeSpeechRecognition() async {
    try {
      _speechToText = stt.SpeechToText();
      bool available = await _speechToText!.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );

      if (available) {
        debugPrint('Speech recognition initialized successfully');
        // Start listening for voice commands
        _startVoiceCommands();
      } else {
        debugPrint('Speech recognition not available on this device');
      }
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      // Don't show error to user - voice commands are optional
    }
  }

  void _startVoiceCommands() {
    if (_speechToText == null || _isListening) return;

    setState(() {
      _isListening = true;
    });

    _speechToText!.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleVoiceCommand(result.recognizedWords.toLowerCase());
        }
      },
      listenMode: stt.ListenMode.confirmation,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
    );
  }

  void _handleVoiceCommand(String command) {
    debugPrint('Voice command: $command');

    final poseProvider = Provider.of<PoseCoachProvider>(context, listen: false);

    if (command.contains('start') || command.contains('begin')) {
      if (!poseProvider.isWorkoutActive) {
        // Start workout (this handles both positioning mode and not-started state)
        _startWorkout();
      }
    } else if (command.contains('stop') ||
        command.contains('end') ||
        command.contains('finish')) {
      if (poseProvider.isWorkoutActive) {
        _endWorkout();
      }
    } else if (command.contains('pause')) {
      // Future: Implement pause functionality
      _speak('Pause feature coming soon');
    }

    // Restart listening
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isListening) {
        _startVoiceCommands();
      }
    });
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || _availableCameras.length < 2) return;

    setState(() {
      _isSwitchingCamera = true;
      _isInitialized = false;
    });

    try {
      // Stop current camera
      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();

      // Switch to next camera
      _currentCameraIndex =
          (_currentCameraIndex + 1) % _availableCameras.length;

      // Reinitialize with new camera
      await _initializeCamera();
    } catch (e) {
      debugPrint('Error switching camera: $e');
      setState(() {
        _isSwitchingCamera = false;
        _isInitialized = true;
      });
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || _exerciseLogic == null) return;

    final poseProvider = Provider.of<PoseCoachProvider>(context, listen: false);

    _isProcessing = true;

    try {
      // Detect pose landmarks
      final rawLandmarks = await _poseDetectionService!.detectPose(image);

      // Persist landmarks for overlay - update skeleton position in real-time
      if (rawLandmarks != null && rawLandmarks.isNotEmpty) {
        _lastLandmarks = rawLandmarks.cast<PoseLandmark>();
        _lastImageSize = Size(image.width.toDouble(), image.height.toDouble());
        final now = DateTime.now();
        // Update UI at ~20 FPS (50ms) for smooth skeleton movement
        if (_lastOverlayUpdate == null ||
            now.difference(_lastOverlayUpdate!).inMilliseconds >= 50) {
          _lastOverlayUpdate = now;
          if (mounted) setState(() {});
        }
      }

      // POSITIONING MODE - Check if user is in frame
      if (_isPositioningMode) {
        final now = DateTime.now();

        if (rawLandmarks == null || rawLandmarks.isEmpty) {
          // No body detected
          // Reset visibility flags when user is not visible
          if (_wasFullyVisible) {
            _wasFullyVisible = false;
            _hasConfirmedVisibility = false;
          }

          if (_lastPositionCheck == null ||
              now.difference(_lastPositionCheck!).inSeconds >= 3) {
            setState(() {
              _positioningStatus = 'Step back so I can see your full body';
            });
            if (!_hasSpokenPositionInstructions) {
              _speak(
                  'Please step back so I can see your full body. Make sure your head, arms, hips, and legs are visible in the camera.');
              _hasSpokenPositionInstructions = true;
            }
            _lastPositionCheck = now;
          }
        } else {
          final landmarks = rawLandmarks.cast<PoseLandmark>();

          // Check if full body is visible (key points)
          final hasHead = landmarks.length > 0;
          final hasShoulders = landmarks.length > 12;
          final hasHips = landmarks.length > 24;
          final hasKnees = landmarks.length > 26;
          final hasAnkles = landmarks.length > 28;

          if (hasHead && hasShoulders && hasHips && hasKnees && hasAnkles) {
            // Full body detected!
            // Only speak if:
            // 1. This is the first time we see them fully (transition from not visible to visible) OR
            // 2. They left and came back (wasFullyVisible was false, now true again)
            final shouldConfirmVisibility = !_hasConfirmedVisibility ||
                (!_wasFullyVisible && !_hasConfirmedVisibility);

            if (shouldConfirmVisibility) {
              setState(() {
                _positioningStatus =
                    'Perfect! I can see you clearly. Press start when ready!';
                _wasFullyVisible = true;
                _hasConfirmedVisibility = true;
              });
              _speak(
                  'Perfect! I can see you clearly. Press the start button when you are ready.');
              _lastPositionCheck = now;
              _hasSpokenPositionInstructions = true;
            } else {
              // User is still visible, just update status text silently
              setState(() {
                _positioningStatus =
                    'Perfect! I can see you clearly. Press start when ready!';
                _wasFullyVisible = true;
              });
            }
          } else {
            // Partial body detected
            // Reset visibility flag when user is only partially visible
            if (_wasFullyVisible) {
              _wasFullyVisible = false;
              _hasConfirmedVisibility = false;
            }

            String missingParts = '';
            if (!hasHead) missingParts += 'head, ';
            if (!hasShoulders) missingParts += 'shoulders, ';
            if (!hasHips) missingParts += 'hips, ';
            if (!hasKnees) missingParts += 'knees, ';
            if (!hasAnkles) missingParts += 'feet, ';

            if (missingParts.isNotEmpty) {
              missingParts = missingParts.substring(0, missingParts.length - 2);
            }

            if (_lastPositionCheck == null ||
                now.difference(_lastPositionCheck!).inSeconds >= 3) {
              setState(() {
                _positioningStatus =
                    'Step back a bit more. I need to see your $missingParts';
              });
              _speak(
                  'Step back a bit more. I need to see your $missingParts clearly.');
              _lastPositionCheck = now;
            }
          }
        }
      }
      // WORKOUT MODE - Normal exercise tracking
      else if (poseProvider.isWorkoutActive) {
        if (rawLandmarks == null || rawLandmarks.isEmpty) {
          // Lost tracking during workout - user not in frame
          final now = DateTime.now();

          // Only warn if:
          // 1. User was previously seen in frame AND
          // 2. Has been out of frame for at least 6 seconds AND
          // 3. Haven't warned in the last 10 seconds
          if (_lastSeenInFrame != null) {
            final timeSinceLastSeen =
                now.difference(_lastSeenInFrame!).inSeconds;
            final timeSinceLastWarning = _lastOutOfFrameWarning != null
                ? now.difference(_lastOutOfFrameWarning!).inSeconds
                : 999;

            if (timeSinceLastSeen >= 6 && timeSinceLastWarning >= 10) {
              _speak('I cannot see you. Please step back into the frame.');
              _lastOutOfFrameWarning = now;
            }
          }
        } else {
          // User is in frame - update last seen time
          _lastSeenInFrame = DateTime.now();

          // Use exercise-specific logic to analyze pose
          final landmarks = rawLandmarks.cast<PoseLandmark>();
          final result = _exerciseLogic!.analyzePose(landmarks);

          // Track analysis for workout report
          if (poseProvider.isWorkoutActive) {
            _workoutReportService.processAnalysisResult(result);
          }

          final now = DateTime.now();

          // Get orientation data (non-blocking)
          final isIdealOrientation =
              result.additionalData?['isIdealOrientation'] ?? true;
          final orientationHint =
              result.additionalData?['orientationHint'] ?? '';
          final currentOrientation =
              result.additionalData?['orientation'] ?? 'sideways';

          // Update provider with exercise-specific feedback
          poseProvider.updateExerciseFeedback(
            result.feedback,
            result.accuracy,
            result.feedbackLevel == FeedbackLevel.excellent ||
                result.feedbackLevel == FeedbackLevel.good,
          );

          // Count rep if completed
          if (result.isRepCompleted) {
            poseProvider.incrementRep();
          }

          // Voice feedback for form corrections
          final currentFeedback = poseProvider.currentFeedback;

          // Get improved voice feedback from report service for real-time coaching
          final improvedFeedback = poseProvider.isWorkoutActive
              ? _workoutReportService.getVoiceFeedback(result)
              : currentFeedback;

          // Speak if:
          // 1. Feedback text changed OR
          // 2. Same form issue for 5+ seconds and haven't warned in last 8 seconds
          //    (for form corrections like "Keep your back straight")
          final feedbackChanged = improvedFeedback != _lastFormFeedback;
          final timeSinceLastFormWarning = _lastFormFeedbackTime != null
              ? now.difference(_lastFormFeedbackTime!).inSeconds
              : 999;

          final isFormIssue =
              result.feedbackLevel == FeedbackLevel.needsImprovement;

          final shouldSpeak = poseProvider.showVisualFeedback &&
              (feedbackChanged ||
                  (isFormIssue && timeSinceLastFormWarning >= 8));

          if (shouldSpeak) {
            _speak(improvedFeedback);
            _lastFormFeedback = improvedFeedback;
            _lastFormFeedbackTime = now;
          }

          // Also update lastSpokenFeedback for backward compatibility
          if (feedbackChanged) {
            _lastSpokenFeedback = currentFeedback;
            _lastFeedbackTime = now;
          }

          // Optional: Provide orientation hint as a gentle reminder (not blocking)
          // Only speak orientation hint if not ideal and hasn't been warned recently
          if (!isIdealOrientation && orientationHint.isNotEmpty) {
            final orientationChanged = currentOrientation != _lastOrientation;
            final timeSinceLastWarning = _lastOrientationWarning != null
                ? now.difference(_lastOrientationWarning!).inSeconds
                : 999;

            if (orientationChanged || timeSinceLastWarning >= 12) {
              _speak(orientationHint);
              _lastOrientation = currentOrientation;
              _lastOrientationWarning = now;
            }
          } else {
            _lastOrientation = 'sideways'; // Reset when orientation is good
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing pose: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Calculate knee angle from hip, knee, and ankle landmarks
  double _calculateKneeAngle(
      PoseLandmark hip, PoseLandmark knee, PoseLandmark ankle) {
    // Create vectors from knee (vertex) to hip and ankle
    final vector1X = hip.x - knee.x;
    final vector1Y = hip.y - knee.y;
    final vector2X = ankle.x - knee.x;
    final vector2Y = ankle.y - knee.y;

    // Calculate dot product
    final dotProduct = vector1X * vector2X + vector1Y * vector2Y;

    // Calculate magnitudes
    final magnitude1 = (vector1X * vector1X + vector1Y * vector1Y);
    final magnitude2 = (vector2X * vector2X + vector2Y * vector2Y);

    if (magnitude1 == 0 || magnitude2 == 0) return 180.0;

    // Calculate cosine of angle
    final cosAngle = dotProduct / sqrt(magnitude1 * magnitude2);
    final clampedCos = cosAngle.clamp(-1.0, 1.0);

    // Calculate angle in degrees
    final angleDeg = acos(clampedCos) * 180.0 / pi;
    return angleDeg;
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty || _flutterTts == null) return;

    // Don't allow the same text to be spoken multiple times in rapid succession
    final now = DateTime.now();
    if (_lastSpeechTime != null &&
        now.difference(_lastSpeechTime!).inMilliseconds < 1000 &&
        _speechQueue.isNotEmpty &&
        _speechQueue.last == text) {
      debugPrint('TTS: Skipping duplicate message within 1000ms: $text');
      return;
    }

    // Stop any current speech to prevent overlap
    if (_isSpeaking) {
      await _flutterTts?.stop();
      _speechQueue.clear(); // Clear queue to prevent old messages
      debugPrint('TTS: Stopped current speech for new message: $text');
    }

    // Speak immediately
    _isSpeaking = true;
    _lastSpeechTime = now;

    try {
      debugPrint('TTS: Speaking now: $text');
      await _flutterTts?.speak(text);

      // Wait for speech to complete (estimate based on text length)
      // Average speaking rate: ~150 words per minute = 2.5 words per second
      final wordCount = text.split(' ').length;
      final estimatedDuration =
          ((wordCount / 2.5) * 1000).toInt(); // milliseconds
      await Future.delayed(
          Duration(milliseconds: estimatedDuration + 300)); // Add buffer
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  /// Video recording - currently disabled during workout because the camera
  /// package on Android cannot run image stream and video recording simultaneously.
  /// The image stream is required for real-time pose detection and skeleton overlay.
  /// This method is kept for potential future use with a different recording approach.
  // ignore: unused_element
  Future<void> _startVideoRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecordingVideo) {
      return;
    }

    try {
      // Stop image stream before recording video
      await _cameraController!.stopImageStream();

      // Start video recording
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecordingVideo = true;
      });
      debugPrint('Video recording started');
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  void _startWorkout() async {
    // Start countdown first
    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 5;
    });

    _speak('Get ready! Starting in 5 seconds.');

    // Countdown from 5 to 1
    for (int i = 5; i >= 1; i--) {
      if (!mounted || !_isCountingDown)
        return; // Exit if cancelled or unmounted

      setState(() {
        _countdownSeconds = i;
      });

      if (i <= 3) {
        _speak('$i');
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted || !_isCountingDown) return;

    setState(() {
      _isCountingDown = false;
    });

    // Now actually start the workout
    _actuallyStartWorkout();
  }

  void _actuallyStartWorkout() async {
    final poseProvider = Provider.of<PoseCoachProvider>(context, listen: false);

    // Clear any pending speech from positioning mode
    _speechQueue.clear();
    _isSpeaking = false;
    await _flutterTts?.stop();

    setState(() {
      _isRecordingVideo = true;
    });

    // Exit positioning mode
    setState(() {
      _isPositioningMode = false;
      // Initialize tracking timestamps
      _lastSeenInFrame = DateTime.now();
      _lastOutOfFrameWarning = null;
      // Reset positioning mode state (no longer needed in workout)
      _wasFullyVisible = false;
      _hasConfirmedVisibility = false;
      _hasSpokenPositionInstructions = false;
      _lastPositionCheck = null;
      // Reset workout feedback state for fresh start
      _lastFormFeedback = '';
      _lastFormFeedbackTime = null;
      _lastOrientation = '';
      _lastOrientationWarning = null;
      _lastSpokenFeedback = '';
      _lastFeedbackTime = null;
    });

    _exerciseLogic?.reset();
    poseProvider.startWorkout(_currentExercise?.id ?? 'squats');

    // Start workout report tracking
    _workoutReportService.startWorkout(_currentExercise?.name ?? 'Squats');

    _speak('Go! Start your exercise.');
  }

  void _endWorkout() {
    _stopWorkout();
  }

  Future<void> _stopWorkout() async {
    final poseProvider = Provider.of<PoseCoachProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    setState(() {
      _isRecordingVideo = false;
    });

    // Generate workout report
    final workoutReport = _workoutReportService.generateReport();
    debugPrint(
        'WorkoutReport: Generated report with ${workoutReport.totalReps} reps, ${workoutReport.averageAccuracy.toStringAsFixed(1)}% accuracy');

    // Get Firebase user ID (consistent with the rest of your app)
    final userId = authProvider.firebaseUser?.uid ?? '';

    if (userId.isEmpty) {
      debugPrint('Error: No user ID found');
      _speak('Error: Please log in to save workout');
      _workoutReportService.reset();
      return;
    }

    final session = poseProvider.stopWorkout(userId);

    // Save workout report and get path
    final reportPath = await _workoutReportService.saveReport(workoutReport);
    debugPrint('WorkoutReport: Saved to $reportPath');

    // Create session with report path
    final sessionWithReport = PoseSession(
      userId: session.userId,
      exercise: session.exercise,
      reps: session.reps,
      accuracy: session.accuracy,
      timestamp: session.timestamp,
      duration: session.duration,
      feedbackPoints: session.feedbackPoints,
      videoPath: session.videoPath,
      reportPath: reportPath,
    );

    _speak('Exercise completed. Great job!');

    // Show report processing dialog
    if (mounted) {
      _showReportProcessingDialog(sessionWithReport, workoutReport, userId);
    }
  }

  /// Show dialog while generating workout report
  void _showReportProcessingDialog(
    PoseSession session,
    WorkoutReport report,
    String userId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Start report saving process
          if (!_isGeneratingVideo) {
            _isGeneratingVideo = true;
            _saveWorkoutWithReport(
              session: session,
              report: report,
              userId: userId,
              onProgress: (progress, status) {
                if (mounted) {
                  setDialogState(() {
                    _videoGenerationProgress = progress;
                    _videoGenerationStatus = status;
                  });
                }
              },
              onComplete: (savedSession) {
                Navigator.pop(dialogContext);
                _isGeneratingVideo = false;
                if (mounted) {
                  _showWorkoutReportSummary(savedSession ?? session, report);
                }
              },
            );
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Saving Workout',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _videoGenerationStatus.isEmpty
                      ? 'Analyzing your workout...'
                      : _videoGenerationStatus,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _videoGenerationProgress,
                  backgroundColor: primaryColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_videoGenerationProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Your report will include:\n• Rep-by-rep analysis\n• Form feedback & corrections\n• Personalized coaching tips',
                    style: TextStyle(fontSize: 12, color: primaryColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Save workout with report
  Future<void> _saveWorkoutWithReport({
    required PoseSession session,
    required WorkoutReport report,
    required String userId,
    required Function(double progress, String status) onProgress,
    required Function(PoseSession? savedSession) onComplete,
  }) async {
    try {
      onProgress(0.2, 'Saving workout report...');

      // Save session with report (no video/frames, just metadata)
      final savedSession =
          await _localStorageService.saveSessionWithReport(session);

      onProgress(0.5, 'Uploading to cloud...');

      // Save to Firebase
      final firebaseSessionId = await _firebaseService.saveWorkoutSession(
        userId: userId,
        session: savedSession ?? session,
      );
      debugPrint('Workout session saved to Firebase: $firebaseSessionId');

      onProgress(0.7, 'Sending for analysis...');

      // Send to backend for AI analysis
      await _apiService.sendWorkoutSummary((savedSession ?? session).toJson());

      onProgress(0.9, 'Finalizing...');

      // Reset report service
      _workoutReportService.reset();

      onProgress(1.0, 'Complete!');
      onComplete(savedSession ?? session);
    } catch (e) {
      debugPrint('Error saving workout with report: $e');
      _workoutReportService.reset();
      onComplete(null);
    }
  }

  /// Show workout report summary dialog
  void _showWorkoutReportSummary(PoseSession session, WorkoutReport report) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getGradeColor(report.overallGrade).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getGradeColor(report.overallGrade).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Text(
                report.overallGrade,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _getGradeColor(report.overallGrade),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Complete! 🎉',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.performanceLevel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getGradeColor(report.overallGrade),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildReportStatRow(
                  'Total Reps', '${report.totalReps}', Icons.repeat),
              _buildReportStatRow(
                'Accuracy',
                '${report.averageAccuracy.toStringAsFixed(0)}%',
                Icons.speed,
              ),
              _buildReportStatRow(
                'Perfect Reps',
                '${report.perfectReps}',
                Icons.star,
              ),
              _buildReportStatRow(
                'Duration',
                '${report.durationSeconds}s',
                Icons.timer,
              ),
              const Divider(height: 24),
              if (report.areasToImprove.isNotEmpty) ...[
                const Text(
                  '🎯 Key Focus Area:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    report.areasToImprove.first,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(
                '/workoutReport',
                extra: report,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
            ),
            child: const Text(
              'View Full Report',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .pushReplacement('/${RouteNames.poseSessionGalleryScreen}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'View History',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final poseProvider = Provider.of<PoseCoachProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCheckingPermissions
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'Checking permissions...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _error!.contains('permission')
                              ? Icons.lock_outline
                              : Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!.contains('permission')
                              ? 'Please grant camera permission in your device settings to use AI Coach.'
                              : 'Please try again or restart the app.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_error!.contains('permission')) {
                              // Open app settings
                              await openAppSettings();
                            } else {
                              // Retry initialization
                              await _checkAndRequestPermissions();
                            }
                          },
                          icon: Icon(_error!.contains('permission')
                              ? Icons.settings
                              : Icons.refresh),
                          label: Text(_error!.contains('permission')
                              ? 'Open Settings'
                              : 'Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Go Back',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : !_isInitialized
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            'Initializing camera...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        // Camera preview with properly aligned skeleton overlay
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (_cameraController == null ||
                                  !_cameraController!.value.isInitialized) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              // Get camera preview aspect ratio
                              // On Android, previewSize is in landscape (e.g., 1920x1080)
                              // We need to swap for portrait display
                              final previewSize =
                                  _cameraController!.value.previewSize!;
                              final double cameraAspectRatio =
                                  Platform.isAndroid
                                      ? previewSize.height / previewSize.width
                                      : previewSize.width / previewSize.height;

                              // Calculate how the camera preview fits within constraints
                              final double containerWidth =
                                  constraints.maxWidth;
                              final double containerHeight =
                                  constraints.maxHeight;
                              final double containerAspectRatio =
                                  containerWidth / containerHeight;

                              double previewWidth;
                              double previewHeight;
                              double offsetX = 0;
                              double offsetY = 0;

                              if (cameraAspectRatio > containerAspectRatio) {
                                // Camera is wider - fit by width, letterbox top/bottom
                                previewWidth = containerWidth;
                                previewHeight =
                                    containerWidth / cameraAspectRatio;
                                offsetY = (containerHeight - previewHeight) / 2;
                              } else {
                                // Camera is taller - fit by height, pillarbox left/right
                                previewHeight = containerHeight;
                                previewWidth =
                                    containerHeight * cameraAspectRatio;
                                offsetX = (containerWidth - previewWidth) / 2;
                              }

                              return Stack(
                                children: [
                                  // Camera preview centered and maintaining aspect ratio
                                  Center(
                                    child: SizedBox(
                                      width: previewWidth,
                                      height: previewHeight,
                                      child: CameraPreview(_cameraController!),
                                    ),
                                  ),
                                  // Skeleton overlay positioned to match actual preview area
                                  if (_lastLandmarks != null &&
                                      _lastImageSize != null)
                                    Positioned(
                                      left: offsetX,
                                      top: offsetY,
                                      width: previewWidth,
                                      height: previewHeight,
                                      child: CustomPaint(
                                        painter: PoseSkeletonPainter(
                                          landmarks: _lastLandmarks!,
                                          imageSize: _lastImageSize!,
                                          previewSize: _previewSize,
                                          isFrontCamera: _cameraController
                                                  ?.description.lensDirection ==
                                              CameraLensDirection.front,
                                          showGoodForm:
                                              poseProvider.showVisualFeedback,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Stats overlay
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 60,
                          left: 20,
                          right: 20,
                          child: _buildStatsOverlay(poseProvider),
                        ),

                        // Camera flip button - top right
                        if (_availableCameras.length > 1)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 60,
                            right: 20,
                            child: Material(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(30),
                              child: InkWell(
                                onTap:
                                    _isSwitchingCamera ? null : _switchCamera,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: _isSwitchingCamera
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.flip_camera_ios,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                          ),

                        // Positioning Mode Overlay
                        if (_isPositioningMode)
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.35,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.8),
                                    Colors.purple.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.person_pin,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _positioningStatus,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          offset: Offset(1, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  if (_isListening)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.mic,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Listening for "Start"...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),

                        // Countdown Overlay
                        if (_isCountingDown)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'GET READY!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade400,
                                            Colors.purple.shade400,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.5),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$_countdownSeconds',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 80,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    const Text(
                                      'Get into position',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Feedback overlay - responsive positioning
                        Positioned(
                          bottom: screenHeight * 0.2 + bottomPadding,
                          left: 20,
                          right: 20,
                          child: _buildFeedbackOverlay(poseProvider),
                        ),

                        // Control buttons - lower, closer to navbar
                        Positioned(
                          bottom: bottomPadding + 20,
                          left: 0,
                          right: 0,
                          child: _buildControls(poseProvider),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildStatsOverlay(PoseCoachProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Reps', provider.repCount.toString(), Icons.fitness_center),
          _buildStatItem(
            'Accuracy',
            '${(provider.accuracy * 100).toStringAsFixed(0)}%',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackOverlay(PoseCoachProvider provider) {
    return AnimatedOpacity(
      opacity: provider.isWorkoutActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: provider.showVisualFeedback
              ? Colors.green.withOpacity(0.8)
              : Colors.orange.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              provider.showVisualFeedback ? Icons.thumb_up : Icons.info,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.currentFeedback,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(PoseCoachProvider provider) {
    // In positioning mode, show "I'm Ready" button
    if (_isPositioningMode) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _isCountingDown ? null : _startWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCountingDown ? Colors.grey : Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isCountingDown ? Icons.hourglass_top : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isCountingDown ? 'Starting...' : 'I\'m Ready - Start!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // In workout mode, show Start/Stop button
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed:
                  provider.isWorkoutActive ? _stopWorkout : _startWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    provider.isWorkoutActive ? Colors.red : Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                provider.isWorkoutActive ? 'Stop Workout' : 'Start Workout',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHistory() {
    if (!mounted) return;
    context.push('/${RouteNames.poseSessionGalleryScreen}');
  }
}

/// Dialog widget for recording a video after workout
class _RecordingDialog extends StatefulWidget {
  final CameraController cameraController;
  final Function(String path) onVideoSaved;
  final VoidCallback onCancel;

  const _RecordingDialog({
    required this.cameraController,
    required this.onVideoSaved,
    required this.onCancel,
  });

  @override
  State<_RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<_RecordingDialog> {
  bool _isRecording = false;
  int _recordingSeconds = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      // Stop image stream if running
      if (widget.cameraController.value.isStreamingImages) {
        await widget.cameraController.stopImageStream();
      }

      // Start recording
      await widget.cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });

      // Start timer
      _startTimer();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        widget.onCancel();
      }
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return false;
      setState(() {
        _recordingSeconds++;
      });
      return true;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
      _isSaving = true;
    });

    try {
      final videoFile = await widget.cameraController.stopVideoRecording();
      debugPrint('Video recorded: ${videoFile.path}');
      widget.onVideoSaved(videoFile.path);
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      widget.onCancel();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎬 Recording Your Victory!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isRecording ? Colors.red : Colors.grey,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: CameraPreview(widget.cameraController),
              ),
            ),
            const SizedBox(height: 16),
            if (_isRecording) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'REC ${_formatDuration(_recordingSeconds)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Show off your moves!',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
            if (_isSaving) ...[
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'Saving to gallery...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : widget.onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving || !_isRecording ? null : _stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.stop, color: Colors.white),
                  label: const Text(
                    'Stop & Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for pose skeleton overlay
class PoseSkeletonPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Size imageSize;
  final Size? previewSize;
  final bool isFrontCamera;
  final bool showGoodForm;

  PoseSkeletonPainter({
    required this.landmarks,
    required this.imageSize,
    required this.previewSize,
    required this.isFrontCamera,
    required this.showGoodForm,
  });

  // MLKit pose landmark indices for body connections
  // Head
  static const int nose = 0;
  static const int leftEyeInner = 1;
  static const int leftEye = 2;
  static const int leftEyeOuter = 3;
  static const int rightEyeInner = 4;
  static const int rightEye = 5;
  static const int rightEyeOuter = 6;
  static const int leftEar = 7;
  static const int rightEar = 8;
  static const int mouthLeft = 9;
  static const int mouthRight = 10;
  // Body
  static const int leftShoulder = 11;
  static const int rightShoulder = 12;
  static const int leftElbow = 13;
  static const int rightElbow = 14;
  static const int leftWrist = 15;
  static const int rightWrist = 16;
  static const int leftPinky = 17;
  static const int rightPinky = 18;
  static const int leftIndex = 19;
  static const int rightIndex = 20;
  static const int leftThumb = 21;
  static const int rightThumb = 22;
  static const int leftHip = 23;
  static const int rightHip = 24;
  static const int leftKnee = 25;
  static const int rightKnee = 26;
  static const int leftAnkle = 27;
  static const int rightAnkle = 28;
  static const int leftHeel = 29;
  static const int rightHeel = 30;
  static const int leftFootIndex = 31;
  static const int rightFootIndex = 32;

  // Body skeleton connections (pairs of landmark indices)
  static const List<List<int>> _bodyConnections = [
    // Torso
    [leftShoulder, rightShoulder],
    [leftShoulder, leftHip],
    [rightShoulder, rightHip],
    [leftHip, rightHip],
    // Left arm
    [leftShoulder, leftElbow],
    [leftElbow, leftWrist],
    // Right arm
    [rightShoulder, rightElbow],
    [rightElbow, rightWrist],
    // Left leg
    [leftHip, leftKnee],
    [leftKnee, leftAnkle],
    [leftAnkle, leftHeel],
    [leftAnkle, leftFootIndex],
    // Right leg
    [rightHip, rightKnee],
    [rightKnee, rightAnkle],
    [rightAnkle, rightHeel],
    [rightAnkle, rightFootIndex],
  ];

  Offset _transform(PoseLandmark lm, Size canvasSize) {
    // MLKit returns landmarks in the coordinate space of the processed image
    // The coordinate system depends on the rotation applied during image processing

    double x = lm.x;
    double y = lm.y;

    double sourceWidth;
    double sourceHeight;

    if (Platform.isAndroid) {
      // On Android, camera gives landscape image (e.g. 1280x720)
      // MLKit rotates it based on sensor orientation for processing
      // After rotation, the image becomes portrait, so dimensions are swapped
      sourceWidth = imageSize.height;
      sourceHeight = imageSize.width;
    } else {
      // iOS handles this differently
      sourceWidth = imageSize.width;
      sourceHeight = imageSize.height;
    }

    // Scale to canvas size
    final double scaleX = canvasSize.width / sourceWidth;
    final double scaleY = canvasSize.height / sourceHeight;

    x = x * scaleX;
    y = y * scaleY;

    // For front camera: The camera preview widget displays a mirrored (selfie) view
    // But MLKit processes the raw un-mirrored image from the camera sensor
    // We need to mirror the skeleton X-coordinates to match the mirrored preview
    if (isFrontCamera) {
      x = canvasSize.width - x;
    }

    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty || landmarks.length < 33) return;

    // Filter landmarks by visibility threshold
    const double visibilityThreshold = 0.5;

    final jointPaint = Paint()
      ..color = showGoodForm
          ? const Color(0xFF00E676).withOpacity(0.95) // Bright green
          : const Color(0xFFFF9100).withOpacity(0.95) // Bright orange
      ..style = PaintingStyle.fill;

    final bonePaint = Paint()
      ..color = showGoodForm
          ? const Color(0xFF00E676).withOpacity(0.85)
          : const Color(0xFFFF9100).withOpacity(0.85)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw skeleton bones
    for (final connection in _bodyConnections) {
      final idx1 = connection[0];
      final idx2 = connection[1];

      if (idx1 >= landmarks.length || idx2 >= landmarks.length) continue;

      final lm1 = landmarks[idx1];
      final lm2 = landmarks[idx2];

      // Only draw if both landmarks are visible enough
      if (lm1.visibility < visibilityThreshold ||
          lm2.visibility < visibilityThreshold) continue;

      final p1 = _transform(lm1, size);
      final p2 = _transform(lm2, size);

      canvas.drawLine(p1, p2, bonePaint);
    }

    // Draw joints (only visible ones)
    for (int i = 0; i < landmarks.length && i < 33; i++) {
      final lm = landmarks[i];
      if (lm.visibility < visibilityThreshold) continue;

      final point = _transform(lm, size);

      // Draw larger circles for key joints
      final bool isKeyJoint = i == leftShoulder ||
          i == rightShoulder ||
          i == leftElbow ||
          i == rightElbow ||
          i == leftWrist ||
          i == rightWrist ||
          i == leftHip ||
          i == rightHip ||
          i == leftKnee ||
          i == rightKnee ||
          i == leftAnkle ||
          i == rightAnkle;

      canvas.drawCircle(point, isKeyJoint ? 8 : 5, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.isFrontCamera != isFrontCamera ||
        oldDelegate.showGoodForm != showGoodForm;
  }
}
