import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../tip_model.dart';
import '../tip_edit_dialog.dart';
import '../tip_storage.dart';


class TipGalleryDialog extends StatefulWidget {
  final List<TipModel> tips;
  final Set<int> selectedIndexes;
  final void Function(int index) onEdit;
  final void Function(Set<int> newSelection) onSelectionChanged;

  const TipGalleryDialog({
    super.key,
    required this.tips,
    required this.selectedIndexes,
    required this.onEdit,
    required this.onSelectionChanged,
  });

  @override
  State<TipGalleryDialog> createState() => _TipGalleryDialogState();
}

class _TipGalleryDialogState extends State<TipGalleryDialog> {
  late Set<int> localSelection;
  late final ScrollController _scrollController;
  bool cleaningCache = false;

  // ---- Defina a altura da barra de botões do rodapé dos cards ----
  static const double bottomBarHeight = 36.0; // Pode ajustar!

  @override
  void initState() {
    super.initState();
    localSelection = Set.from(widget.selectedIndexes);
    _scrollController = ScrollController();
  }

  Future<void> _clearGalleryCache() async {
    setState(() => cleaningCache = true);
    try {
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/focus_gallery_thumbs');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {}
    setState(() => cleaningCache = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cache limpo!")),
      );
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _miniPreview(TipModel tip) {
    const double thumbSize = 50.0;
    if (tip.isImage && tip.imagePath != null && File(tip.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.file(
          File(tip.imagePath!),
          width: thumbSize,
          height: thumbSize,
          fit: BoxFit.cover,
          cacheWidth:  (thumbSize * 1.28).toInt(),
          cacheHeight: (thumbSize * 1.28).toInt(),
          errorBuilder: (context, error, stack) =>
              Icon(Icons.broken_image, size: thumbSize, color: Colors.grey),
        ),
      );
    } else {
      String txt = tip.content.trim().isEmpty
          ? "(Sem texto)"
          : tip.content.length > 28
          ? tip.content.substring(0, 28) + "..."
          : tip.content;
      return Container(
        width: thumbSize,
        height: thumbSize,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          txt,
          style: TextStyle(fontSize: 12, color: Colors.black54),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }

  Future<void> _addNewTip() async {
    final TipModel? newTip = await showDialog<TipModel>(
      context: context,
      builder: (ctx) => TipEditDialog(),
    );
    if (newTip != null) {
      setState(() {
        widget.tips.add(newTip);
        final newIndex = widget.tips.length - 1;
        localSelection.add(newIndex);
        widget.onSelectionChanged(localSelection);
      });
      await Future.delayed(Duration(milliseconds: 50));
      _scrollToEnd();
    }
  }

  Future<void> _editTip(int index) async {
    final wasSelected = localSelection.contains(index);
    final TipModel? editedTip = await showDialog<TipModel>(
      context: context,
      builder: (ctx) => TipEditDialog(tip: widget.tips[index]),
    );
    if (editedTip != null) {
      setState(() {
        widget.tips[index] = editedTip;
        if (wasSelected) {
          localSelection.add(index);
        } else {
          localSelection.remove(index);
        }
        widget.onSelectionChanged(localSelection);
      });
    }
  }

  Future<void> _deleteTip(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja apagar esta dica? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        widget.tips.removeAt(index);
        localSelection.remove(index);
        localSelection = localSelection
            .map((i) => i > index ? i - 1 : i)
            .where((i) => i < widget.tips.length)
            .toSet();
        widget.onSelectionChanged(localSelection);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.tips.isEmpty;
    final minCardWidth = 80.0;
    final maxCardWidth = 120.0;
    final minCardHeight = 80.0;
    final maxCardHeight = 135.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Usa quase toda a tela, exceto pequenas margens
        final double dialogWidth = constraints.maxWidth * 0.82;
        final double dialogHeight = constraints.maxHeight * 0.65;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header
            Row(
            children: [
            Icon(Icons.collections, color: Colors.deepPurple, size: 20),
            SizedBox(width: 8),
            Spacer(), // empurra o botão para a borda direita
            ElevatedButton.icon(
              onPressed: _addNewTip,
              icon: Icon(Icons.add, size: 14),
              label: Text("Nova Dica"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 4,
                shadowColor: Colors.deepPurple.withOpacity(0.1),
              ),
            ),
            SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, size: 14),
                color: Colors.grey.shade600,
                splashRadius: 20,
                padding: EdgeInsets.all(3),
                constraints: BoxConstraints.tight(Size(20, 20)),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200.withOpacity(0.2),
                  shape: CircleBorder(),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: 'Fechar',
              ),
            ],

                ),
                SizedBox(height: 10),
                // Galeria/grid
                Expanded(
                  child: isEmpty
                      ? Center(
                    child: Text(
                      "Nenhuma dica cadastrada.\nClique em Nova Dica para adicionar!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black45),
                    ),
                  )
                      : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(4),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxCardWidth,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 10,
                      mainAxisExtent: maxCardHeight,     // altura fixa
                      //childAspectRatio: 0.75,
                    ),
                    itemCount: widget.tips.length,
                    itemBuilder: (context, index) {
                      final tip = widget.tips[index];
                      final isSelected = localSelection.contains(index);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              localSelection.remove(index);
                            } else {
                              localSelection.add(index);
                            }
                            widget.onSelectionChanged(localSelection);
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepPurple[50] : Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: isSelected ? 7 : 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(7),
                          child: Stack(
                            children: [
                              // Conteúdo principal limitado ao espaço do card
                              Positioned.fill(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: bottomBarHeight),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _miniPreview(tip),
                                      SizedBox(height: 7),
                                      if (tip.isImage && tip.content.trim().isNotEmpty)
                                        Text(
                                          tip.content.length > 22
                                              ? tip.content.substring(0, 22) + "..."
                                              : tip.content,
                                          style: TextStyle(fontSize: 8, color: Colors.black54),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Checkbox de seleção
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        localSelection.add(index);
                                      } else {
                                        localSelection.remove(index);
                                      }
                                      widget.onSelectionChanged(localSelection);
                                    });
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              // Botão editar (superior direito)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: Icon(Icons.edit, size: 18, color: Colors.black45),
                                  tooltip: "Editar",
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  onPressed: () => _editTip(index),
                                ),
                              ),
                              // Botão excluir (inferior esquerdo)
                              Positioned(
                                left: 2,
                                bottom: 2,
                                child: IconButton(
                                  icon: Icon(Icons.delete, size: 16, color: Colors.red[400]),
                                  tooltip: "Excluir",
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _deleteTip(index),
                                ),
                              ),
                              // Botão duplicar (inferior direito)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: IconButton(
                                  icon: Icon(Icons.copy, size: 16, color: Colors.deepPurple[400]),
                                  tooltip: 'Duplicar',
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    setState(() {
                                      final cloned = tip.copyWith();
                                      widget.tips.add(cloned);
                                      final newIndex = widget.tips.length - 1;
                                      localSelection.add(newIndex);
                                      widget.onSelectionChanged(localSelection);
                                    });
                                    // salva imediatamente no arquivo
                                    await TipStorage.saveTips(widget.tips);
                                    // scroll suave até o final
                                    await Future.delayed(Duration(milliseconds: 50));
                                    _scrollToEnd();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Limpar cache
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Opacity(
                    opacity: 0.7,
                    child: ElevatedButton.icon(
                      onPressed: cleaningCache ? null : _clearGalleryCache,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                        backgroundColor: cleaningCache ? Colors.grey : Colors.red[200],
                        foregroundColor: Colors.white,
                        minimumSize: Size(0, 32),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      icon: Icon(Icons.cleaning_services, size: 12),
                      label: Text("Limpar Cache", style: TextStyle(fontSize: 8)),
                    ),
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
