import 'package:animated_background/animated_background.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/pose_coach/models/workout_report.dart';
import 'package:bema_application/features/pose_coach/services/workout_report_service.dart';
import 'package:flutter/material.dart';

class WorkoutReportScreen extends StatefulWidget {
  static const routePath = '/workoutReport';

  final String? reportPath;
  final WorkoutReport? report;

  const WorkoutReportScreen({
    super.key,
    this.reportPath,
    this.report,
  });

  @override
  State<WorkoutReportScreen> createState() => _WorkoutReportScreenState();
}

class _WorkoutReportScreenState extends State<WorkoutReportScreen>
    with TickerProviderStateMixin {
  WorkoutReport? _report;
  bool _isLoading = true;
  String? _error;
  int _selectedRepIndex = -1; // -1 means overview

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (widget.report != null) {
      setState(() {
        _report = widget.report;
        _isLoading = false;
      });
      return;
    }

    if (widget.reportPath != null) {
      final report = await WorkoutReportService.loadReport(widget.reportPath!);
      if (report != null) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load report';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = 'No report data provided';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade100,
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            baseColor: Colors.white,
            spawnOpacity: 0.0,
            opacityChangeRate: 0.25,
            minOpacity: 0.1,
            maxOpacity: 0.4,
            spawnMinSpeed: 30.0,
            spawnMaxSpeed: 70.0,
            spawnMinRadius: 7.0,
            spawnMaxRadius: 15.0,
            particleCount: 50,
          ),
        ),
        vsync: this,
        child: SafeArea(
          child: Column(
            children: [
              const CustomAppBar(showBackButton: true),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _report == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error ?? 'Report not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildOverallScore(),
          const SizedBox(height: 16),
          _buildQuickStats(),
          const SizedBox(height: 16),
          _buildStrengths(),
          const SizedBox(height: 16),
          _buildAreasToImprove(),
          const SizedBox(height: 16),
          _buildRepBreakdown(),
          const SizedBox(height: 16),
          _buildCoachingTips(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final report = _report!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.exerciseType} Workout Report',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatDate(report.startTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScore() {
    final report = _report!;
    final gradeColor = _getGradeColor(report.overallGrade);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: gradeColor, width: 4),
            ),
            child: Center(
              child: Text(
                report.overallGrade,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.performanceLevel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.averageAccuracy.toStringAsFixed(1)}% Overall Accuracy',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: report.averageAccuracy / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final report = _report!;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.repeat,
            label: 'Total Reps',
            value: '${report.totalReps}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            label: 'Perfect Reps',
            value: '${report.perfectReps}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer,
            label: 'Duration',
            value: _formatDuration(report.durationSeconds),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengths() {
    final report = _report!;
    if (report.strengths.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: '💪 Strengths',
      color: Colors.green,
      child: Column(
        children: report.strengths
            .map((s) => _buildListItem(s, Icons.check_circle, Colors.green))
            .toList(),
      ),
    );
  }

  Widget _buildAreasToImprove() {
    final report = _report!;
    if (report.areasToImprove.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: '🎯 Areas to Improve',
      color: Colors.orange,
      child: Column(
        children: report.areasToImprove
            .map((s) => _buildListItem(s, Icons.arrow_forward, Colors.orange))
            .toList(),
      ),
    );
  }

  Widget _buildListItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepBreakdown() {
    final report = _report!;
    if (report.repAnalyses.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: '📊 Rep-by-Rep Analysis',
      color: Colors.blue,
      child: Column(
        children: [
          // Rep selector chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Overview'),
                selected: _selectedRepIndex == -1,
                onSelected: (_) => setState(() => _selectedRepIndex = -1),
                selectedColor: Colors.blue.shade200,
              ),
              ...report.repAnalyses.asMap().entries.map((entry) {
                final rep = entry.value;
                final isSelected = _selectedRepIndex == entry.key;
                return ChoiceChip(
                  label: Text('Rep ${rep.repNumber}'),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedRepIndex = entry.key),
                  selectedColor:
                      _getAccuracyColor(rep.accuracy).withOpacity(0.3),
                  avatar: CircleAvatar(
                    backgroundColor: _getAccuracyColor(rep.accuracy),
                    radius: 8,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          // Show selected rep details or overview
          if (_selectedRepIndex == -1)
            _buildRepOverview()
          else
            _buildRepDetails(report.repAnalyses[_selectedRepIndex]),
        ],
      ),
    );
  }

  Widget _buildRepOverview() {
    final report = _report!;
    return Column(
      children: report.repAnalyses.map((rep) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getAccuracyColor(rep.accuracy).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getAccuracyColor(rep.accuracy).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getAccuracyColor(rep.accuracy),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${rep.repNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rep.grade,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getAccuracyColor(rep.accuracy),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${rep.accuracy.toStringAsFixed(0)}%',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    if (rep.hasIssues)
                      Text(
                        '${rep.issues.length} issue${rep.issues.length > 1 ? 's' : ''} detected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                rep.hasIssues ? Icons.warning_amber : Icons.check_circle,
                color: rep.hasIssues ? Colors.orange : Colors.green,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRepDetails(RepAnalysis rep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getAccuracyColor(rep.accuracy),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rep ${rep.repNumber} - ${rep.grade}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${rep.accuracy.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getAccuracyColor(rep.accuracy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Knee Angle',
                  '${rep.kneeAngle.toStringAsFixed(0)}°',
                  _getKneeAngleStatus(rep.kneeAngle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Back Align',
                  '${(rep.backAlignment * 100).toStringAsFixed(0)}%',
                  rep.backAlignment >= 0.7 ? 'Good' : 'Needs Work',
                ),
              ),
            ],
          ),

          // Issues
          if (rep.issues.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Issues Detected:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...rep.issues.map((issue) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            issue.description,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '✓ Fix: ${issue.correction}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Feedback
          if (rep.overallFeedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Feedback: ${rep.overallFeedback}',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(status,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildCoachingTips() {
    final report = _report!;
    if (report.coachingTips.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: '🏋️ Coaching Tips',
      color: Colors.purple,
      child: Text(
        report.coachingTips,
        style: const TextStyle(fontSize: 14, height: 1.6),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          child,
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

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return Colors.green;
    if (accuracy >= 80) return Colors.lightGreen;
    if (accuracy >= 70) return Colors.orange;
    if (accuracy >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  String _getKneeAngleStatus(double angle) {
    if (angle >= 70 && angle <= 105) return 'Perfect';
    if (angle < 70) return 'Too Deep';
    if (angle > 105 && angle < 130) return 'Partial';
    return 'Standing';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }
}
