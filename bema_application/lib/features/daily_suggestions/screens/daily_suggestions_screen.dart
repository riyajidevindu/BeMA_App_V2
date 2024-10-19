import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/cards/water_intake_card.dart';
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
  Set<int> completedTasks = Set(); 
  int currentPage = 0; 
  final PageController _pageController = PageController();
  final TaskService _taskService = TaskService(); // TaskService for Firestore

  bool isLoading = true; // To track loading state
  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    _initializeTasks(); // Initialize tasks from API and Firestore
  }

  /// Initialize tasks from the API and then check Firestore for updates
  Future<void> _initializeTasks() async {
    setState(() {
      isLoading = true;
    });

    // Check if tasks for today are already saved in Firestore
    bool isTasksSaved = await _taskService.isTaskListSavedForToday();

    if (!isTasksSaved) {
      // Fetch tasks from API and save them for today
      tasks = await _taskService.fetchTasksFromAPI();
      await _taskService.saveTaskForToday(tasks); // Save the fetched tasks to Firestore
    }

    // Fetch user task progress from Firestore
    tasks = await _taskService.fetchUserTasksForToday(tasks);
    
    // Update the user points and completed tasks based on the fetched data
    _updateTaskStates();
    
    setState(() {
      isLoading = false;
    });
  }

  /// Update task states after fetching data from Firestore
  void _updateTaskStates() {
    int points = 0;
    Set<int> completed = Set();

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

  /// Save task progress in Firestore
  Future<void> _saveTaskProgress(int index) async {
    await _taskService.saveTask(tasks[index]);
  }

  /// Function to mark tasks as complete and save to Firestore
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

  /// Function to update stepwise tasks like Water Intake
  void updateStepwiseTask(int index, double selectedAmount) {
    setState(() {
      if (!completedTasks.contains(index)) {
        int updatedProgress = tasks[index].progress! + selectedAmount.toInt();
        tasks[index] = tasks[index].copyWith(progress: updatedProgress);
        
        if (updatedProgress >= tasks[index].total!) {
          completedTasks.add(index);
          userPoints += 10;
        }
        _saveTaskProgress(index); // Save updated progress to Firestore
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int totalTasks = tasks.length;
    int completedCount = completedTasks.length;
    double taskCompletionPercentage = completedCount / totalTasks;

    return Scaffold(
      backgroundColor: backgroundColor, 
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const CustomAppBar(),
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      'Points: $userPoints',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Completed $completedCount / $totalTasks tasks',
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView.builder(
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
                        onProgressUpdate: (selectedAmount) => updateStepwiseTask(index, selectedAmount),
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
                            Icon(Icons.task, size: 40, color: Colors.blueAccent),
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
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            completedTasks.contains(index)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.shade400,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Completed',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                )
                              : FloatingActionButton.extended(
                                  onPressed: () => completeTask(index),
                                  label: const Text('Mark as Done'),
                                  icon: const Icon(Icons.check),
                                  backgroundColor: Colors.blueAccent,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}
