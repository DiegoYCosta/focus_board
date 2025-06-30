// lib/src/widgets/tip_gallery_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../tip_model.dart';
import '../tip_edit_dialog.dart';
import '../tip_storage.dart';
import 'draggable_tip_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Diálogo que exibe uma galeria de dicas com grid arrastável.
class TipGalleryDialog extends StatefulWidget {
  final List<TipModel> tips;
  final Set<int> selectedIndexes;
  final void Function(int index) onEdit;
  final void Function(Set<int> newSelection) onSelectionChanged;
  final VoidCallback? onCacheCleared;

  const TipGalleryDialog({
    Key? key,
    required this.tips,
    required this.selectedIndexes,
    required this.onEdit,
    required this.onSelectionChanged,
    this.onCacheCleared,
  }) : super(key: key);

  @override
  State<TipGalleryDialog> createState() => _TipGalleryDialogState();
}

class _TipGalleryDialogState extends State<TipGalleryDialog> {
  late Set<int> localSelection;
  late final ScrollController _scrollController;
  bool cleaningCache = false;

  @override
  void initState() {
    super.initState();
    localSelection = Set.from(widget.selectedIndexes);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  //Função limpar cachê
  Future<void> _clearGalleryCache() async {
    setState(() => cleaningCache = true);
    try {
      // 1) Limpa as miniaturas da galeria
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/focus_gallery_thumbs');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      // 2) Remove prefs da pasta, exe e ícone
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('default_folder');
      await prefs.remove('default_exe');
      await prefs.remove('default_exe_icon');
      // 3) Deleta o arquivo de ícone extraído
      final appSupportDir = await getApplicationSupportDirectory();
      final iconFile = File('${appSupportDir.path}/exe_icon.ico');
      if (await iconFile.exists()) {
        await iconFile.delete();
      }
    } catch (_) {
      // silencioso em caso de erro
    }
    setState(() => cleaningCache = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache e configurações limpas!')),
      );
    }
  }

  Future<void> _addNewTip() async {
    final newTip = await showDialog<TipModel>(
      context: context,
      builder: (_) => const TipEditDialog(),
    );
    if (newTip != null) {
      setState(() {
        widget.tips.add(newTip);
        localSelection.add(widget.tips.length - 1);
        widget.onSelectionChanged(localSelection);
      });
      try {
        await TipStorage.saveTips(widget.tips);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar nova dica: \$e')),
        );
      }
      await Future.delayed(Duration.zero);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _editTip(int idx) async {
    final editedTip = await showDialog<TipModel>(
      context: context,
      builder: (_) => TipEditDialog(tip: widget.tips[idx]),
    );
    if (editedTip != null) {
      setState(() {
        widget.tips[idx] = editedTip;
      });
      await TipStorage.saveTips(widget.tips);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.tips.isEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final dialogWidth = constraints.maxWidth * 0.82;
        final dialogHeight = constraints.maxHeight * 0.65;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                // HEADER
                Row(
                  children: [
                    const Icon(Icons.collections, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 8),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _addNewTip,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Nova Dica'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // GRID ARRASTÁVEL OU PLACEHOLDER
                Expanded(
                  child: isEmpty
                      ? const Center(
                    child: Text(
                      'Nenhuma dica cadastrada.\nClique em Nova Dica para adicionar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black45),
                    ),
                  )
                  : DraggableTipGrid(
                    tips: widget.tips,
                    selectedIndexes: localSelection,
                    onSelectionChanged: (sel) {
                      setState(() {
                        localSelection = sel;
                        widget.onSelectionChanged(localSelection);
                      });
                    },
                    onEdit: _editTip,
                    scrollController: _scrollController,
                  ),
                  
                ),
                // BOTÃO LIMPAR CACHE
                Align(
                  alignment: Alignment.bottomLeft,
                  child: ElevatedButton.icon(
                    onPressed: cleaningCache ? null : () async {
                      await _clearGalleryCache();
                      widget.onCacheCleared?.call();
                    },
                    icon: const Icon(Icons.cleaning_services, size: 12),
                    label: const Text('Limpar Cache', style: TextStyle(fontSize: 8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
