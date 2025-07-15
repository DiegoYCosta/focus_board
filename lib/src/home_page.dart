// lib/src/home_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter/material.dart';
import 'package:focus_board/src/task_storage.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:provider/provider.dart';

import 'tip_model.dart';
import 'tip_storage.dart';
import 'tip_edit_dialog.dart';
import 'theme_manager.dart';
import 'settings_page.dart';
import 'widgets/empty_tips_placeholder.dart';
import 'widgets/tip_gallery_dialog.dart';
import 'widgets/snap_window_manager_button.dart';
import 'task_section.dart';
import 'task_model.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  List<TipModel> tips = [];
  int currentIndex = 0;
  bool slideshowActive = false;
  int slideshowInterval = 20;
  Timer? slideshowTimer;
  bool _isHovering = false;
  bool _showTasks = false;
  final GlobalKey<TaskSectionState> _taskSectionKey = GlobalKey<TaskSectionState>();

  Set<int> selectedIndexes = {};

  String? _savedFolderPath;
  String? _savedExePath;
  String? _savedExeIconPath;

  List<TipModel> get visibleTips {
    if (selectedIndexes.isEmpty) return tips;
    return [
      for (final idx in selectedIndexes)
        if (idx >= 0 && idx < tips.length) tips[idx]
    ];
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadTips();
    _loadSlideshowInterval();
    _loadSavedPaths();
    _initializeWindowSize();
  }

  Future<void> _initializeWindowSize() async {
    await windowManager.setMinimumSize(Size(150, 250));
    final size = await windowManager.getSize();
    if (size.height < 250) {
      await windowManager.setSize(Size(size.width, 250));
    }
  }

  Future<void> _loadSavedPaths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedFolderPath = prefs.getString('default_folder');
      _savedExePath = prefs.getString('default_exe');
      _savedExeIconPath = prefs.getString('default_exe_icon');
    });
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_folder', path);
      setState(() => _savedFolderPath = path);
    }
  }

  Future<void> _openFolderOrPick() async {
    if (_savedFolderPath != null && Directory(_savedFolderPath!).existsSync()) {
      await Process.start('explorer.exe', [_savedFolderPath!]);
    } else {
      await _pickFolder();
    }
  }

  Future<void> _openExeOrPick() async {
    if (_savedExePath != null && File(_savedExePath!).existsSync()) {
      try {
        await Process.start(_savedExePath!, []);
      } on ProcessException catch (e) {
        if (e.message.contains('requer elevação') || e.message.contains('requires elevation')) {
          await Process.start('powershell', [
            '-NoProfile',
            '-Command',
            "Start-Process '${_savedExePath!.replaceAll("'", "''")}' -Verb runAs"
          ]);
        } else {
          rethrow;
        }
      }
    } else {
      await _pickExe();
    }
  }

  Future<void> _deleteOldExeIcon() async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString('default_exe_icon');
    if (old != null) {
      final f = File(old);
      if (await f.exists()) await f.delete();
      await prefs.remove('default_exe_icon');
    }
    setState(() => _savedExeIconPath = null);
  }

  Future<void> _pickExe() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
    );
    final filePath = result?.files.single.path;
    if (filePath != null) {
      await _deleteOldExeIcon();
      final iconPath = await _extractExeIcon(filePath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_exe', filePath);
      if (iconPath != null) {
        await prefs.setString('default_exe_icon', iconPath);
        setState(() {
          _savedExePath = filePath;
          _savedExeIconPath = iconPath;
        });
      } else {
        setState(() {
          _savedExePath = filePath;
          _savedExeIconPath = null;
        });
      }
    }
  }

  Future<String?> _extractExeIcon(String exePath) async {
    final dir = await getApplicationSupportDirectory();
    final iconFile = File('${dir.path}/exe_icon.ico');
    if (await iconFile.exists()) await iconFile.delete();

    final psArgs = [
      '-NoProfile',
      '-Command',
      """
Add-Type -AssemblyName System.Drawing;
\$icon = [System.Drawing.Icon]::ExtractAssociatedIcon('${exePath.replaceAll(r"'", "''")}');
\$fs = [System.IO.File]::Open('${iconFile.path.replaceAll(r"'", "''")}', 'Create');
\$icon.Save(\$fs);
\$fs.Close();
"""
    ];

    final proc = await Process.run('powershell', psArgs);
    if (proc.exitCode == 0 && await iconFile.exists()) {
      return iconFile.path;
    } else {
      print('Erro extraindo ícone: ${proc.stderr}');
      return null;
    }
  }

  Future<void> _loadSlideshowInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('slideshowInterval');
    if (saved != null && saved > 0) {
      setState(() => slideshowInterval = saved);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    slideshowTimer?.cancel();
    super.dispose();
  }

  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    final newWidth = size.width < 150.0 ? 150.0 : size.width;
    final newHeight = size.height < 250.0 ? 250.0 : size.height;
    if (newWidth != size.width || newHeight != size.height) {
      await windowManager.setSize(Size(newWidth, newHeight));
    }
  }

  Future<void> _loadTips() async {
    final loaded = await TipStorage.loadTips();
    setState(() {
      tips = loaded;
      if (currentIndex >= tips.length) currentIndex = 0;
      if (currentIndex >= visibleTips.length) currentIndex = 0;
    });
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openTipGallery() async {
    final Set<int> initialSelection = selectedIndexes.isEmpty
        ? Set<int>.from(List.generate(tips.length, (i) => i))
        : Set<int>.from(selectedIndexes);

    await showDialog(
      context: context,
      builder: (_) => TipGalleryDialog(
        tips: tips,
        selectedIndexes: initialSelection,
        onEdit: (idx) async => await _addOrEditTip(tips[idx], idx),
        onSelectionChanged: (sel) {
          setState(() {
            selectedIndexes = sel;
            currentIndex = 0;
          });
        },
        onCacheCleared: _loadSavedPaths,
      ),
    );
    await _loadSavedPaths();
    setState(() {});
  }

  String _themeLabel(AppThemeType t) {
    switch (t) {
      case AppThemeType.light:
        return 'Light';
      case AppThemeType.dark:
        return 'Dark Mode';
      case AppThemeType.green:
        return 'Green';
      case AppThemeType.grey:
        return 'Grey';
    }
  }

  void _startSlideshow() {
    slideshowActive = true;
    slideshowTimer?.cancel();
    setState(() {
      currentIndex = 0;
    });
    slideshowTimer = Timer.periodic(Duration(seconds: slideshowInterval), (_) => _nextTip());
  }

  void _stopSlideshow() {
    slideshowActive = false;
    slideshowTimer?.cancel();
    setState(() {});
  }

  void _nextTip() {
    final list = visibleTips;
    if (list.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex + 1) % list.length;
      });
    }
  }

  void _prevTip() {
    final list = visibleTips;
    if (list.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex - 1 + list.length) % list.length;
      });
    }
  }

  Future<void> _addOrEditTip([TipModel? tip, int? editIdx]) async {
    final result = await showDialog<TipModel>(
      context: context,
      builder: (_) => TipEditDialog(tip: tip),
    );
    if (result != null) {
      if (editIdx != null) {
        tips[editIdx] = result;
      } else {
        tips.add(result);
      }
      await TipStorage.saveTips(tips);
      setState(() {});
    }
  }

  Future<void> _deleteTip(int idx) async {
    tips.removeAt(idx);
    await TipStorage.saveTips(tips);
    if (currentIndex >= tips.length) currentIndex = 0;
    setState(() {});
  }

  Widget _buildTipContent(TipModel tip) {
    final file = tip.getFile();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: 200.0, // Limite a altura da imagem
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (tip.hasImage && file != null)
                  ? Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200.0, // Altura fixa
              )
                  : Image.asset(
                'assets/Athenas_Smile.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200.0, // Altura fixa
              ),
            ),
          ),
        ),
        if (tip.content.isNotEmpty) SizedBox(height: 16),
        if (tip.content.isNotEmpty)
          MouseRegion(
            cursor: tip.link != null && tip.link!.isNotEmpty
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTap: tip.link != null && tip.link!.isNotEmpty
                  ? () => _openUrl(tip.link!)
                  : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: _isHovering && tip.link != null && tip.link!.isNotEmpty
                      ? Border.all(color: Colors.blue.withOpacity(0.13), width: 1)
                      : null,
                  color: _isHovering && tip.link != null && tip.link!.isNotEmpty
                      ? Colors.blue.withOpacity(0.025)
                      : Colors.transparent,
                ),
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        tip.content,
                        style: TextStyle(
                          fontSize: 18,
                          decoration: tip.link != null && tip.link!.isNotEmpty
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                    if (tip.link != null && tip.link!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.open_in_new, size: 13),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (tip.link != null && tip.link!.isNotEmpty && tip.showLink)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: LinkPreviewGenerator(
              link: tip.link!,
              linkPreviewStyle: LinkPreviewStyle.small,
              bodyMaxLines: 2,
              showDomain: true,
              backgroundColor: Colors.green[50]!,
              borderRadius: 8,
              cacheDuration: Duration(days: 90),
            ),
          ),
      ],
    );
  }

  Future<void> _adjustWindowHeight(bool showTasks) async {
    final currentSize = await windowManager.getSize();
    final newHeight = showTasks ? currentSize.height + 300.0 : currentSize.height - 300.0;
    await windowManager.setSize(Size(currentSize.width, newHeight.clamp(250.0, double.infinity)));
    setState(() {
      _showTasks = showTasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tipList = visibleTips;
    final tip = tipList.isNotEmpty && currentIndex < tipList.length
        ? tipList[currentIndex]
        : null;
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: tip == null
                      ? EmptyTipsPlaceholder()
                      : Container(
                    padding: EdgeInsets.all(12),
                    child: _buildTipContent(tip),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).viewPadding.top + 8,
                  right: MediaQuery.of(context).viewPadding.right + 8,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    left: false,
                    right: false,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: slideshowActive ? 'Parar Slideshow' : 'Iniciar Slideshow',
                            child: IconButton(
                              icon: Icon(
                                slideshowActive ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: slideshowActive ? _stopSlideshow : _startSlideshow,
                              splashRadius: 20,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tight(Size(36, 36)),
                            ),
                          ),
                          SnapWindowManagerButton(),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.menu, color: Colors.white),
                            tooltip: 'Menu e Configurações',
                            onSelected: (value) {
                              if (value == 'settings') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => SettingsPage()),
                                );
                              } else if (value.startsWith('theme_')) {
                                final selected = AppThemeType.values.firstWhere(
                                        (t) => 'theme_${t.name}' == value);
                                Provider.of<ThemeManager>(context, listen: false)
                                    .setTheme(selected);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                enabled: false,
                                child: Row(
                                  children: [
                                    Text('Intervalo:'),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 40,
                                      child: TextFormField(
                                        initialValue: slideshowInterval.toString(),
                                        keyboardType: TextInputType.number,
                                        onFieldSubmitted: (v) async {
                                          final newInterval =
                                              int.tryParse(v) ?? slideshowInterval;
                                          final prefs =
                                          await SharedPreferences.getInstance();
                                          await prefs.setInt(
                                              'slideshowInterval', newInterval);
                                          setState(() {
                                            slideshowInterval = newInterval;
                                            if (slideshowActive) {
                                              slideshowTimer?.cancel();
                                              slideshowTimer = Timer.periodic(
                                                Duration(seconds: slideshowInterval),
                                                    (_) => _nextTip(),
                                              );
                                            }
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                    Text('s'),
                                  ],
                                ),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(enabled: false, child: Text('Tema')),
                              ...AppThemeType.values.map((t) => PopupMenuItem<String>(
                                value: 'theme_${t.name}',
                                child: Text(_themeLabel(t)),
                              )),
                              PopupMenuDivider(),
                              PopupMenuItem(value: 'settings', child: Text('Sobre o App')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showTasks) TaskSection(key: _taskSectionKey),
        ],
      ),
      floatingActionButton: _showTasks
          ? Semantics(
        label: 'Adicionar nova tarefa',
        child: FloatingActionButton(
          onPressed: () {
            if (_taskSectionKey.currentState != null) {
              _taskSectionKey.currentState!.addOrEditTask();
            } else {
              print('TaskSection state is null');
            }
          },
          tooltip: 'Adicionar Tarefa',
          child: Icon(Icons.add),
          backgroundColor: Colors.blue[700],
        ),
      )
          : null,
      bottomNavigationBar: tipList.isEmpty
          ? null
          : SizedBox(
        height: kToolbarHeight,
        child: BottomAppBar(
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(Icons.filter_list, size: 14, color: Colors.grey[600]),
                      onPressed: () async {
                        await _adjustWindowHeight(!_showTasks);
                      },
                      tooltip: 'Mostrar/Ocultar Tarefas',
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tight(Size(36, 36)),
                    ),
                    IconButton(
                      icon: Icon(Icons.folder),
                      tooltip: _savedFolderPath ?? 'Selecionar Pasta',
                      onPressed: _openFolderOrPick,
                      onLongPress: _pickFolder,
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tight(Size(36, 36)),
                    ),
                    IconButton(
                      icon: _savedExeIconPath != null &&
                          File(_savedExeIconPath!).existsSync()
                          ? ImageIcon(
                        FileImage(File(_savedExeIconPath!)),
                        size: 14,
                      )
                          : Icon(Icons.apps, size: 14),
                      tooltip: _savedExePath ?? 'Selecionar Aplicativo',
                      onPressed: _openExeOrPick,
                      onLongPress: _pickExe,
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tight(Size(16, 16)),
                    ),
                    IconButton(
                      icon: Icon(Icons.grid_view, size: 14, color: Colors.grey[600]),
                      onPressed: _openTipGallery,
                      tooltip: 'Galeria',
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tight(Size(36, 36)),
                    ),
                    IconButton(
                      icon: Icon(Icons.history, size: 14, color: Colors.grey[600]),
                      onPressed: () {
                        // Implementar diálogo ou navegação para tarefas concluídas/destruídas
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Tarefas Concluídas/Destruídas'),
                            content: FutureBuilder<List<TaskModel>>(
                              future: TaskStorage.loadTasks(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return CircularProgressIndicator();
                                final completedTasks = snapshot.data!
                                    .where((t) => t.isCompleted || t.isDeleted)
                                    .toList();
                                if (completedTasks.isEmpty) {
                                  return Text('Nenhuma tarefa concluída.');
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: completedTasks.length,
                                  itemBuilder: (context, index) {
                                    final task = completedTasks[index];
                                    return ListTile(
                                      title: Text(task.title),
                                      subtitle: task.isCompleted
                                          ? Text('Concluída em: ${DateFormat('dd/MM/yyyy HH:mm').format(task.completionDate!)}')
                                          : Text('Destruída'),
                                    );
                                  },
                                );
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Fechar'),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Ver Histórico de Tarefas',
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tight(Size(36, 36)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, size: 14),
                      onPressed: _prevTip,
                      tooltip: 'Anterior',
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tight(Size(25, 14)),
                    ),
                    Text(
                      '${tipList.isEmpty ? 0 : currentIndex + 1}/${tipList.length}',
                      style: TextStyle(fontSize: 14),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward, size: 14),
                      onPressed: _nextTip,
                      tooltip: 'Próxima',
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tight(Size(25, 14)),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 14),
                      tooltip: 'Abrir Opções',
                      onSelected: (value) async {
                        if (value == 'add') {
                          await _addOrEditTip();
                        } else if (value == 'edit') {
                          if (tip != null) {
                            await _addOrEditTip(tip, currentIndex);
                          }
                        } else if (value == 'delete') {
                          if (tip != null) {
                            await _deleteTip(currentIndex);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'add',
                          child: Text('Adicionar Dica'),
                        ),
                        if (tip != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar Dica'),
                          ),
                        if (tip != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir Dica'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}