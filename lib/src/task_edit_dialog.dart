// lib/src/task_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'package:uuid/uuid.dart';

class TaskEditDialog extends StatefulWidget {
  final TaskModel? task;
  final bool isNew;

  const TaskEditDialog({Key? key, this.task, this.isNew = false}) : super(key: key);

  @override
  _TaskEditDialogState createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _titleController = TextEditingController();
  int _priorityLevel = 0;  // 0: normal, 1: important, 2: urgent (ciclo)
  DateTime? _dueDate;
  bool _hasAlarm = false;
  DateTime? _alarmTime;
  bool _hasTimer = false;
  Duration? _timerDuration;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _priorityLevel = widget.task!.isUrgent ? 2 : widget.task!.isImportant ? 1 : 0;
      _dueDate = widget.task!.dueDate;
      _hasAlarm = widget.task!.hasAlarm;
      _alarmTime = widget.task!.alarmTime;
      _hasTimer = widget.task!.hasTimer;
      _timerDuration = widget.task!.timerDuration;
    }
  }

  void _cyclePriority() {
    setState(() => _priorityLevel = (_priorityLevel + 1) % 3);
  }

  IconData _getPriorityIcon() {
    return _priorityLevel == 2 ? Icons.warning_rounded : _priorityLevel == 1 ? Icons.priority_high_rounded : Icons.circle_outlined;
  }

  Color _getPriorityColor() {
    return _priorityLevel == 2 ? Colors.red[600]! : _priorityLevel == 1 ? Colors.yellow[800]! : Colors.grey[600]!;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: Colors.teal[600]!),
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontFamily: 'Roboto'),
            bodyMedium: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _selectAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime != null
          ? TimeOfDay.fromDateTime(_alarmTime!)
          : TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: Colors.blue[600]!),
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontFamily: 'Roboto'),
            bodyMedium: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _alarmTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        picked.hour,
        picked.minute,
      ));
    }
  }

  Future<void> _selectTimerDuration() async {
    final duration = await showDialog<Duration>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Duração do Temporizador', style: TextStyle(fontFamily: 'Roboto')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minutos',
                hintText: 'Ex.: 25',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(fontFamily: 'Roboto'),
              onChanged: (value) {
                final minutes = int.tryParse(value) ?? 0;
                _timerDuration = Duration(minutes: minutes);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600], fontFamily: 'Roboto')),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Salvar', style: TextStyle(color: Colors.white, fontFamily: 'Roboto')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, _timerDuration),
          ),
        ],
      ),
    );
    if (duration != null) setState(() => _timerDuration = duration);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Expanded(child: Text(widget.isNew ? 'Nova Tarefa' : 'Editar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          IconButton(
            icon: Icon(_getPriorityIcon(), color: _getPriorityColor(), size: 18),  // Ícone pequeno togglable
            onPressed: _cyclePriority,
            tooltip: 'Alternar Prioridade',
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(hintText: 'Tarefa...', border: InputBorder.none),
            autofocus: true,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.calendar_today, size: 18, color: _dueDate != null ? Colors.teal[600] : Colors.grey),
                onPressed: _selectDate,
                tooltip: 'Data de Vencimento',
              ),
              IconButton(
                icon: Icon(Icons.alarm, size: 18, color: _hasAlarm ? Colors.blue[600] : Colors.grey),
                onPressed: () => setState(() => _hasAlarm = !_hasAlarm),  // Toggle simples
                tooltip: 'Alarme',
              ),
              if (_hasAlarm) IconButton(icon: Icon(Icons.access_time, size: 18), onPressed: _selectAlarmTime),
              IconButton(
                icon: Icon(Icons.timer, size: 18, color: _hasTimer ? Colors.orange[600] : Colors.grey),
                onPressed: () => setState(() => _hasTimer = !_hasTimer),
                tooltip: 'Temporizador',
              ),
              if (_hasTimer) IconButton(icon: Icon(Icons.schedule, size: 18), onPressed: _selectTimerDuration),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final task = TaskModel(
              id: widget.task?.id ?? const Uuid().v4(),
              title: _titleController.text.isEmpty ? 'Sem título' : _titleController.text,
              isUrgent: _priorityLevel == 2,
              isImportant: _priorityLevel == 1,
              dueDate: _dueDate,
              hasAlarm: _hasAlarm,
              alarmTime: _alarmTime,
              hasTimer: _hasTimer,
              timerDuration: _timerDuration,
            );
            Navigator.pop(context, task);
          },
          child: Text('Salvar'),
        ),
      ],
    );
  }
}