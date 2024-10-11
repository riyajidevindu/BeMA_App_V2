import 'package:flutter/material.dart';

class TaskModel {
  final String title;
  final String detail;
  final IconData icon;
  final String type; // "stepwise" or "regular"
  final int? total; // Only for stepwise tasks
  final int? progress; // Only for stepwise tasks
  final int? stepAmount; // Only for stepwise tasks

  TaskModel({
    required this.title,
    required this.detail,
    required this.icon,
    required this.type,
    this.total,
    this.progress,
    this.stepAmount,
  });

  // Method to update progress for stepwise tasks
  TaskModel copyWith({
    String? title,
    String? detail,
    IconData? icon,
    String? type,
    int? total,
    int? progress,
    int? stepAmount,
  }) {
    return TaskModel(
      title: title ?? this.title,
      detail: detail ?? this.detail,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      total: total ?? this.total,
      progress: progress ?? this.progress,
      stepAmount: stepAmount ?? this.stepAmount,
    );
  }
}
