import 'package:flutter/material.dart';

class TaskModel {
  final String title;
  final String detail;
  final IconData icon;
  final String type; // "stepwise" or "regular"
  final int? total; // Total steps or amount (e.g., 2500ml for water intake)
  final int? progress; // Current progress (e.g., 500ml for water intake)
  final int? stepAmount; // Amount to increment for stepwise tasks
  final bool completed; // If the task is completed or not

  TaskModel({
    required this.title,
    required this.detail,
    required this.icon,
    required this.type,
    this.total,
    this.progress = 0,
    this.stepAmount,
    this.completed = false,
  });

  // Factory to create a TaskModel from Firestore data
  factory TaskModel.fromFirestore(Map<String, dynamic> data) {
    return TaskModel(
      title: data['title'] as String,
      detail: data['detail'] as String,
      icon: IconData(data['icon'], fontFamily: 'MaterialIcons'),
      type: data['type'] as String,
      total: data['total'] as int?,
      progress: data['progress'] as int? ?? 0,
      stepAmount: data['stepAmount'] as int?,
      completed: data['completed'] as bool? ?? false,
    );
  }

  // Convert TaskModel to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'detail': detail,
      'icon': icon.codePoint, // Convert IconData to integer
      'type': type,
      'total': total,
      'progress': progress,
      'stepAmount': stepAmount,
      'completed': completed,
    };
  }

  // Copy method to update task data
  TaskModel copyWith({
    String? title,
    String? detail,
    IconData? icon,
    String? type,
    int? total,
    int? progress,
    int? stepAmount,
    bool? completed,
  }) {
    return TaskModel(
      title: title ?? this.title,
      detail: detail ?? this.detail,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      total: total ?? this.total,
      progress: progress ?? this.progress,
      stepAmount: stepAmount ?? this.stepAmount,
      completed: completed ?? this.completed,
    );
  }
}

// Function to convert LLM output to TaskModel
List<TaskModel> convertLLMOutputToTasks(Map<String, dynamic> llmOutput) {
  // Mapping of task names to Material icons
  const Map<String, IconData> iconMapping = {
    "water_intake": Icons.local_drink,
    "walking_duration": Icons.directions_walk,
    "stretching_time": Icons.accessibility_new,
    "stretching_duration": Icons.accessibility_new,
    "mindfulness_exercise": Icons.self_improvement,
    "nutrition_tip": Icons.local_dining,
    "sleep_reminder": Icons.bedtime,
    "screen_time_break": Icons.tv_off,
    "special_task": Icons.no_food,
    "social_interaction": Icons.group,
    "posture_reminder": Icons.accessibility,
  };

  return llmOutput.entries.map((entry) {
    String key = entry.key;
    Map<String, dynamic> data = entry.value;

    // Determine task type and assign step amount for stepwise tasks
    String type = data['type'] ?? 'regular';
    int? total = data['total'] as int? ?? (type == 'stepwise' ? 10 : null);
    int stepAmount = (type == 'stepwise' && total != null) ? (total ~/ 5) : 0;

    return TaskModel(
      title: data['title'] ?? key,
      detail: data['detail'] ?? '',
      icon: iconMapping[key] ?? Icons.help_outline,
      type: type,
      total: total,
      progress: 0,
      stepAmount: stepAmount > 0 ? stepAmount : null,
      completed: false,
    );
  }).toList();
}
