import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/progress_indicator/custom_progress_indicator.dart';
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
  double monthlyPoints = 0;
  double totalDailyMarks = 100; // Total marks for the day
  double totalMonthlyMarks = 100; // Total marks for the month
  List<TaskModel> dailyTasks = [];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    loadUserData(); // Initiate data loading
  }

  /// Fetch daily and monthly points along with daily tasks
  Future<void> loadUserData() async {
    setState(() => isLoading = true); // Start loading
    try {
      final taskSummary = await markService.fetchTaskSummary();

      setState(() {
        dailyTasks = taskSummary['dailyTasks'];
        dailyPoints = taskSummary['dailyPoints'];
        monthlyPoints = taskSummary['monthlyPoints'];
        totalMonthlyMarks = taskSummary['monthlyTotalPoints'];
        isLoading = false; // Stop loading when data is ready
      });
    } catch (error) {
      debugPrint("Error fetching task summary: $error");
      setState(() => isLoading = false); // Stop loading even on error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define responsive text and padding sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSizeTitle = screenWidth * 0.045;
    final fontSizePoints = screenWidth * 0.055;
    final iconSize = screenWidth * 0.08;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CustomProgressIndicator( ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Points Display (Daily and Monthly) with Arrow Indicators
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        child: PageView(
                          controller: _pageController,
                          scrollDirection: Axis.horizontal,
                          children: [
                            buildPointsBox(
                                "Daily Points",
                                "$dailyPoints / $totalDailyMarks",
                                fontSizeTitle,
                                fontSizePoints),
                            buildPointsBox(
                                "Monthly Points",
                                "$monthlyPoints / $totalMonthlyMarks",
                                fontSizeTitle,
                                fontSizePoints),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.blueAccent, size: 24),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Colors.blueAccent, size: 24),
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Task List
                  Expanded(
                    child: ListView.builder(
                      itemCount: dailyTasks.length,
                      itemBuilder: (context, index) {
                        TaskModel task = dailyTasks[index];
                        double progress = task.completed
                            ? 1.0
                            : (task.total != null && task.total! > 0)
                                ? (task.progress / task.total!).clamp(0, 1)
                                : 0;

                        // Calculate marks for the task
                        double taskMarks = (totalDailyMarks / dailyTasks.length)
                                .isNaN
                            ? 0.0
                            : (totalDailyMarks / dailyTasks.length);
                        double obtainedMarks = task.completed
                            ? taskMarks
                            : (task.progress / (task.total ?? 1) * taskMarks)
                                    .isNaN
                                ? 0.0
                                : (task.progress / (task.total ?? 1) *
                                    taskMarks);

                        return buildAchievementRow(
                          task.title,
                          "${obtainedMarks.toStringAsFixed(1)} / ${taskMarks.toStringAsFixed(1)}",
                          progress,
                          task.icon,
                          task.completed,
                          fontSizeTitle,
                          iconSize,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Responsive points box with dynamic font size
  Widget buildPointsBox(String title, String pointsText, double fontSizeTitle,
      double fontSizePoints) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.withOpacity(0.3), Colors.blueGrey.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSizeTitle,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            pointsText,
            style: TextStyle(
              fontSize: fontSizePoints,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Updated task card with responsive elements
  Widget buildAchievementRow(String title, String marksText, double progress,
      IconData icon, bool completed, double fontSizeTitle, double iconSize) {
    int progressPercentage = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: completed ? Colors.green : Colors.blueGrey, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: iconSize),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: fontSizeTitle,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: completed ? Colors.green : Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  completed ? 'Completed' : marksText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(progress)),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0%',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '$progressPercentage%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Text(
                '100%',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Color based on progress for the progress bar
  Color getProgressColor(double progress) {
    if (progress >= 0.7) {
      return Colors.green;
    } else if (progress >= 0.3) return Colors.blue;
    else return Colors.redAccent;
  }
}
