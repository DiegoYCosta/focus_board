import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'task_model.dart';
import 'task_storage.dart';
import 'task_edit_dialog.dart';
import 'task_history_page.dart';

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TaskModel> tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final loadedTasks = await TaskStorage.loadTasks();
    setState(() {
      tasks = loadedTasks;
      _isLoading = false;
    });
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
        TaskStorage.saveTasks(tasks);
      });
    }
  }

  Widget _buildTaskList(List<TaskModel> taskList) {
    return ListView.builder(
      itemCount: taskList.length,
      itemBuilder: (context, index) {
        final task = taskList[index];
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
              title: Text(
                task.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: task.dueDate != null
                  ? Text(
                'Vencimento: ${task.dueDate!.toLocal().toString().split(' ')[0]}',
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarefas', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.grey[200],
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue[700],
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              tabs: [
                Tab(text: 'Urgente'),
                Tab(text: 'Importante'),
                Tab(text: 'Normal'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(tasks.where((t) => t.isUrgent && !t.isCompleted && !t.isDeleted).toList()),
                _buildTaskList(tasks.where((t) => t.isImportant && !t.isUrgent && !t.isCompleted && !t.isDeleted).toList()),
                _buildTaskList(tasks.where((t) => !t.isImportant && !t.isUrgent && !t.isCompleted && !t.isDeleted).toList()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.add, size: 24, color: Colors.blue[700]),
                onPressed: () => addOrEditTask(),
                tooltip: 'Adicionar Tarefa',
              ),
              IconButton(
                icon: Icon(Icons.history, size: 24, color: Colors.grey[600]),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskHistoryPage(),
                    settings: RouteSettings(arguments: tasks),
                  ),
                ),
                tooltip: 'Histórico',
              ),
            ],
          ),
        ),
      ),
    );
  }
}