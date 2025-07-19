// lib/src/task_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_storage.dart';
import 'task_edit_dialog.dart';

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
      builder: (_) => TaskEditDialog(task: task, isNew: task == null), // Passa flag isNew
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

  Widget _getPriorityIcon(TaskModel task) {
    return Semantics(
      label: task.isUrgent ? 'Tarefa Urgente' : task.isImportant ? 'Tarefa Importante' : 'Tarefa Normal',
      child: Icon(
        task.isUrgent
            ? Icons.warning_rounded
            : task.isImportant
            ? Icons.priority_high_rounded
            : Icons.circle_outlined,
        color: task.isUrgent
            ? Colors.red[600]
            : task.isImportant
            ? Colors.yellow[800]
            : Colors.grey[600],
        size: 20,
      ),
    );
  }

  Color _getBackgroundColor(TaskModel task) {
    return task.isUrgent
        ? Colors.red[50]!
        : task.isImportant
        ? Colors.yellow[50]!
        : Colors.yellow[100]!;
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        if (task.isCompleted || task.isDeleted) return SizedBox.shrink();
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
          child: Transform.rotate(
            angle: task.isUrgent ? 0.02 : task.isImportant ? 0.01 : -0.01, // Leve rotação para efeito de post-it
            child: Card(
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.2),
              color: _getBackgroundColor(task),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: _getPriorityIcon(task),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto', // Fonte mais suave
                  ),
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
                      Icon(Icons.alarm_rounded, size: 18, color: Colors.blue[600]),
                    if (task.hasTimer)
                      Icon(Icons.timer_rounded, size: 18, color: Colors.orange[600]),
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
                      activeColor: Colors.green[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ],
                ),
                onTap: () => addOrEditTask(task),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300.0,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Tarefas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
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