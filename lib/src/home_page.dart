import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'tip_model.dart';
import 'tip_storage.dart';
import 'tip_edit_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  bool isAlwaysOnTop = false;
  List<TipModel> tips = [];
  int currentIndex = 0;
  bool slideshowActive = false;
  int slideshowInterval = 30;
  Timer? slideshowTimer;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadTips();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    slideshowTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTips() async {
    final loaded = await TipStorage.loadTips();
    setState(() {
      tips = loaded;
      if (currentIndex >= tips.length) currentIndex = 0;
    });
  }

  void _toggleAlwaysOnTop() async {
    isAlwaysOnTop = !isAlwaysOnTop;
    await windowManager.setAlwaysOnTop(isAlwaysOnTop);
    setState(() {});
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
    slideshowTimer = Timer.periodic(Duration(seconds: slideshowInterval), (_) {
      _nextTip();
    });
    setState(() {});
  }

  void _stopSlideshow() {
    slideshowActive = false;
    slideshowTimer?.cancel();
    setState(() {});
  }

  void _nextTip() {
    if (tips.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex + 1) % tips.length;
      });
    }
  }

  void _prevTip() {
    if (tips.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex - 1 + tips.length) % tips.length;
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

  Widget _tipContent(TipModel tip) {
    final scrollableContent = SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (tip.isImage)
            Stack(
              alignment: Alignment.topRight,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: _isHovering && tip.link != null && tip.link!.trim().isNotEmpty
                        ? Border.all(color: Colors.blue.withOpacity(0.12), width: 1)
                        : null,
                  ),
                  child: Image.file(
                    tip.getFile()!,
                    fit: BoxFit.contain,
                  ),
                ),
                if (tip.link != null && tip.link!.trim().isNotEmpty && tip.content.trim().isEmpty)
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Tooltip(
                      message: 'Clique para abrir o link',
                      child: Icon(Icons.open_in_new, size: 15, color: Colors.blue.withOpacity(0.30)),
                    ),
                  ),
              ],
            ),
          if (tip.isImage && tip.content.trim().isNotEmpty)
            SizedBox(height: 16),
          if (tip.content.trim().isNotEmpty)
            MouseRegion(
              cursor: tip.link != null && tip.link!.trim().isNotEmpty
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: GestureDetector(
                onTap: tip.link != null && tip.link!.trim().isNotEmpty
                    ? () => _openUrl(tip.link!)
                    : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: _isHovering && tip.link != null && tip.link!.trim().isNotEmpty
                        ? Border.all(color: Colors.blue.withOpacity(0.13), width: 1)
                        : null,
                    color: _isHovering && tip.link != null && tip.link!.trim().isNotEmpty
                        ? Colors.blue.withOpacity(0.025)
                        : Colors.transparent,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          tip.content,
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            decoration: tip.link != null && tip.link!.trim().isNotEmpty
                                ? TextDecoration.underline
                                : null,
                            decorationColor: Colors.blue.withOpacity(0.16),
                            decorationThickness: 1,
                            shadows: tip.link != null && tip.link!.trim().isNotEmpty
                                ? [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 1.5,
                                color: Colors.blue.withOpacity(0.10),
                              ),
                            ]
                                : [],
                          ),
                        ),
                      ),
                      if (tip.link != null && tip.link!.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(left: 3, bottom: 1),
                          child: Icon(Icons.open_in_new, size: 13, color: Colors.blue.withOpacity(0.16)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (tip.link != null && tip.link!.trim().isNotEmpty && tip.showLink)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: LinkPreviewGenerator(
                key: ValueKey(tip.link),
                link: tip.link!,
                linkPreviewStyle: LinkPreviewStyle.small,
                bodyMaxLines: 2,
                showDomain: true,
                backgroundColor: Colors.green[50] ?? Colors.white,
                borderRadius: 8,
                cacheDuration: const Duration(days: 7),
              ),
            ),
        ],
      ),
    );

    if (tip.link != null && tip.link!.trim().isNotEmpty && (tip.isImage || tip.content.trim().isNotEmpty)) {
      return Tooltip(
        message: 'Clique para abrir o link',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openUrl(tip.link!),
            child: scrollableContent,
          ),
        ),
      );
    }

    return scrollableContent;
  }

  @override
  Widget build(BuildContext context) {
    final tip = tips.isNotEmpty ? tips[currentIndex] : null;
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: themeManager.themeData.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: tip == null
                ? Text('Nenhuma dica cadastrada.')
                : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              child: _tipContent(tip),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
              tooltip: 'Menu e Configurações',
              onSelected: (value) {
                switch (value) {
                  case 'toggleTop':
                    _toggleAlwaysOnTop();
                    break;
                  case 'slideshow':
                    slideshowActive ? _stopSlideshow() : _startSlideshow();
                    break;
                  case 'settings':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SettingsPage()),
                    );
                    break;
                }
                if (value.startsWith('theme_')) {
                  final selected = AppThemeType.values.firstWhere(
                        (t) => 'theme_${t.name}' == value,
                  );
                  Provider.of<ThemeManager>(context, listen: false).setTheme(selected);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggleTop',
                  child: Text(isAlwaysOnTop ? 'Desafixar Janela' : 'Fixar Janela'),
                ),
                PopupMenuItem(
                  value: 'slideshow',
                  child: Text(slideshowActive ? 'Parar Slideshow' : 'Iniciar Slideshow'),
                ),
                PopupMenuItem(
                  enabled: false,
                  child: Row(
                    children: [
                      Text('Intervalo: '),
                      SizedBox(
                        width: 40,
                        child: TextFormField(
                          initialValue: slideshowInterval.toString(),
                          keyboardType: TextInputType.number,
                          onFieldSubmitted: (v) {
                            final x = int.tryParse(v) ?? 30;
                            slideshowInterval = x;
                            setState(() {});
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Text('s'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  enabled: false,
                  child: Text('Tema'),
                ),
                ...AppThemeType.values.map((theme) => PopupMenuItem<String>(
                  value: 'theme_${theme.name}',
                  child: Text(_themeLabel(theme)),
                )),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'settings',
                  child: Text('Sobre o App'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: tips.isEmpty
          ? null
          : BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: _prevTip,
            ),
            Text('${currentIndex + 1}/${tips.length}'),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: _nextTip,
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _addOrEditTip(tip, currentIndex),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteTip(currentIndex),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeManager.themeData.floatingActionButtonTheme.backgroundColor,
        child: Icon(Icons.add),
        tooltip: 'Nova Dica',
        onPressed: () => _addOrEditTip(),
      ),
    );
  }
}