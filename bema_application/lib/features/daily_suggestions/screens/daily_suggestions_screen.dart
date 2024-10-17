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
  List<TaskModel> tasks = [
     TaskModel(
      title: "Water Intake",
      detail: "You should drink 2.5 liters of water today.",
      icon: Icons.local_drink,
      type: "stepwise",
      total: 2500,
      progress: 0,
      stepAmount: 250,
    ),
    TaskModel(
      title: "Walking Duration",
      detail: "Aim to walk for 45 minutes or complete 6000 steps today.",
      icon: Icons.directions_walk,
      type: "regular",
    ),
    TaskModel(
      title: "Stretching Time",
      detail: "Spend 10 minutes doing flexibility exercises.",
      icon: Icons.accessibility_new,
      type: "regular",
    ),
    TaskModel(
      title: "Mindfulness Exercise",
      detail: "Try 10 minutes of mindfulness meditation today.",
      icon: Icons.self_improvement,
      type: "regular",
    ),
    TaskModel(
      title: "Nutrition Tip",
      detail: "Eat at least 5 servings of fruits and vegetables.",
      icon: Icons.local_dining,
      type: "regular",
    ),
    TaskModel(
      title: "Sleep Reminder",
      detail: "Aim for at least 7 hours of sleep tonight.",
      icon: Icons.bedtime,
      type: "regular",
    ),
    TaskModel(
      title: "Screen Time Break",
      detail: "Take a 15-minute break after every hour of screen time.",
      icon: Icons.tv_off,
      type: "stepwise",
      total: 4,
      progress: 0,
      stepAmount: 1,
    ),
    TaskModel(
      title: "Special Task",
      detail: "Today's challenge: Avoid sugary snacks.",
      icon: Icons.no_food,
      type: "regular",
    ),
    TaskModel(
      title: "Social Interaction",
      detail: "Reach out to a friend for a quick chat.",
      icon: Icons.group,
      type: "regular",
    ),
    TaskModel(
      title: "Posture Check",
      detail: "Make sure to check your posture every hour.",
      icon: Icons.accessibility,
      type: "regular",
    ),

    // Add more tasks here
  ];

  @override
  void initState() {
    super.initState();
    _loadTasksFromFirestore(); // Load tasks from Firestore on screen load
  }

  /// Fetch user's task progress from Firestore
  Future<void> _loadTasksFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    tasks = await _taskService.fetchUserTasks(tasks); 
    // Update the user points and completed tasks based on the fetched data
    _updateTaskStates();
    
    setState(() {
      isLoading = false; // Stop loading once tasks are fetched
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
  void updateStepwiseTask(int index) {
    setState(() {
      if (!completedTasks.contains(index)) {
        tasks[index] = tasks[index].copyWith(
          progress: (tasks[index].progress! + tasks[index].stepAmount!),
        );
        if (tasks[index].progress! >= tasks[index].total!) {
          completedTasks.add(index);
          userPoints += 10;
        }
        _saveTaskProgress(index); // Save updated progress to Firestore
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        ? const Center(child: CircularProgressIndicator()) // Show a loader while data is fetched
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Points: $userPoints',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: taskCompletionPercentage,
                        backgroundColor: Colors.grey[200],
                        color: Colors.blueAccent,
                        strokeWidth: 8,
                      ),
                      Text(
                        '${(taskCompletionPercentage * 100).toInt()}%',
                        style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Completed $completedCount / $totalTasks tasks',
                    style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),

            // PageView for tasks
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
                            onProgressUpdate: () => updateStepwiseTask(index),
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
                                Icon(task.icon, size: 40, color: Colors.blueAccent),
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
                                ElevatedButton(
                                  onPressed: completedTasks.contains(index)
                                      ? null
                                      : () => completeTask(index),
                                  child: Text(
                                    completedTasks.contains(index) ? "Completed" : "Mark as Done",
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
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent),
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
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
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
