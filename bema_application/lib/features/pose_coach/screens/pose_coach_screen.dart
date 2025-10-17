import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import '../providers/pose_coach_provider.dart';
import '../services/pose_detection_service.dart';
import '../services/pose_firebase_service.dart';
import '../services/exercise_logic.dart';
import '../services/exercise_logic_factory.dart';
import '../models/pose_session.dart';
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
  bool _hasPermissions = false;
  bool _isCheckingPermissions = true;
  String _lastSpokenFeedback = '';
  DateTime? _lastFeedbackTime;
  final ApiService _apiService = ApiService();
  final PoseFirebaseService _firebaseService = PoseFirebaseService();

  // Camera switching
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;
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

  // Track ready state to tell user when to start
  bool _isUserReady =
      false; // Is user in frame, full body visible, and good orientation?
  bool _hasAnnouncedReady = false; // Have we told user they're ready to start?

  // Track orientation feedback to avoid repetition
  String _lastOrientation = '';
  DateTime? _lastOrientationWarning;
  String _lastFormFeedback = '';
  DateTime? _lastFormFeedbackTime;

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
        _hasPermissions = hasRequiredPermissions;
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

      // If first initialization, use front camera (index 0)
      // Otherwise use the current index
      if (_currentCameraIndex >= _availableCameras.length) {
        _currentCameraIndex = 0;
      }

      _cameraController = CameraController(
        _availableCameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Initialize pose detection service
      _poseDetectionService = PoseDetectionService();
      await _poseDetectionService!.initialize();

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
      await _flutterTts!.setSpeechRate(0.5);
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
      if (_isPositioningMode) {
        // Skip positioning mode if user is ready
        setState(() {
          _isPositioningMode = false;
        });
        _speak('Starting workout now!');
      } else if (!poseProvider.isWorkoutActive) {
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
                    'Perfect! I can see you clearly. Say "Start" to begin!';
                _wasFullyVisible = true;
                _hasConfirmedVisibility = true;
              });
              _speak(
                  'Perfect! I can see you clearly. Say Start when you are ready, or tap the start button.');
              _lastPositionCheck = now;
              _hasSpokenPositionInstructions = true;
            } else {
              // User is still visible, just update status text silently
              setState(() {
                _positioningStatus =
                    'Perfect! I can see you clearly. Say "Start" to begin!';
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

          final now = DateTime.now();

          // Get orientation data (non-blocking)
          final isIdealOrientation =
              result.additionalData?['isIdealOrientation'] ?? true;
          final orientationHint =
              result.additionalData?['orientationHint'] ?? '';
          final currentOrientation =
              result.additionalData?['orientation'] ?? 'sideways';

          // Check if user is in standing position and ready to start
          final avgKneeAngle = result.additionalData?['avgKneeAngle'] ?? 0.0;
          final isStanding = avgKneeAngle > 160;
          final isInGoodPosition = isIdealOrientation && isStanding;

          // Announce when user is ready to start (once per session or when they return)
          if (isInGoodPosition && !_isUserReady) {
            _isUserReady = true;
            if (!_hasAnnouncedReady) {
              _speak(
                  'Perfect! You are in position and ready. You can start your ${_currentExercise?.name ?? 'exercise'} now!');
              _hasAnnouncedReady = true;
            }
          } else if (!isInGoodPosition && _isUserReady) {
            // Reset ready state if user moves out of position
            _isUserReady = false;
          }

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

          // Speak if:
          // 1. Feedback text changed OR
          // 2. Same form issue for 5+ seconds and haven't warned in last 8 seconds
          //    (for form corrections like "Keep your back straight")
          final feedbackChanged = currentFeedback != _lastFormFeedback;
          final timeSinceLastFormWarning = _lastFormFeedbackTime != null
              ? now.difference(_lastFormFeedbackTime!).inSeconds
              : 999;

          final isFormIssue =
              result.feedbackLevel == FeedbackLevel.needsImprovement;

          final shouldSpeak = poseProvider.showVisualFeedback &&
              (feedbackChanged ||
                  (isFormIssue && timeSinceLastFormWarning >= 8));

          if (shouldSpeak) {
            _speak(currentFeedback);
            _lastFormFeedback = currentFeedback;
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

  Future<void> _speak(String text) async {
    try {
      await _flutterTts?.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  void _startWorkout() {
    final poseProvider = Provider.of<PoseCoachProvider>(context, listen: false);

    // Exit positioning mode
    setState(() {
      _isPositioningMode = false;
      // Initialize tracking timestamps
      _lastSeenInFrame = DateTime.now();
      _lastOutOfFrameWarning = null;
      // Reset ready state for new workout session
      _isUserReady = false;
      _hasAnnouncedReady = false;
    });

    _exerciseLogic?.reset();
    poseProvider.startWorkout(_currentExercise?.id ?? 'squats');
    _speak('Starting ${_currentExercise?.name ?? "squat"} workout. Get ready!');
  }

  void _endWorkout() {
    _stopWorkout();
  }

  Future<void> _stopWorkout() async {
    final poseProvider = Provider.of<PoseCoachProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    // Get Firebase user ID (consistent with the rest of your app)
    final userId = authProvider.firebaseUser?.uid ?? '';

    if (userId.isEmpty) {
      debugPrint('Error: No user ID found');
      _speak('Error: Please log in to save workout');
      return;
    }

    final session = poseProvider.stopWorkout(userId);

    _speak('Workout completed. Great job!');

    // Save to both Firebase and backend
    try {
      // 1. Save to Firebase Firestore first (primary storage)
      final firebaseSessionId = await _firebaseService.saveWorkoutSession(
        userId: userId,
        session: session,
      );

      if (firebaseSessionId != null) {
        debugPrint('Workout session saved to Firebase: $firebaseSessionId');
      } else {
        debugPrint('Failed to save to Firebase');
      }

      // 2. Send session data to backend (for AI analysis and additional features)
      final response = await _apiService.sendWorkoutSummary(session.toJson());

      if (response != null && mounted) {
        // Show motivational feedback from AI
        _showWorkoutSummary(session, response['motivation'] ?? 'Great work!');
      } else if (mounted) {
        _showWorkoutSummary(session, 'Excellent workout!');
      }
    } catch (e) {
      debugPrint('Error saving workout: $e');
      if (mounted) {
        _showWorkoutSummary(session, 'Excellent workout!');
      }
    }
  }

  void _showWorkoutSummary(PoseSession session, String motivation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reps: ${session.reps}'),
            Text('Accuracy: ${(session.accuracy * 100).toStringAsFixed(1)}%'),
            Text('Duration: ${session.duration}s'),
            const SizedBox(height: 16),
            Text(
              motivation,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
                        // Camera preview
                        Positioned.fill(
                          child: _cameraController != null &&
                                  _cameraController!.value.isInitialized
                              ? CameraPreview(_cameraController!)
                              : const Center(
                                  child: CircularProgressIndicator()),
                        ),

                        // Pose detection overlay
                        if (poseProvider.isWorkoutActive)
                          CustomPaint(
                            painter: PoseOverlayPainter(
                              showGoodForm: poseProvider.showVisualFeedback,
                            ),
                            child: Container(),
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
          _buildStatItem('Streak', provider.consecutiveGoodReps.toString(),
              Icons.local_fire_department),
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
          child: ElevatedButton(
            onPressed: _startWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_arrow, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'I\'m Ready - Start!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // In workout mode, show Start/Stop button
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          onPressed: provider.isWorkoutActive ? _stopWorkout : _startWorkout,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                provider.isWorkoutActive ? Colors.red : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
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
      ),
    );
  }
}

// Custom painter for pose overlay
class PoseOverlayPainter extends CustomPainter {
  final bool showGoodForm;

  PoseOverlayPainter({required this.showGoodForm});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGoodForm) return;

    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // Draw a checkmark overlay when form is good
    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.65);
    path.lineTo(size.width * 0.7, size.height * 0.35);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return oldDelegate.showGoodForm != showGoodForm;
  }
}
