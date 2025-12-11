import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/pose_session.dart';

/// Manages local storage for recorded pose sessions (video + metadata).
class PoseLocalStorageService {
  static const _sessionsDir = 'pose_sessions';
  static const _metaFileName = 'session.json';

  /// Root directory where pose session folders live.
  Future<Directory> _rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _sessionsDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File? _findVideoFile(Directory folder) {
    final mp4 = folder.listSync().whereType<File>().firstWhere(
          (f) => p.extension(f.path).toLowerCase() == '.mp4',
          orElse: () => File(''),
        );
    return mp4.path.isNotEmpty ? mp4 : null;
  }

  /// Save a new session with video file.
  /// Returns the saved session with updated videoPath, or null on failure.
  Future<PoseSession?> saveSession(
      PoseSession session, String tempVideoPath) async {
    try {
      final dir = await _rootDir();
      // Create unique folder for this session
      final folderName =
          '${session.exercise}_${session.timestamp.millisecondsSinceEpoch}';
      final sessionDir = Directory(p.join(dir.path, folderName));
      await sessionDir.create(recursive: true);

      // Move video file to session folder
      final videoFile = File(tempVideoPath);
      if (!await videoFile.exists()) {
        return null;
      }
      final newVideoPath = p.join(sessionDir.path, 'workout.mp4');
      await videoFile.copy(newVideoPath);
      await videoFile.delete(); // Clean up temp file

      // Save metadata
      final metaFile = File(p.join(sessionDir.path, _metaFileName));
      final updatedSession = session.copyWith(videoPath: newVideoPath);
      await metaFile.writeAsString(jsonEncode(updatedSession.toJson()));

      return updatedSession;
    } catch (e) {
      return null;
    }
  }

  /// Returns sessions filtered by exercise name (optional).
  Future<List<PoseSession>> listSessions({String? exerciseFilter}) async {
    final dir = await _rootDir();
    final entries = dir.listSync().whereType<Directory>().toList();
    final sessions = <PoseSession>[];

    for (final folder in entries) {
      final metaFile = File(p.join(folder.path, _metaFileName));
      final videoFile = _findVideoFile(folder);
      if (!metaFile.existsSync() || videoFile == null) {
        continue; // skip incomplete session
      }

      try {
        final meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        final session =
            PoseSession.fromJson(meta).copyWith(videoPath: videoFile.path);

        // Filter by exercise if specified
        if (exerciseFilter != null &&
            session.exercise.toLowerCase() != exerciseFilter.toLowerCase()) {
          continue;
        }

        sessions.add(session);
      } catch (_) {
        continue;
      }
    }

    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions;
  }

  /// Delete session folder (video + metadata).
  Future<bool> deleteSession(PoseSession session) async {
    try {
      if (session.videoPath == null) return false;
      final folderPath = Directory(p.dirname(session.videoPath!));
      if (await folderPath.exists()) {
        await folderPath.delete(recursive: true);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

extension on PoseSession {
  PoseSession copyWith({
    String? userId,
    String? exercise,
    int? reps,
    double? accuracy,
    DateTime? timestamp,
    int? duration,
    List<String>? feedbackPoints,
    String? videoPath,
  }) {
    return PoseSession(
      userId: userId ?? this.userId,
      exercise: exercise ?? this.exercise,
      reps: reps ?? this.reps,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      feedbackPoints: feedbackPoints ?? this.feedbackPoints,
      videoPath: videoPath ?? this.videoPath,
    );
  }
}
