import 'package:bema_application/common/config/colors.dart'; // Custom colors
import 'package:bema_application/common/widgets/app_bar.dart'; // Custom AppBar
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter to handle navigation

class DailytaskScrenn extends StatefulWidget {
  const DailytaskScrenn({super.key});

  @override
  State<DailytaskScrenn> createState() => _DailytaskScrennState();
}

class _DailytaskScrennState extends State<DailytaskScrenn> {
  int userPoints = 0; // Track user points
  Set<int> completedTasks = Set(); // Track completed tasks

  // List of daily suggestions
  final List<Map<String, String>> suggestions = [
    {"title": "Water Intake", "detail": "You should drink 2.5 liters of water today."},
    {"title": "Walking Duration", "detail": "Aim to walk for 45 minutes or complete 6000 steps today."},
    {"title": "Stretching Time", "detail": "Spend 10 minutes doing flexibility exercises."},
    {"title": "Mindfulness Exercise", "detail": "Try 10 minutes of mindfulness meditation today."},
    {"title": "Nutrition Tip", "detail": "Eat at least 5 servings of fruits and vegetables."},
    {"title": "Sleep Reminder", "detail": "Aim for at least 7 hours of sleep tonight."},
    {"title": "Screen Time Break", "detail": "Take a 15-minute break after every hour of screen time."},
    {"title": "Special Task", "detail": "Today's challenge: Avoid sugary snacks."},
    {"title": "Social Interaction", "detail": "Reach out to a friend for a quick chat."},
    {"title": "Posture Check", "detail": "Make sure to check your posture every hour."},
  ];

  // Function to mark tasks as complete
  void completeTask(int index) {
    setState(() {
      if (!completedTasks.contains(index)) {
        completedTasks.add(index);
        userPoints += 10; // Award 10 points per task
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Use custom background color
      appBar: AppBar(
        backgroundColor: backgroundColor, // Consistent background color
        // Custom AppBar with back button using GoRouter
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back arrow icon
          onPressed: () {
            context.pop(); // Use GoRouter's pop method to go back
          },
        ),
        title: const CustomAppBar(), // Use custom AppBar widget
      ),
      body: Column(
        children: [
          // Display user points in the AppBar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Points: $userPoints', // Display the points
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 1, 34, 75),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: suggestions.length, // Number of suggestions
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
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
                        Text(
                          suggestion['title']!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 1, 34, 75),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          suggestion['detail']!,
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
                                  completeTask(index); // Mark task as completed
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${suggestion['title']} task completed!'),
                                    ),
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
          ),
        ],
      ),
    );
  }
}
