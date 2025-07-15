// lib/src/widgets/draggable_tip_grid.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../tip_model.dart';
import '../tip_storage.dart';

/// Grid arrastável de dicas, com suporte a DragTarget e Draggable/LongPressDraggable
class DraggableTipGrid extends StatefulWidget {
  final List<TipModel> tips;
  final Set<int> selectedIndexes;
  final ValueChanged<Set<int>> onSelectionChanged;
  final ValueChanged<int> onEdit;
  final ScrollController scrollController;

  const DraggableTipGrid({
    Key? key,
    required this.tips,
    required this.selectedIndexes,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<DraggableTipGrid> createState() => _DraggableTipGridState();
}

class _DraggableTipGridState extends State<DraggableTipGrid> {
  late Set<int> localSelection;
  static const double bottomBarHeight = 36.0;

  @override
  void initState() {
    super.initState();
    localSelection = Set.from(widget.selectedIndexes);
  }

  @override
  void didUpdateWidget(covariant DraggableTipGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndexes != widget.selectedIndexes) {
      localSelection = Set.from(widget.selectedIndexes);
    }
  }

  Future<void> _scrollToEnd() async {
    await Future.delayed(Duration.zero);
    if (widget.scrollController.hasClients) {
      await widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.tips.length;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (count < 2) {
      return GridView.count(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(4),
        crossAxisCount: count,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        children: List.generate(count, (i) {
          final tip = widget.tips[i];
          final sel = localSelection.contains(i);
          return _buildCard(context, tip, i, sel);
        }),
      );
    }

    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120.0,
        mainAxisSpacing: 5,
        crossAxisSpacing: 10,
        mainAxisExtent: 135.0,
      ),
      itemCount: count,
      itemBuilder: (context, i) {
        final tip = widget.tips[i];
        final sel = localSelection.contains(i);
        return DragTarget<int>(
          onWillAccept: (from) => from != i,
          onAccept: (from) async {
            setState(() {
              final moved = widget.tips.removeAt(from);
              widget.tips.insert(i, moved);
              localSelection = localSelection.map((j) {
                if (j == from) return i;
                if (from < i && j > from && j <= i) return j - 1;
                if (i < from && j >= i && j < from) return j + 1;
                return j;
              }).toSet();
            });
            widget.onSelectionChanged(localSelection);
            try {
              await TipStorage.saveTips(widget.tips);
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao salvar ordem: \$e')),
              );
            }
          },
          builder: (ctx, candidate, rejected) {
            final highlight = candidate.isNotEmpty;
            Widget draggableChild = _buildCard(ctx, tip, i, sel);
            Widget dragWidget;
            if (isMobile) {
              dragWidget = LongPressDraggable<int>(
                data: i,
                feedback: Material(
                  elevation: 6,
                  child: SizedBox(width: 120, height: 135, child: draggableChild),
                ),
                childWhenDragging: Container(),
                child: draggableChild,
              );
            } else {
              dragWidget = Draggable<int>(
                data: i,
                feedback: Material(
                  elevation: 6,
                  child: SizedBox(width: 120, height: 135, child: draggableChild),
                ),
                childWhenDragging: Container(),
                child: draggableChild,
              );
            }
            // Destaque visual do alvo
            return Container(
              decoration: highlight
                  ? BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(13),
              )
                  : null,
              child: dragWidget,
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
      BuildContext context, TipModel tip, int idx, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple[50] : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(7),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: bottomBarHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _miniPreview(tip),
                  const SizedBox(height: 6),
                  if (tip.content.isNotEmpty)
                    Text(
                      tip.content,
                      style: const TextStyle(fontSize: 8, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Checkbox(
              value: isSelected,
              onChanged: (sel) {
                setState(() {
                  if (sel == true) localSelection.add(idx);
                  else localSelection.remove(idx);
                  widget.onSelectionChanged(localSelection);
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          // Botões de ação delegando edição
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.black45),
              tooltip: 'Editar',
              onPressed: () => widget.onEdit(idx),
            ),
          ),
          Positioned(
            left: 2,
            bottom: 2,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              tooltip: 'Excluir',
              onPressed: () async {
                setState(() {
                  widget.tips.removeAt(idx);
                  localSelection.remove(idx);
                  localSelection = localSelection
                      .map((j) => j > idx ? j - 1 : j)
                      .where((j) => j < widget.tips.length)
                      .toSet();
                  widget.onSelectionChanged(localSelection);
                });
                try {
                  await TipStorage.saveTips(widget.tips);
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: \$e')),
                  );
                }
              },
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: IconButton(
              icon: const Icon(Icons.copy, size: 16, color: Colors.deepPurple),
              tooltip: 'Duplicar',
              onPressed: () async {
                setState(() {
                  widget.tips.add(tip.copyWith());
                  localSelection.add(widget.tips.length - 1);
                  widget.onSelectionChanged(localSelection);
                });
                try {
                  await TipStorage.saveTips(widget.tips);
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao duplicar: \$e')),
                  );
                }
                _scrollToEnd();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPreview(TipModel tip) {
    const thumbSize = 50.0;
    if (tip.isImage && tip.imagePath != null && File(tip.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.file(
          File(tip.imagePath!),
          width: thumbSize,
          height: thumbSize,
          fit: BoxFit.cover,
          cacheWidth: (thumbSize * 1.28).toInt(),
          cacheHeight: (thumbSize * 1.28).toInt(),
          errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image, size: thumbSize, color: Colors.grey),
        ),
      );
    }
    final txt = tip.content.trim().isEmpty
        ? '(Sem texto)'
        : tip.content.length > 28
        ? tip.content.substring(0, 28) + '...'
        : tip.content;
    return Container(
      width: thumbSize,
      height: thumbSize,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(9)),
      alignment: Alignment.center,
      child: Text(
        txt,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
