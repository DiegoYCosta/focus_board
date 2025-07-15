import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'package:uuid/uuid.dart';

class TaskEditDialog extends StatefulWidget {
  final TaskModel? task;

  const TaskEditDialog({Key? key, this.task}) : super(key: key);

  @override
  _TaskEditDialogState createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _titleController = TextEditingController();
  bool _isUrgent = false;
  bool _isImportant = false;
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
      _isUrgent = widget.task!.isUrgent;
      _isImportant = widget.task!.isImportant;
      _dueDate = widget.task!.dueDate;
      _hasAlarm = widget.task!.hasAlarm;
      _alarmTime = widget.task!.alarmTime;
      _hasTimer = widget.task!.hasTimer;
      _timerDuration = widget.task!.timerDuration;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _selectAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime != null
          ? TimeOfDay.fromDateTime(_alarmTime!)
          : TimeOfDay.now(),
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
        title: Text('Duração do Temporizador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Minutos'),
              onChanged: (value) {
                final minutes = int.tryParse(value) ?? 0;
                _timerDuration = Duration(minutes: minutes);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Salvar'),
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
      title: Text(widget.task == null ? 'Nova Tarefa' : 'Editar Tarefa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Título'),
            ),
            Row(
              children: [
                Checkbox(
                  value: _isUrgent,
                  onChanged: (value) => setState(() => _isUrgent = value ?? false),
                ),
                Text('Urgente'),
                SizedBox(width: 16),
                Checkbox(
                  value: _isImportant,
                  onChanged: (value) => setState(() => _isImportant = value ?? false),
                ),
                Text('Importante'),
              ],
            ),
            ListTile(
              title: Text('Vencimento: ${_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Não definida'}'),
              trailing: Icon(Icons.calendar_today, color: Colors.blue[700]),
              onTap: _selectDate,
            ),
            SwitchListTile(
              title: Text('Alarme'),
              value: _hasAlarm,
              onChanged: (value) => setState(() => _hasAlarm = value),
              secondary: Icon(Icons.alarm, color: Colors.blue[700]),
            ),
            if (_hasAlarm)
              ListTile(
                title: Text('Hora: ${_alarmTime != null ? DateFormat('HH:mm').format(_alarmTime!) : 'Não definida'}'),
                trailing: Icon(Icons.access_time, color: Colors.blue[700]),
                onTap: _selectAlarmTime,
              ),
            SwitchListTile(
              title: Text('Temporizador'),
              value: _hasTimer,
              onChanged: (value) => setState(() => _hasTimer = value),
              secondary: Icon(Icons.timer, color: Colors.orange[700]),
            ),
            if (_hasTimer)
              ListTile(
                title: Text('Duração: ${_timerDuration != null ? '${_timerDuration!.inMinutes} min' : 'Não definida'}'),
                trailing: Icon(Icons.schedule, color: Colors.orange[700]),
                onTap: _selectTimerDuration,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Salvar', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
          onPressed: () {
            final task = TaskModel(
              id: widget.task?.id ?? const Uuid().v4(),
              title: _titleController.text,
              isUrgent: _isUrgent,
              isImportant: _isImportant,
              dueDate: _dueDate,
              hasAlarm: _hasAlarm,
              alarmTime: _alarmTime,
              hasTimer: _hasTimer,
              timerDuration: _timerDuration,
            );
            Navigator.pop(context, task);
          },
        ),
      ],
    );
  }
}