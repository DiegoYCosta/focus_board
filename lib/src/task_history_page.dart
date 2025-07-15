import 'package:flutter/material.dart';
import 'task_model.dart';

class TaskHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = ModalRoute.of(context)!.settings.arguments as List<TaskModel>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Tarefas', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: [
          if (tasks.where((t) => t.isCompleted && !t.isDeleted).isNotEmpty)
            Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text('Tarefas Concluídas', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasks
                      .where((t) => t.isCompleted && !t.isDeleted)
                      .map((task) => ListTile(
                    title: Text(task.title, style: TextStyle(fontSize: 16)),
                    subtitle: Text(
                        'Concluída: ${task.completionDate != null ? task.completionDate!.toLocal().toString().split(' ')[0] : 'Não especificada'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ))
                      .toList(),
                ),
              ),
            ),
          if (tasks.where((t) => t.isDeleted).isNotEmpty)
            Card(
              elevation: 2,
              child: ListTile(
                title: Text('Tarefas Excluídas', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasks
                      .where((t) => t.isDeleted)
                      .map((task) => ListTile(
                    title: Text(task.title, style: TextStyle(fontSize: 16)),
                    subtitle: Text(
                        'Excluída: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ))
                      .toList(),
                ),
              ),
            ),
          if (tasks.where((t) => t.isCompleted || t.isDeleted).isEmpty)
            Center(
              child: Text('Nenhum histórico disponível.', style: TextStyle(color: Colors.grey[600])),
            ),
        ],
      ),
    );
  }
}