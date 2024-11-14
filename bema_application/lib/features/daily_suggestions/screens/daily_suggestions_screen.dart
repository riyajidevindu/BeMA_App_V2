import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/cards/water_intake_card.dart';
import 'package:bema_application/common/widgets/progress_indicator/custom_progress_indicator.dart';
import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';
import 'package:bema_application/features/daily_suggestions/data/services/task_service.dart';
import 'package:flutter/material.dart';

class DailytaskScreen extends StatefulWidget {
  const DailytaskScreen({super.key});

  @override
  State<DailytaskScreen> createState() => _DailytaskScreenState();
}

class _DailytaskScreenState extends State<DailytaskScreen> {
  int userPoints = 0;
  Set<int> completedTasks = {};
  int currentPage = 0;
  final PageController _pageController = PageController();
  final TaskService _taskService = TaskService(); // TaskService for Firestore

  bool isLoading = true; // Track loading state
  List<TaskModel> tasks = []; // Initialize empty list to hold tasks

  @override
  void initState() {
    super.initState();
    _generateAndLoadTasksForToday(); // Load or generate today's tasks
  }

  Future<void> _generateAndLoadTasksForToday() async {
    setState(() {
      isLoading = true;
    });

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

      print("Fetched tasks count: ${tasks.length}");
      for (var task in tasks) {
        print("Task: ${task.title}, Completed: ${task.completed}");
      }

      _updateTaskStates();
    } catch (error) {
      print("Error fetching or generating tasks: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateTaskStates() {
    int points = 0;
    Set<int> completed = {};

    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].completed) {
        completed.add(i);
        points += 10; // Assuming 10 points per completed task
      }
    }

    setState(() {
      userPoints = points;
      completedTasks = completed;
    });
  }

  Future<void> _saveTaskProgress(int index) async {
    await _taskService.saveTask(tasks[index]);
  }

  void completeTask(int index) {
    setState(() {
      if (!completedTasks.contains(index)) {
        completedTasks.add(index);
        tasks[index] = tasks[index].copyWith(completed: true);
        userPoints += 10;
        _saveTaskProgress(index); // Save task completion to Firestore
      }
    });
  }

  void updateStepwiseTask(int index, double selectedAmount) {
    setState(() {
      if (!completedTasks.contains(index)) {
        int updatedProgress = tasks[index].progress! + selectedAmount.toInt();

        tasks[index] = tasks[index].copyWith(progress: updatedProgress);

        if (updatedProgress >= tasks[index].total!) {
          completedTasks.add(index);
          userPoints += 10;
        }
        print(
            "Updated task progress: ${tasks[index].progress} / ${tasks[index].total}");
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
          ? const Center(
              child: CustomProgressIndicator(),
            )
          : Column(
              children: [
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
                            backgroundColor: Colors.greenAccent.shade400,
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
                                  color: Colors.blueAccent,
                                  strokeWidth: 10,
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
                            fontSize: 16, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];

                          if (task.title == "Water Intake") {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: WaterIntakeCard(
                                totalWaterGoal: task.total!.toDouble(),
                                currentProgress: task.progress!.toDouble(),
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
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(task.icon,
                                        size: 40, color: Colors.blueAccent),
                                    const SizedBox(height: 10),
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      task.detail,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    completedTasks.contains(index)
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 20),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.greenAccent.shade400,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 24),
                                                const SizedBox(width: 10),
                                                const Text(
                                                  'Completed',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : FloatingActionButton.extended(
                                            onPressed: () =>
                                                completeTask(index),
                                            label: const Text('Mark as Done'),
                                            icon: const Icon(Icons.check),
                                            backgroundColor: Colors.blueAccent,
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
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
