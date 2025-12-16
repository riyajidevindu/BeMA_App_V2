import 'package:flutter/material.dart';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/progress_indicator/custom_progress_indicator.dart';
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/workout_plan/data/models/workout_plan.dart';
import 'package:bema_application/features/workout_plan/data/services/workout_service.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  final WorkoutService _workoutService = WorkoutService();
  bool isLoading = true;
  List<WorkoutPlan> workoutPlans = [];
  Set<int> completedWorkouts = {};
  double userProgress = 0;

  @override
  void initState() {
    super.initState();
    _generateAndLoadWorkoutPlanForToday();
  }

  Future<void> _generateAndLoadWorkoutPlanForToday() async {
    setState(() => isLoading = true);

    List<WorkoutPlan> defaultWorkouts = [
      WorkoutPlan(
        exerciseType: 'Squats',
        description: 'Build lower body strength',
        sets: 3,
        reps: 15,
        duration: 10,
        difficulty: 'Medium',
        icon: Icons.fitness_center,
      ),
      WorkoutPlan(
        exerciseType: 'Push-ups',
        description: 'Upper body and core strength',
        sets: 3,
        reps: 12,
        duration: 8,
        difficulty: 'Medium',
        icon: Icons.accessibility_new,
      ),
      WorkoutPlan(
        exerciseType: 'Plank',
        description: 'Core stability and strength',
        sets: 3,
        reps: 1,
        duration: 5,
        difficulty: 'Easy',
        icon: Icons.self_improvement,
      ),
    ];

    try {
      await _workoutService.generateWorkoutPlanIfNeeded(defaultWorkouts);
      workoutPlans =
          await _workoutService.fetchUserWorkoutPlans(defaultWorkouts);
      setState(() {
        _updateWorkoutStates();
      });
    } catch (error) {
      print("Error fetching or generating workout plan: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _updateWorkoutStates() {
    double progress = 0;
    Set<int> completed = {};

    // Calculate total sets across all workouts
    int totalSets = 0;
    int completedSetsCount = 0;

    for (int i = 0; i < workoutPlans.length; i++) {
      totalSets += workoutPlans[i].sets;
      completedSetsCount += workoutPlans[i].completedSets;

      if (workoutPlans[i].completed) {
        completed.add(i);
      }
    }

    // Calculate progress based on completed sets
    if (totalSets > 0) {
      progress = (completedSetsCount / totalSets) * 100;
    }

    // Update state variables (to be called within setState)
    userProgress = double.parse(progress.toStringAsFixed(1));
    completedWorkouts = completed;
  }

  Future<void> _saveWorkoutProgress(int index) async {
    await _workoutService.saveWorkoutPlan(workoutPlans[index]);
  }

  void completeWorkout(int index) {
    if (!completedWorkouts.contains(index)) {
      setState(() {
        workoutPlans[index] = workoutPlans[index].copyWith(
          completed: true,
          completedSets: workoutPlans[index].sets, // All sets completed
        );

        // Recalculate progress based on all completed sets
        _updateWorkoutStates();
        _saveWorkoutProgress(index);
      });

      showSuccessSnackBarMessage(
          context, '${workoutPlans[index].exerciseType} completed! 🎉');
    }
  }

  void completeSet(int index) {
    WorkoutPlan workout = workoutPlans[index];

    if (workout.completedSets < workout.sets) {
      setState(() {
        int newCompletedSets = workout.completedSets + 1;
        bool isFullyCompleted = newCompletedSets >= workout.sets;

        workoutPlans[index] = workout.copyWith(
          completedSets: newCompletedSets,
          completed: isFullyCompleted,
        );

        // Recalculate progress based on all completed sets
        _updateWorkoutStates();
        _saveWorkoutProgress(index);
      });

      if (workout.completedSets + 1 >= workout.sets) {
        showSuccessSnackBarMessage(
            context, '${workout.exerciseType} completed! 🎉');
      } else {
        showSuccessSnackBarMessage(context,
            'Set ${workout.completedSets + 1}/${workout.sets} completed! 💪');
      }
    }
  }

  void _showEditWorkoutDialog(int index) {
    WorkoutPlan workout = workoutPlans[index];
    int sets = workout.sets;
    int reps = workout.reps;
    int duration = workout.duration;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit ${workout.exerciseType}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sets:', style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (sets > 1) {
                              setDialogState(() => sets--);
                            }
                          },
                        ),
                        Text('$sets', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setDialogState(() => sets++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                // Reps
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Reps:', style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (reps > 1) {
                              setDialogState(() => reps--);
                            }
                          },
                        ),
                        Text('$reps', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setDialogState(() => reps++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                // Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Duration (min):',
                        style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (duration > 1) {
                              setDialogState(() => duration--);
                            }
                          },
                        ),
                        Text('$duration', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setDialogState(() => duration++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                workoutPlans[index] = workoutPlans[index].copyWith(
                  sets: sets,
                  reps: reps,
                  duration: duration,
                );
                _saveWorkoutProgress(index);
              });
              Navigator.pop(context);
              showSuccessSnackBarMessage(
                  context, 'Workout updated successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int totalWorkouts = workoutPlans.length;
    int completedCount = completedWorkouts.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CustomProgressIndicator())
          : Column(
              children: [
                // Header with progress
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04, // Responsive padding
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Chip(
                              backgroundColor: primaryColor.withOpacity(0.2),
                              label: Text(
                                '${userProgress.toStringAsFixed(0)}% Complete',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      screenWidth * 0.035, // Responsive font
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                '$completedCount / $totalWorkouts Workouts',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      screenWidth * 0.035, // Responsive font
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: userProgress / 100, // Use set-based progress
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Workout list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom +
                          100, // Bottom navbar padding
                    ),
                    itemCount: workoutPlans.length,
                    itemBuilder: (context, index) {
                      final workout = workoutPlans[index];
                      final isCompleted = completedWorkouts.contains(index);
                      final hasPartialCompletion =
                          workout.completedSets > 0 && !isCompleted;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: isCompleted
                                ? LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(0.3),
                                      Colors.green.withOpacity(0.1),
                                    ],
                                  )
                                : hasPartialCompletion
                                    ? LinearGradient(
                                        colors: [
                                          Colors.orange.withOpacity(0.2),
                                          Colors.orange.withOpacity(0.05),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          primaryColor.withOpacity(0.1),
                                          Colors.white,
                                        ],
                                      ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? Colors.green
                                            : primaryColor,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        workout.icon,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            workout.exerciseType,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isCompleted
                                                  ? Colors.green.shade700
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            workout.description,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCompleted)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 32,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Workout details
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildDetailChip(
                                      icon: Icons.repeat,
                                      label: hasPartialCompletion
                                          ? '${workout.completedSets}/${workout.sets} Sets'
                                          : '${workout.sets} Sets',
                                      isHighlighted: hasPartialCompletion,
                                    ),
                                    _buildDetailChip(
                                      icon: Icons.fitness_center,
                                      label: '${workout.reps} Reps',
                                    ),
                                    _buildDetailChip(
                                      icon: Icons.timer,
                                      label: '${workout.duration} min',
                                    ),
                                  ],
                                ),
                                // Show progress bar for partial completion
                                if (hasPartialCompletion) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value:
                                          workout.completedSets / workout.sets,
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.orange),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                // Difficulty badge
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getDifficultyColor(
                                              workout.difficulty)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      workout.difficulty,
                                      style: TextStyle(
                                        color: _getDifficultyColor(
                                            workout.difficulty),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Action buttons
                                Row(
                                  children: [
                                    // Complete Set button (only if not fully completed)
                                    if (!isCompleted) ...[
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => completeSet(index),
                                          icon: const Icon(Icons.add_task,
                                              size: 18),
                                          label: Text(
                                            workout.completedSets > 0
                                                ? 'Next Set'
                                                : 'Complete Set',
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    // Complete All button
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: isCompleted
                                            ? null
                                            : () => completeWorkout(index),
                                        icon: Icon(
                                          isCompleted
                                              ? Icons.check
                                              : Icons.done_all,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isCompleted
                                              ? 'Completed'
                                              : 'Complete All',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isCompleted
                                              ? Colors.grey
                                              : Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () =>
                                          _showEditWorkoutDialog(index),
                                      icon: const Icon(Icons.edit, size: 20),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            primaryColor.withOpacity(0.2),
                                        foregroundColor: primaryColor,
                                      ),
                                    ),
                                  ],
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

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.orange.withOpacity(0.3)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted
              ? Colors.orange.withOpacity(0.5)
              : primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isHighlighted ? Colors.orange : primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.orange : primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
