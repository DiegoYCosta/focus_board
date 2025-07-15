// lib/src/task_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'task_model.dart';
import 'task_storage.dart';
import 'task_edit_dialog.dart';
import 'task_history_page.dart';

class TaskSection extends StatefulWidget {
  final GlobalKey<TaskSectionState>? key;

  TaskSection({this.key}) : super(key: key);

  @override
  TaskSectionState createState() => TaskSectionState();
}

class TaskSectionState extends State<TaskSection> with SingleTickerProviderStateMixin {
  List<TaskModel> tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final loadedTasks = await TaskStorage.loadTasks();
    setState(() {
      tasks = loadedTasks..sort(_sortTasks);
      _isLoading = false;
    });
  }

  int _sortTasks(TaskModel a, TaskModel b) {
    int priorityA = a.isUrgent ? 2 : a.isImportant ? 1 : 0;
    int priorityB = b.isUrgent ? 2 : b.isImportant ? 1 : 0;
    if (priorityA != priorityB) return priorityB - priorityA;

    if (a.dueDate != null && b.dueDate != null) {
      return a.dueDate!.compareTo(b.dueDate!);
    } else if (a.dueDate != null) {
      return -1;
    } else if (b.dueDate != null) {
      return 1;
    }
    return 0;
  }

  Future<void> addOrEditTask([TaskModel? task]) async {
    final editedTask = await showDialog<TaskModel>(
      context: context,
      builder: (_) => TaskEditDialog(task: task),
    );
    if (editedTask != null) {
      setState(() {
        if (task == null) {
          tasks.add(editedTask);
        } else {
          final index = tasks.indexOf(task);
          tasks[index] = editedTask;
        }
        tasks.sort(_sortTasks);
        TaskStorage.saveTasks(tasks);
      });
    }
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        if (task.isCompleted || task.isDeleted) return SizedBox.shrink(); // Exclui concluídas/destruídas da lista principal
        return Dismissible(
          key: Key(task.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            setState(() {
              task.isDeleted = true;
              TaskStorage.saveTasks(tasks);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tarefa excluída')),
            );
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: _getPriorityIcon(task),
              title: Text(
                task.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: task.dueDate != null
                  ? Text(
                'Vencimento: ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.hasAlarm)
                    Icon(Icons.alarm, size: 18, color: Colors.blue[700]),
                  if (task.hasTimer)
                    Icon(Icons.timer, size: 18, color: Colors.orange[700]),
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) {
                      setState(() {
                        task.isCompleted = value ?? false;
                        if (task.isCompleted) task.completionDate = DateTime.now();
                        else task.completionDate = null;
                        TaskStorage.saveTasks(tasks);
                      });
                    },
                    activeColor: Colors.green[700],
                  ),
                ],
              ),
              onTap: () => addOrEditTask(task),
            ),
          ),
        );
      },
    );
  }

  Widget _getPriorityIcon(TaskModel task) {
    return Semantics(
      label: task.isUrgent ? 'Tarefa Urgente' : task.isImportant ? 'Tarefa Importante' : 'Tarefa Normal',
      child: Icon(
        task.isUrgent
            ? Icons.warning
            : task.isImportant
            ? Icons.priority_high
            : Icons.circle,
        color: task.isUrgent
            ? Colors.red
            : task.isImportant
            ? Colors.yellow[700]
            : Colors.grey,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300.0,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildTaskList(),
            ),
          ],
        ),
      ),
    );
  }
}