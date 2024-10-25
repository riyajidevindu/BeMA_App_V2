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

  // Create a TaskModel from Firestore data
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
