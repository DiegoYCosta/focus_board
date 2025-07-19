// lib/src/task_model.dart
import 'package:uuid/uuid.dart';

class TaskModel {
  final String id;
  String title;
  bool isUrgent;
  bool isImportant;
  DateTime? dueDate;
  bool hasAlarm;
  DateTime? alarmTime;
  bool hasTimer;
  Duration? timerDuration;
  bool isCompleted;
  DateTime? completionDate;
  bool isDeleted;

  TaskModel({
    required this.id,
    required this.title,
    this.isUrgent = false,
    this.isImportant = false,
    this.dueDate,
    this.hasAlarm = false,
    this.alarmTime,
    this.hasTimer = false,
    this.timerDuration,
    this.isCompleted = false,
    this.completionDate,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isUrgent': isUrgent,
    'isImportant': isImportant,
    'dueDate': dueDate?.toIso8601String(),
    'hasAlarm': hasAlarm,
    'alarmTime': alarmTime?.toIso8601String(),
    'hasTimer': hasTimer,
    'timerDuration': timerDuration?.inSeconds,
    'isCompleted': isCompleted,
    'completionDate': completionDate?.toIso8601String(),
    'isDeleted': isDeleted,
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'],
    title: json['title'],
    isUrgent: json['isUrgent'] ?? false,
    isImportant: json['isImportant'] ?? false,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    hasAlarm: json['hasAlarm'] ?? false,
    alarmTime: json['alarmTime'] != null ? DateTime.parse(json['alarmTime']) : null,
    hasTimer: json['hasTimer'] ?? false,
    timerDuration: json['timerDuration'] != null ? Duration(seconds: json['timerDuration']) : null,
    isCompleted: json['isCompleted'] ?? false,
    completionDate: json['completionDate'] != null ? DateTime.parse(json['completionDate']) : null,
    isDeleted: json['isDeleted'] ?? false,
  );
}