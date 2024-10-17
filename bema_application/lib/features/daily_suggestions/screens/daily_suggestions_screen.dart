import 'package:bema_application/common/config/colors.dart'; // Custom colors
import 'package:bema_application/common/widgets/app_bar.dart'; // Custom AppBar
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/daily_suggestions/data/models/daily_task.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter to handle navigation

class DailytaskScreen extends StatefulWidget {
  const DailytaskScreen({super.key});

  @override
  State<DailytaskScreen> createState() => _DailytaskScreenState();
}

class _DailytaskScreenState extends State<DailytaskScreen> {
  int userPoints = 0; // Track user points
  Set<int> completedTasks = Set(); // Track completed tasks
  int currentPage = 0; // Track the current page index for PageView
  final PageController _pageController = PageController(); // Add PageController

  // List of daily tasks with the new TaskModel
  final List<TaskModel> tasks = [
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
  ];


  // Function to mark regular tasks as complete
  void completeTask(int index) {
    setState(() {
      if (!completedTasks.contains(index)) {
        completedTasks.add(index);
        userPoints += 10; // Award 10 points per task
      }
    });
  }

  // Function to handle progress updates for stepwise tasks
  void updateStepwiseTask(int index) {
    setState(() {
      if (!completedTasks.contains(index)) {
        // Update progress
        tasks[index] = tasks[index].copyWith(
          progress: (tasks[index].progress! + tasks[index].stepAmount!),
        );

        // Check if task is completed
        if (tasks[index].progress! >= tasks[index].total!) {
          completedTasks.add(index);
          userPoints += 10; // Award 10 points when the task is fully completed
          showSuccessSnackBarMessage(context, '${tasks[index].title} task completed!');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress of tasks completed
    int totalTasks = tasks.length;
    int completedCount = completedTasks.length;
    double taskCompletionPercentage = completedCount / totalTasks;

    return Scaffold(
      backgroundColor: backgroundColor, // Use custom background color
      appBar: AppBar(
        backgroundColor: backgroundColor, // Consistent background color
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 3, 0, 0)), // Back arrow icon
        //   onPressed: () {
        //     context.pop(); // Use GoRouter's pop method to go back
        //   },
        // ),
        title: const CustomAppBar(), // Use custom AppBar widget
      ),
      body: Column(
        children: [
          // Task completion progress
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Points: $userPoints', // Display user points
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 1, 34, 75),
                  ),
                ),
                SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: taskCompletionPercentage,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blueAccent,
                      strokeWidth: 6,
                    ),
                    Text(
                      '${(taskCompletionPercentage * 100).toInt()}%', // Show completion percentage
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Completed $completedCount / $totalTasks tasks',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),

          // PageView for tasks
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController, // Connect PageController
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemCount: tasks.length, // Number of tasks
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    // Stepwise task UI
                    if (task.type == 'stepwise') {
                      double progressPercentage = (task.progress! / task.total!) * 100;
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(task.icon, size: 50, color: Colors.blueAccent),
                              SizedBox(height: 10),
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 1, 34, 75),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                task.detail,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 30),
                              LinearProgressIndicator(
                                value: task.progress! / task.total!,
                                backgroundColor: Colors.grey[200],
                                color: Colors.blueAccent,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Progress: ${progressPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              ElevatedButton(
                                onPressed: completedTasks.contains(index)
                                    ? null // Disable if already completed
                                    : () {
                                        updateStepwiseTask(index); // Update progress for stepwise tasks
                                      },
                                child: Text(
                                  completedTasks.contains(index) ? "Completed" : "Add Progress",
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Regular task UI
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(task.icon, size: 50, color: Colors.blueAccent),
                            SizedBox(height: 10),
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 1, 34, 75),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              task.detail,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: completedTasks.contains(index)
                                  ? null // Disable if already completed
                                  : () {
                                      completeTask(index);
                                      showSuccessSnackBarMessage(
                                        context,
                                        '${task.title} task completed!',
                                      );
                                    },
                              child: Text(
                                completedTasks.contains(index) ? "Completed" : "Mark as Done",
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Left arrow for previous task
                if (currentPage > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.blueAccent),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ); // Move to previous page
                      },
                    ),
                  ),

                // Right arrow for next task
                if (currentPage < tasks.length - 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ); // Move to next page
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
