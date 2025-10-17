import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  ExerciseLogic? _exerciseLogic;
  Exercise? _currentExercise;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _error;
  String _lastSpokenFeedback = '';
  final ApiService _apiService = ApiService();
  final PoseFirebaseService _firebaseService = PoseFirebaseService();

  @override
  void initState() {
    super.initState();
    // Initialize exercise logic based on passed exercise or default to squats
    _currentExercise = widget.exercise ?? Exercise.squats;
    _exerciseLogic = ExerciseLogicFactory.createLogic(_currentExercise!.type);
    _exerciseLogic?.initialize();

    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeTts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _poseDetectionService?.dispose();
    _flutterTts?.stop();
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
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera available';
        });
        return;
      }

      // Use front camera for self-view
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
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
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts!.setLanguage("en-US");
    await _flutterTts!.setSpeechRate(0.5);
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || _exerciseLogic == null) return;

    final poseProvider = Provider.of<PoseCoachProvider>(context, listen: false);
    if (!poseProvider.isWorkoutActive) return;

    _isProcessing = true;

    try {
      // Detect pose landmarks
      final rawLandmarks = await _poseDetectionService!.detectPose(image);

      if (rawLandmarks != null && rawLandmarks.isNotEmpty) {
        // Use exercise-specific logic to analyze pose
        final landmarks = rawLandmarks.cast<PoseLandmark>();
        final result = _exerciseLogic!.analyzePose(landmarks);

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

        // Provide voice feedback
        final currentFeedback = poseProvider.currentFeedback;
        if (currentFeedback != _lastSpokenFeedback &&
            poseProvider.showVisualFeedback) {
          _speak(currentFeedback);
          _lastSpokenFeedback = currentFeedback;
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
    _exerciseLogic?.reset();
    poseProvider.startWorkout(_currentExercise?.id ?? 'squats');
    _speak('Starting ${_currentExercise?.name ?? "squat"} workout. Get ready!');
    _speak('Starting squat workout. Get ready!');
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
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    // Camera preview
                    Positioned.fill(
                      child: _cameraController != null &&
                              _cameraController!.value.isInitialized
                          ? CameraPreview(_cameraController!)
                          : const Center(child: CircularProgressIndicator()),
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
