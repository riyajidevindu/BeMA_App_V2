import 'package:flutter/material.dart';

class WorkoutPlan {
  final String exerciseType;
  final String description;
  final int sets;
  final int reps;
  final int duration; // in minutes
  final String difficulty;
  final bool completed;
  final int completedSets; // Track completed sets
  final IconData icon;

  WorkoutPlan({
    required this.exerciseType,
    required this.description,
    required this.sets,
    required this.reps,
    required this.duration,
    required this.difficulty,
    this.completed = false,
    this.completedSets = 0,
    required this.icon,
  });

  /// Factory to create a WorkoutPlan from Firestore data
  factory WorkoutPlan.fromFirestore(Map<String, dynamic> data) {
    return WorkoutPlan(
      exerciseType: data['exerciseType'] as String,
      description: data['description'] as String,
      sets: data['sets'] as int,
      reps: data['reps'] as int,
      duration: data['duration'] as int,
      difficulty: data['difficulty'] as String,
      completed: data['completed'] as bool? ?? false,
      completedSets: data['completedSets'] as int? ?? 0,
      icon: IconData(data['icon'], fontFamily: 'MaterialIcons'),
    );
  }

  /// Convert WorkoutPlan to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'exerciseType': exerciseType,
      'description': description,
      'sets': sets,
      'reps': reps,
      'duration': duration,
      'difficulty': difficulty,
      'completed': completed,
      'completedSets': completedSets,
      'icon': icon.codePoint,
    };
  }

  /// Copy method to update workout data
  WorkoutPlan copyWith({
    String? exerciseType,
    String? description,
    int? sets,
    int? reps,
    int? duration,
    String? difficulty,
    bool? completed,
    int? completedSets,
    IconData? icon,
  }) {
    return WorkoutPlan(
      exerciseType: exerciseType ?? this.exerciseType,
      description: description ?? this.description,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      completed: completed ?? this.completed,
      completedSets: completedSets ?? this.completedSets,
      icon: icon ?? this.icon,
    );
  }
}

/// Helper function to convert API output into WorkoutPlan objects
List<WorkoutPlan> convertApiOutputToWorkoutPlans(
    Map<String, dynamic> apiOutput) {
  const Map<String, IconData> iconMapping = {
    "squats": Icons.fitness_center,
    "push_ups": Icons.accessibility_new,
    "lunges": Icons.directions_walk,
    "plank": Icons.self_improvement,
    "jumping_jacks": Icons.sports_gymnastics,
    "burpees": Icons.sports_handball,
    "mountain_climbers": Icons.landscape,
    "sit_ups": Icons.airline_seat_recline_normal,
    "leg_raises": Icons.air,
    "cardio": Icons.directions_run,
    "yoga": Icons.spa,
    "stretching": Icons.accessibility,
  };

  // If API returns a workout_plan array or similar structure
  if (apiOutput.containsKey('workout_plan')) {
    var workoutPlanData = apiOutput['workout_plan'];

    if (workoutPlanData is List) {
      return workoutPlanData.map((workout) {
        String exerciseType =
            (workout['exercise_type'] ?? workout['exerciseType'] ?? 'Exercise')
                .toString()
                .toLowerCase();

        return WorkoutPlan(
          exerciseType: workout['exercise_type'] ?? workout['exerciseType'],
          description: workout['description'] ?? '',
          sets: workout['sets'] ?? 3,
          reps: workout['reps'] ?? 10,
          duration: workout['duration'] ?? 15,
          difficulty: workout['difficulty'] ?? 'Medium',
          completed: workout['completed'] ?? false,
          icon: iconMapping[exerciseType] ?? Icons.fitness_center,
        );
      }).toList();
    }
  }

  // Default workout plans if API response is not in expected format
  return [
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
}
