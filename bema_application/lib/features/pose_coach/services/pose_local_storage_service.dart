import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/pose_session.dart';

/// Manages local storage for recorded pose sessions (video/frames + metadata).
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

  /// Find video file (.mp4) in folder
  File? _findVideoFile(Directory folder) {
    final mp4 = folder.listSync().whereType<File>().firstWhere(
          (f) => p.extension(f.path).toLowerCase() == '.mp4',
          orElse: () => File(''),
        );
    return mp4.path.isNotEmpty ? mp4 : null;
  }

  /// Find frames directory in folder (contains workout_metadata.json or .jpg files)
  Directory? _findFramesDir(Directory folder) {
    // Check if folder itself contains frames
    final workoutMeta = File(p.join(folder.path, 'workout_metadata.json'));
    if (workoutMeta.existsSync()) {
      return folder;
    }

    // Check subdirectories
    for (final sub in folder.listSync().whereType<Directory>()) {
      final subMeta = File(p.join(sub.path, 'workout_metadata.json'));
      if (subMeta.existsSync()) {
        return sub;
      }
      // Check for jpg files
      final hasFrames = sub.listSync().whereType<File>().any(
            (f) => p.extension(f.path).toLowerCase() == '.jpg',
          );
      if (hasFrames) {
        return sub;
      }
    }
    return null;
  }

  /// Save a new session with video file OR processed frames directory.
  /// Returns the saved session with updated videoPath, or null on failure.
  Future<PoseSession?> saveSession(
      PoseSession session, String sourcePath) async {
    try {
      final dir = await _rootDir();
      // Create unique folder for this session
      final folderName =
          '${session.exercise}_${session.timestamp.millisecondsSinceEpoch}';
      final sessionDir = Directory(p.join(dir.path, folderName));
      await sessionDir.create(recursive: true);

      String? savedPath;

      // Check if source is a directory (processed frames) or a file (video)
      final sourceDir = Directory(sourcePath);
      final sourceFile = File(sourcePath);

      if (await sourceDir.exists()) {
        // It's a directory with processed frames - copy entire directory
        final framesDir = Directory(p.join(sessionDir.path, 'frames'));
        await framesDir.create(recursive: true);

        // Copy all files from source to frames directory
        int copiedCount = 0;
        for (final entity in sourceDir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath = p.relative(entity.path, from: sourcePath);
            final destPath = p.join(framesDir.path, relativePath);
            final destDir = Directory(p.dirname(destPath));
            if (!await destDir.exists()) {
              await destDir.create(recursive: true);
            }
            await entity.copy(destPath);
            copiedCount++;
          }
        }
        debugPrint(
            'PoseLocalStorageService: Copied $copiedCount files to ${framesDir.path}');

        // Update workout_metadata.json with new paths
        final metaFile = File(p.join(framesDir.path, 'workout_metadata.json'));
        if (await metaFile.exists()) {
          final metaJson =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          // Update frame paths to new location
          if (metaJson['framePaths'] != null) {
            final oldPaths = (metaJson['framePaths'] as List).cast<String>();
            final newPaths = oldPaths.map((oldPath) {
              final fileName = p.basename(oldPath);
              return p.join(framesDir.path, fileName);
            }).toList();
            metaJson['framePaths'] = newPaths;
            metaJson['outputDir'] = framesDir.path;
            await metaFile.writeAsString(jsonEncode(metaJson));
          }
        }

        savedPath = framesDir.path;

        // Clean up source directory
        try {
          await sourceDir.delete(recursive: true);
        } catch (e) {
          debugPrint('Failed to delete source directory: $e');
        }
      } else if (await sourceFile.exists()) {
        // It's a video file - copy to session folder
        final newVideoPath = p.join(sessionDir.path, 'workout.mp4');
        await sourceFile.copy(newVideoPath);
        await sourceFile.delete();
        savedPath = newVideoPath;
      } else {
        debugPrint(
            'PoseLocalStorageService: Source path does not exist: $sourcePath');
        return null;
      }

      // Save session metadata
      final metaFile = File(p.join(sessionDir.path, _metaFileName));
      final updatedSession = session.copyWith(videoPath: savedPath);
      await metaFile.writeAsString(jsonEncode(updatedSession.toJson()));

      debugPrint(
          'PoseLocalStorageService: Session saved to ${sessionDir.path}');
      return updatedSession;
    } catch (e) {
      debugPrint('PoseLocalStorageService: Error saving session: $e');
      return null;
    }
  }

  /// Save a session with only report (no video/frames).
  /// Returns the saved session or null on failure.
  Future<PoseSession?> saveSessionWithReport(PoseSession session) async {
    try {
      final dir = await _rootDir();
      // Create unique folder for this session
      final folderName =
          '${session.exercise}_${session.timestamp.millisecondsSinceEpoch}';
      final sessionDir = Directory(p.join(dir.path, folderName));
      await sessionDir.create(recursive: true);

      // Save session metadata with report path
      final metaFile = File(p.join(sessionDir.path, _metaFileName));
      // Store the session folder path as videoPath for deletion purposes
      final updatedSession = session.copyWith(videoPath: sessionDir.path);
      await metaFile.writeAsString(jsonEncode(updatedSession.toJson()));

      debugPrint(
          'PoseLocalStorageService: Session with report saved to ${sessionDir.path}');
      return updatedSession;
    } catch (e) {
      debugPrint(
          'PoseLocalStorageService: Error saving session with report: $e');
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
      if (!metaFile.existsSync()) {
        continue; // skip folders without session metadata
      }

      try {
        final meta =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
        final session = PoseSession.fromJson(meta);

        // Find video file or frames directory
        final videoFile = _findVideoFile(folder);
        final framesDir = _findFramesDir(folder);

        // Use video path if available, otherwise use frames directory, or folder path for report-only sessions
        String? mediaPath = videoFile?.path ?? framesDir?.path;

        // For report-only sessions, use folder path for deletion purposes
        if (mediaPath == null && session.reportPath != null) {
          mediaPath = folder.path;
        }

        // Skip sessions that have no media and no report
        if (mediaPath == null && session.reportPath == null) {
          continue;
        }

        final updatedSession = session.copyWith(videoPath: mediaPath);

        // Filter by exercise if specified
        if (exerciseFilter != null &&
            updatedSession.exercise.toLowerCase() !=
                exerciseFilter.toLowerCase()) {
          continue;
        }

        sessions.add(updatedSession);
      } catch (e) {
        debugPrint(
            'PoseLocalStorageService: Error loading session from ${folder.path}: $e');
        continue;
      }
    }

    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    debugPrint('PoseLocalStorageService: Found ${sessions.length} sessions');
    return sessions;
  }

  /// Delete session folder (video/frames + metadata).
  Future<bool> deleteSession(PoseSession session) async {
    try {
      if (session.videoPath == null) return false;

      // videoPath could be a file or directory, get parent folder
      final path = session.videoPath!;
      Directory folderPath;

      if (await Directory(path).exists()) {
        // It's a directory (frames), get parent
        folderPath = Directory(p.dirname(path));
      } else {
        // It's a file (video), get parent
        folderPath = Directory(p.dirname(path));
      }

      if (await folderPath.exists()) {
        await folderPath.delete(recursive: true);
      }
      return true;
    } catch (e) {
      debugPrint('PoseLocalStorageService: Error deleting session: $e');
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
    String? reportPath,
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
      reportPath: reportPath ?? this.reportPath,
    );
  }
}
