import 'dart:io';
import 'package:bema_application/features/pose_coach/models/pose_session.dart';
import 'package:bema_application/features/pose_coach/services/pose_local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'pose_session_player_screen.dart';

class PoseSessionGalleryScreen extends StatefulWidget {
  /// Optional exercise name to filter sessions (e.g., "Squats")
  final String? exerciseFilter;

  const PoseSessionGalleryScreen({super.key, this.exerciseFilter});

  @override
  State<PoseSessionGalleryScreen> createState() =>
      _PoseSessionGalleryScreenState();
}

class _PoseSessionGalleryScreenState extends State<PoseSessionGalleryScreen> {
  final _storage = PoseLocalStorageService();
  late Future<List<PoseSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = _storage.listSessions(exerciseFilter: widget.exerciseFilter);
  }

  Future<void> _refresh() async {
    final sessions =
        _storage.listSessions(exerciseFilter: widget.exerciseFilter);
    setState(() {
      _future = sessions;
    });
    await sessions;
  }

  Future<void> _delete(PoseSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete video?'),
        content:
            const Text('This will remove the recorded video and its metadata.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _storage.deleteSession(session);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted video')),
      );
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete video')),
      );
    }
  }

  void _play(PoseSession session) {
    if (session.videoPath == null || !File(session.videoPath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video file missing')),
      );
      return;
    }
    context.push(
      PoseSessionPlayerScreen.routePath,
      extra: session,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.exerciseFilter != null
        ? '${widget.exerciseFilter} History'
        : 'Exercise Videos';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PoseSession>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return const Center(
                child: Text('No recorded videos yet.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = sessions[index];
                final fileName = s.videoPath != null
                    ? p.basename(s.videoPath!)
                    : 'video.mp4';
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: const Icon(Icons.play_circle_fill, size: 36),
                    title: Text('${s.exercise} • ${s.reps} reps'),
                    subtitle: Text(
                      '${DateFormat('yMMMd – HH:mm').format(s.timestamp)}\n'
                      'Accuracy ${(s.accuracy * 100).toStringAsFixed(0)}% • ${s.duration}s • $fileName',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(s),
                    ),
                    onTap: () => _play(s),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
