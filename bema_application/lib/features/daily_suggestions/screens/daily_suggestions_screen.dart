import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/cards/water_intake_card.dart';
import 'package:bema_application/common/widgets/progress_indicator/custom_progress_indicator.dart';
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';
import 'package:bema_application/features/daily_suggestions/data/services/task_service.dart';
import 'package:flutter/material.dart';

class DailytaskScreen extends StatefulWidget {
  const DailytaskScreen({super.key});

  @override
  State<DailytaskScreen> createState() => _DailytaskScreenState();
}

class _DailytaskScreenState extends State<DailytaskScreen> {
  double userPoints = 0;
  Set<int> completedTasks = {};
  int currentPage = 0;
  final PageController _pageController = PageController();
  final TaskService _taskService = TaskService();

  bool isLoading = true;
  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    _generateAndLoadTasksForToday();
  }

  Future<void> _generateAndLoadTasksForToday() async {
    setState(() => isLoading = true);

    List<TaskModel> defaultTasks = [
      TaskModel(
        title: "Water Intake",
        detail: "Drink 2.5 liters of water",
        icon: Icons.local_drink,
        type: "stepwise",
        total: 2500,
        progress: 0,
        stepAmount: 250,
      ),
      TaskModel(
        title: "Walking Duration",
        detail: "Walk for 45 minutes or 6000 steps",
        icon: Icons.directions_walk,
        type: "regular",
      ),
    ];

    try {
      await _taskService.generateDailyTasksIfNeeded(defaultTasks);
      tasks = await _taskService.fetchUserTasks(defaultTasks);
      _updateTaskStates();
    } catch (error) {
      print("Error fetching or generating tasks: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _updateTaskStates() {
    double points = 0;
    Set<int> completed = {};
    double pointsPerTask = tasks.isNotEmpty ? 100 / tasks.length : 0;

    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].completed) {
        completed.add(i);
        points += pointsPerTask;
      }
    }

    setState(() {
      userPoints = double.parse(points.toStringAsFixed(1)); // Round to 1 decimal
      completedTasks = completed;
    });
  }

  Future<void> _saveTaskProgress(int index) async {
    await _taskService.saveTask(tasks[index]);
  }

  void completeTask(int index) {
    if (!completedTasks.contains(index)) {
      setState(() {
        completedTasks.add(index);
        tasks[index] = tasks[index].copyWith(completed: true);

        double pointsPerTask = tasks.isNotEmpty ? 100 / tasks.length : 0;
        userPoints = double.parse((userPoints + pointsPerTask).toStringAsFixed(1)); // Rounded

        _saveTaskProgress(index);
      });

     showSuccessSnackBarMessage(context, '${tasks[index].title} marked as completed!');
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('${tasks[index].title} marked as completed!'),
    //     backgroundColor: Colors.green,
    //   ),
    // );
    }
  }

  void updateStepwiseTask(int index, double selectedAmount) {
    setState(() {
      if (!completedTasks.contains(index)) {
        int updatedProgress = tasks[index].progress + selectedAmount.toInt();

        tasks[index] = tasks[index].copyWith(progress: updatedProgress);

        if (updatedProgress >= tasks[index].total!) {
          completeTask(index); // Mark as completed if goal reached
        }
        _saveTaskProgress(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int totalTasks = tasks.length;
    int completedCount = completedTasks.length;
    double taskCompletionPercentage =
        totalTasks > 0 ? completedCount / totalTasks : 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CustomProgressIndicator())
          : Column(
              children: [
                // Header showing points and task progress
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(
                              'Points: $userPoints',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.blueAccent.shade200,
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: screenWidth * 0.2,
                                height: screenWidth * 0.2,
                                child: CircularProgressIndicator(
                                  value: taskCompletionPercentage,
                                  backgroundColor: Colors.grey[200],
                                  color: Colors.greenAccent.shade400,
                                  strokeWidth: 8,
                                ),
                              ),
                              Text(
                                '${(taskCompletionPercentage * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Completed $completedCount / $totalTasks tasks',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // PageView for displaying task cards
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => currentPage = index),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];

                          if (task.title == "Water Intake") {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: WaterIntakeCard(
                                totalWaterGoal: task.total!.toDouble(),
                                currentProgress: task.progress.toDouble(),
                                onProgressUpdate: (selectedAmount) =>
                                    updateStepwiseTask(index, selectedAmount),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(task.icon,
                                        size: 50, color: Colors.blueAccent),
                                    const SizedBox(height: 10),
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      task.detail,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    completedTasks.contains(index)
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 24),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Completed',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () => completeTask(index),
                                            label: const Text(
                                              'Mark as Done',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            icon: const Icon(Icons.check),
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 24),
                                              elevation: 5,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (currentPage > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      if (currentPage < tasks.length - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios,
                                color: Colors.blueAccent),
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
                ),
              ],
            ),
    );
  }
}
