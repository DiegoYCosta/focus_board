import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'task_model.dart';

class TaskStorage {
  static Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/tasks.json';
  }

  static Future<List<TaskModel>> loadTasks() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) return [];
      final jsonStr = await file.readAsString();
      final list = (jsonDecode(jsonStr) as List).map((e) => TaskModel.fromJson(e)).toList();
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveTasks(List<TaskModel> tasks) async {
    final file = File(await _filePath);
    await file.writeAsString(jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }
}