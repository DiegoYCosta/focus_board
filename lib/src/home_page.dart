import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'tip_model.dart';
import 'tip_storage.dart';
import 'tip_edit_dialog.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  bool isAlwaysOnTop = false;
  List<TipModel> tips = [];
  int currentIndex = 0;
  bool slideshowActive = false;
  int slideshowInterval = 30; // segundos
  Timer? slideshowTimer;

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

  @override
  Widget build(BuildContext context) {
    final tip = tips.isNotEmpty ? tips[currentIndex] : null;
    return Scaffold(
      appBar: AppBar(
        title: Text('Sticky Tips'),
        actions: [
          IconButton(
            icon: Icon(isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: 'Fixar Janela',
            onPressed: _toggleAlwaysOnTop,
          ),
          IconButton(
            icon: Icon(slideshowActive ? Icons.pause : Icons.play_arrow),
            tooltip: slideshowActive ? 'Parar Slideshow' : 'Iniciar Slideshow',
            onPressed: slideshowActive ? _stopSlideshow : _startSlideshow,
          ),
          PopupMenuButton(
            itemBuilder: (ctx) => [
              PopupMenuItem(
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
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    Text('s'),
                  ],
                ),
              ),
              PopupMenuItem(
                child: TextButton(
                  onPressed: () {
                    setState(() => currentIndex = 0);
                    Navigator.pop(ctx);
                  },
                  child: Text('Voltar ao Início'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: tip == null
            ? Text('Nenhuma dica cadastrada.')
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tip.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  tip.getFile()!,
                  // Remove height fixa, deixa o natural
                  fit: BoxFit.contain,
                ),
              ),
            if (tip.isImage && tip.content.trim().isNotEmpty)
              SizedBox(height: 16),
            if (tip.content.trim().isNotEmpty)
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    tip.content,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
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
        child: Icon(Icons.add),
        tooltip: 'Nova Dica',
        onPressed: () => _addOrEditTip(),
      ),
    );
  }
}
