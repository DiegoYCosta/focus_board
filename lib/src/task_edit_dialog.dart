// lib/src/task_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'package:uuid/uuid.dart';

class TaskEditDialog extends StatefulWidget {
  final TaskModel? task;
  final bool isNew; // Flag para diferenciar criação de edição

  const TaskEditDialog({Key? key, this.task, this.isNew = false}) : super(key: key);

  @override
  _TaskEditDialogState createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _titleController = TextEditingController();
  String _priority = 'normal'; // Gerencia prioridade (normal, importante, urgente)
  DateTime? _dueDate;
  bool _hasAlarm = false;
  DateTime? _alarmTime;
  bool _hasTimer = false;
  Duration? _timerDuration;
  bool _showAdvanced = false; // Controla visibilidade das opções avançadas

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _priority = widget.task!.isUrgent
          ? 'urgent'
          : widget.task!.isImportant
          ? 'important'
          : 'normal';
      _dueDate = widget.task!.dueDate;
      _hasAlarm = widget.task!.hasAlarm;
      _alarmTime = widget.task!.alarmTime;
      _hasTimer = widget.task!.hasTimer;
      _timerDuration = widget.task!.timerDuration;
      _showAdvanced = widget.task!.dueDate != null || widget.task!.hasAlarm || widget.task!.hasTimer;
    }
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
      title: Text(
        widget.isNew ? 'Nova Tarefa' : 'Editar Tarefa',
        style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título (opcional)',
                hintText: 'Digite o título da tarefa',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            SizedBox(height: 12),
            Text('Prioridade', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
            DropdownButton<String>(
              value: _priority,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'normal', child: Text('Normal', style: TextStyle(fontFamily: 'Roboto'))),
                DropdownMenuItem(value: 'important', child: Text('Importante', style: TextStyle(fontFamily: 'Roboto'))),
                DropdownMenuItem(value: 'urgent', child: Text('Urgente', style: TextStyle(fontFamily: 'Roboto'))),
              ],
              onChanged: (value) => setState(() => _priority = value!),
              style: TextStyle(fontFamily: 'Roboto', color: Colors.black),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            if (!widget.isNew || _showAdvanced) ...[
              SizedBox(height: 12),
              ListTile(
                title: Text(
                  'Vencimento: ${_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Não definida'}',
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
                trailing: Icon(Icons.calendar_today_rounded, color: Colors.teal[600], size: 18),
                onTap: _selectDate,
                subtitle: Text(
                  'Toque para selecionar a data',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Roboto'),
                ),
              ),
              SwitchListTile(
                title: Text('Alarme', style: TextStyle(fontFamily: 'Roboto')),
                value: _hasAlarm,
                onChanged: (value) => setState(() => _hasAlarm = value),
                secondary: Icon(Icons.alarm_rounded, color: Colors.blue[600], size: 18),
                subtitle: Text(
                  'Ativar alarme para notificação',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Roboto'),
                ),
              ),
              if (_hasAlarm)
                ListTile(
                  title: Text(
                    'Hora: ${_alarmTime != null ? DateFormat('HH:mm').format(_alarmTime!) : 'Não definida'}',
                    style: TextStyle(fontFamily: 'Roboto'),
                  ),
                  trailing: Icon(Icons.access_time_rounded, color: Colors.blue[600], size: 18),
                  onTap: _selectAlarmTime,
                  subtitle: Text(
                    'Toque para definir o horário',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Roboto'),
                  ),
                ),
              SwitchListTile(
                title: Text('Temporizador', style: TextStyle(fontFamily: 'Roboto')),
                value: _hasTimer,
                onChanged: (value) => setState(() => _hasTimer = value),
                secondary: Icon(Icons.timer_rounded, color: Colors.orange[600], size: 18),
                subtitle: Text(
                  'Ativar temporizador para contagem',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Roboto'),
                ),
              ),
              if (_hasTimer)
                ListTile(
                  title: Text(
                    'Duração: ${_timerDuration != null ? '${_timerDuration!.inMinutes} min' : 'Não definida'}',
                    style: TextStyle(fontFamily: 'Roboto'),
                  ),
                  trailing: Icon(Icons.schedule_rounded, color: Colors.orange[600], size: 18),
                  onTap: _selectTimerDuration,
                  subtitle: Text(
                    'Toque para definir a duração',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Roboto'),
                  ),
                ),
            ],
            if (widget.isNew)
              TextButton(
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Text(
                  _showAdvanced ? 'Ocultar Configurações Avançadas' : 'Mostrar Configurações Avançadas',
                  style: TextStyle(color: Colors.blue[600], fontFamily: 'Roboto'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600], fontFamily: 'Roboto')),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Salvar', style: TextStyle(color: Colors.white, fontFamily: 'Roboto')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final task = TaskModel(
              id: widget.task?.id ?? const Uuid().v4(),
              title: _titleController.text.isEmpty ? 'Tarefa sem título' : _titleController.text,
              isUrgent: _priority == 'urgent',
              isImportant: _priority == 'important',
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