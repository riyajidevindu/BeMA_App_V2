import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';
import 'package:bema_application/features/marks/data/services/marks_service.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final MarkService markService = MarkService();
  bool isLoading = true;
  double dailyPoints = 0;
  double weeklyPoints = 0;
  double monthlyPoints = 0;
  double totalDailyMarks = 100; // Total marks for the day
  List<TaskModel> dailyTasks = [];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// Fetch daily, weekly, and monthly points and daily tasks
  Future<void> loadUserData() async {
    setState(() => isLoading = true);
    try {
      final taskSummary = await markService.fetchTaskSummary();

      setState(() {
        dailyTasks = taskSummary['dailyTasks'];
        dailyPoints = taskSummary['dailyPoints'];
        weeklyPoints = taskSummary['weeklyPoints'];
        monthlyPoints = taskSummary['monthlyPoints'];
      });
    } catch (error) {
      debugPrint("Error fetching task summary: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator()) // Loading indicator
            : Column(
                children: [
                  SizedBox(
                    height: 70,
                    child: PageView(
                      controller: _pageController,
                      scrollDirection: Axis.horizontal,
                      onPageChanged: (index) {
                        // Enables circular scrolling by jumping to the first page if end is reached
                        if (index == 3) _pageController.jumpToPage(0);
                        if (index == -1) _pageController.jumpToPage(2);
                      },
                      children: [
                        buildPointsBox("Daily Points", "$dailyPoints / $totalDailyMarks"),
                        buildPointsBox("Weekly Points", "$weeklyPoints"),
                        buildPointsBox("Monthly Points", "$monthlyPoints"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: dailyTasks.length,
                      itemBuilder: (context, index) {
                        TaskModel task = dailyTasks[index];
                        // Set progress to 100% if task is completed
                        double progress = task.completed
                            ? 1.0
                            : (task.total != null && task.total! > 0)
                                ? (task.progress / task.total!).clamp(0, 1)
                                : 0;

                        // Calculate marks for the task
                        double taskMarks = totalDailyMarks / dailyTasks.length;

                        return buildAchievementRow(
                          task.title,
                          "${task.progress}/${task.total}",
                          progress,
                          task.icon,
                          task.completed,
                          taskMarks,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildPointsBox(String title, String pointsText) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$title: $pointsText',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget buildAchievementRow(String title, String progressText, double progress, IconData icon, bool completed, double taskMarks) {
    int progressPercentage = (progress * 100).round();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: completed ? Colors.green : Colors.grey, width: 1), // Green border for completed
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                progressText,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: completed ? Colors.green : Colors.blueAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  completed ? 'Completed' : '${taskMarks.toStringAsFixed(1)} / ${taskMarks.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(progress)),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0%', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('$progressPercentage%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
              const Text('100%', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Color getProgressColor(double progress) {
    if (progress >= 0.7) return Colors.green;
    else if (progress >= 0.3) return Colors.blue;
    else return Colors.red;
  }
}
