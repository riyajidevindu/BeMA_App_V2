import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'exercise_logic.dart';

/// Voice coaching service that manages all voice cues for exercise monitoring.
/// Ensures proper timing and prevents overlapping speech.
class VoiceCoachingService {
  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isEnabled = true;

  // Timing control
  DateTime? _lastCueTime;
  VoiceCueType? _lastCueType;
  ExercisePhase? _lastPhase;

  // Minimum intervals between different cue types (in milliseconds)
  static const int _minIntervalBetweenCues =
      1500; // 1.5 seconds minimum between any cues
  static const int _minIntervalSameCue =
      4000; // 4 seconds before repeating same cue
  static const int _repCompleteCooldown =
      2000; // 2 seconds after rep complete before next cue

  // Track rep-specific cues
  int _lastAnnouncedRep = 0;
  bool _hasGivenGoDownForCurrentStanding = false;
  bool _hasGivenComeUpForCurrentBottom = false;
  DateTime? _lastRepCompleteTime;

  // Voice cue messages - short and clear
  final Map<VoiceCueType, List<String>> _cueMessages = {
    VoiceCueType.goDown: ['Go down', 'Lower down', 'Start squatting'],
    VoiceCueType.keepGoing: ['Keep going', 'Lower', 'Go deeper'],
    VoiceCueType.holdIt: ['Hold', 'Hold it'],
    VoiceCueType.comeUp: ['Come up', 'Push up', 'Stand up'],
    VoiceCueType.goodRep: ['Good!', 'Nice!', 'Good rep!'],
    VoiceCueType.excellentRep: ['Excellent!', 'Perfect!', 'Great form!'],
    VoiceCueType.needsWork: ['Done', 'Okay'],
    VoiceCueType.getReady: ['Ready', 'Next rep', 'Go again'],
    VoiceCueType.encouragement: [
      'Push through!',
      'You got it!',
      'Keep pushing!'
    ],
    VoiceCueType.repCount: [], // Dynamic based on rep number
  };

  // Form correction messages
  final Map<String, String> _formCorrections = {
    'shallow_depth': 'Go lower!',
    'too_deep': 'Not so deep!',
    'back_lean': 'Back straight!',
    'severe_back_lean': 'Straighten back!',
    'hips_not_back': 'Hips back!',
    'excessive_lean': 'Stay upright!',
    'knee_asymmetry': 'Knees even!',
    'heels_lifting': 'Heels down!',
  };

  /// Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage("en-US");
      await _flutterTts!.setSpeechRate(0.5); // Slightly faster for short cues
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.1); // Slightly higher pitch for clarity

      // Set up completion handler
      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('VoiceCoachingService: Initialized');
    } catch (e) {
      debugPrint('VoiceCoachingService: Error initializing TTS: $e');
    }
  }

  /// Reset state for new workout
  void reset() {
    _lastCueTime = null;
    _lastCueType = null;
    _lastPhase = null;
    _lastAnnouncedRep = 0;
    _hasGivenGoDownForCurrentStanding = false;
    _hasGivenComeUpForCurrentBottom = false;
    _lastRepCompleteTime = null;
    _isSpeaking = false;
    _flutterTts?.stop();
  }

  /// Enable or disable voice coaching
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _flutterTts?.stop();
      _isSpeaking = false;
    }
  }

  /// Process analysis result and determine if voice cue is needed
  Future<void> processAnalysisResult(
      ExerciseAnalysisResult result, int currentRepCount) async {
    if (!_isInitialized || !_isEnabled || _flutterTts == null) return;

    final now = DateTime.now();
    final phase = result.currentPhase;
    final suggestedCue = result.suggestedVoiceCue;

    // Don't speak if already speaking
    if (_isSpeaking) return;

    // Check cooldown after rep complete
    if (_lastRepCompleteTime != null) {
      final timeSinceRepComplete =
          now.difference(_lastRepCompleteTime!).inMilliseconds;
      if (timeSinceRepComplete < _repCompleteCooldown) {
        return; // Still in cooldown after rep announcement
      }
    }

    // Check minimum interval between cues
    if (_lastCueTime != null) {
      final timeSinceLastCue = now.difference(_lastCueTime!).inMilliseconds;
      if (timeSinceLastCue < _minIntervalBetweenCues) {
        return; // Too soon since last cue
      }

      // Longer interval for same cue type
      if (suggestedCue == _lastCueType &&
          timeSinceLastCue < _minIntervalSameCue) {
        return;
      }
    }

    // Handle phase transitions for voice cues
    String? messageToSpeak;

    // === REP COMPLETED - Highest priority ===
    if (result.isRepCompleted && currentRepCount > _lastAnnouncedRep) {
      _lastAnnouncedRep = currentRepCount;
      _lastRepCompleteTime = now;

      // Announce rep with quality feedback
      if (result.accuracy >= 85) {
        messageToSpeak =
            'Rep $currentRepCount. ${_getRandomMessage(VoiceCueType.excellentRep)}';
      } else if (result.accuracy >= 70) {
        messageToSpeak =
            'Rep $currentRepCount. ${_getRandomMessage(VoiceCueType.goodRep)}';
      } else {
        messageToSpeak = 'Rep $currentRepCount.';
      }

      // Reset flags for next rep
      _hasGivenGoDownForCurrentStanding = false;
      _hasGivenComeUpForCurrentBottom = false;

      await _speak(messageToSpeak, VoiceCueType.repCount);
      return;
    }

    // === STANDING - Ready for "go down" ===
    if (phase == ExercisePhase.standing && !_hasGivenGoDownForCurrentStanding) {
      // Only give "go down" after a brief pause in standing
      if (_lastPhase == ExercisePhase.standing) {
        // Check if we've been standing for a moment (let them rest)
        if (_lastCueTime == null ||
            now.difference(_lastCueTime!).inMilliseconds > 2500) {
          if (currentRepCount == 0) {
            messageToSpeak = _getRandomMessage(VoiceCueType.goDown);
          } else {
            messageToSpeak = _getRandomMessage(VoiceCueType.getReady);
          }
          _hasGivenGoDownForCurrentStanding = true;
          await _speak(messageToSpeak, VoiceCueType.goDown);
          return;
        }
      }
    }

    // Reset standing flag when leaving standing phase
    if (phase != ExercisePhase.standing &&
        _lastPhase == ExercisePhase.standing) {
      _hasGivenGoDownForCurrentStanding = false;
    }

    // === GOING DOWN - Encourage descent ===
    if (phase == ExercisePhase.goingDown &&
        suggestedCue == VoiceCueType.keepGoing) {
      // Only if transitioning into this phase
      if (_lastPhase != ExercisePhase.goingDown) {
        messageToSpeak = _getRandomMessage(VoiceCueType.keepGoing);
        await _speak(messageToSpeak, VoiceCueType.keepGoing);
        return;
      }
    }

    // === AT BOTTOM - "Come up" cue ===
    if (phase == ExercisePhase.atBottom && !_hasGivenComeUpForCurrentBottom) {
      // Give "come up" cue after brief hold at bottom
      if (_lastPhase == ExercisePhase.atBottom) {
        // Already at bottom for a moment
        messageToSpeak = _getRandomMessage(VoiceCueType.comeUp);
        _hasGivenComeUpForCurrentBottom = true;
        await _speak(messageToSpeak, VoiceCueType.comeUp);
        return;
      } else if (_lastPhase == ExercisePhase.goingDown) {
        // Just arrived at bottom - give immediate cue
        messageToSpeak = _getRandomMessage(VoiceCueType.comeUp);
        _hasGivenComeUpForCurrentBottom = true;
        await _speak(messageToSpeak, VoiceCueType.comeUp);
        return;
      }
    }

    // Reset bottom flag when leaving bottom phase
    if (phase != ExercisePhase.atBottom &&
        _lastPhase == ExercisePhase.atBottom) {
      _hasGivenComeUpForCurrentBottom = false;
    }

    // === COMING UP - Encouragement ===
    if (phase == ExercisePhase.comingUp &&
        suggestedCue == VoiceCueType.encouragement) {
      if (_lastPhase != ExercisePhase.comingUp) {
        messageToSpeak = _getRandomMessage(VoiceCueType.encouragement);
        await _speak(messageToSpeak, VoiceCueType.encouragement);
        return;
      }
    }

    // === FORM CORRECTIONS - Only for significant issues ===
    if (suggestedCue == VoiceCueType.formCorrection &&
        phase == ExercisePhase.atBottom) {
      final issues =
          result.additionalData?['currentRepIssues'] as List<String>?;
      if (issues != null && issues.isNotEmpty) {
        // Only correct one issue at a time - prioritize safety
        for (final issue in [
          'severe_back_lean',
          'back_lean',
          'heels_lifting'
        ]) {
          if (issues.contains(issue) && _formCorrections.containsKey(issue)) {
            messageToSpeak = _formCorrections[issue];
            await _speak(messageToSpeak!, VoiceCueType.formCorrection);
            return;
          }
        }
      }
    }

    // Update last phase
    _lastPhase = phase;
  }

  /// Get a random message for variety
  String _getRandomMessage(VoiceCueType cueType) {
    final messages = _cueMessages[cueType];
    if (messages == null || messages.isEmpty) return '';

    // Simple rotation instead of random for consistency
    final index = DateTime.now().millisecond % messages.length;
    return messages[index];
  }

  /// Speak a message with proper state management
  Future<void> _speak(String message, VoiceCueType cueType) async {
    if (message.isEmpty || !_isEnabled) return;

    _isSpeaking = true;
    _lastCueTime = DateTime.now();
    _lastCueType = cueType;

    try {
      debugPrint('VoiceCoaching: Speaking "$message" (${cueType.name})');
      await _flutterTts?.speak(message);

      // Estimate speech duration and wait
      final wordCount = message.split(' ').length;
      final duration = (wordCount * 350)
          .clamp(400, 2000); // 350ms per word, min 400ms, max 2s
      await Future.delayed(Duration(milliseconds: duration));
    } catch (e) {
      debugPrint('VoiceCoaching: Error speaking: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  /// Speak a custom message immediately (for workout start/end)
  Future<void> speakImmediate(String message) async {
    if (!_isInitialized || !_isEnabled || message.isEmpty) return;

    // Stop any current speech
    await _flutterTts?.stop();
    _isSpeaking = false;

    await _speak(message, VoiceCueType.encouragement);
  }

  /// Stop all speech
  Future<void> stop() async {
    await _flutterTts?.stop();
    _isSpeaking = false;
  }

  /// Dispose resources
  void dispose() {
    _flutterTts?.stop();
    _flutterTts = null;
    _isInitialized = false;
  }
}
