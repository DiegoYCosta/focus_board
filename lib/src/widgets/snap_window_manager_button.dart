import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

enum WindowMode {
  normal,
  alwaysOnTop,
  }

class SnapWindowManagerButton extends StatefulWidget {
  final double snapWidth;
  final double snapHeight;
  final double? customSnapYOffset;

  const SnapWindowManagerButton({
    Key? key,
    this.snapWidth = 350,
    this.snapHeight = 450,
    this.customSnapYOffset, // Use para ajustar offset da taskbar, se quiser
  }) : super(key: key);

  @override
  State<SnapWindowManagerButton> createState() => _SnapWindowManagerButtonState();
}

class _SnapWindowManagerButtonState extends State<SnapWindowManagerButton> {
  WindowMode _mode = WindowMode.normal;

  Future<void> _toggleMode() async {
    WindowMode nextMode;
    switch (_mode) {
      case WindowMode.normal:
        nextMode = WindowMode.alwaysOnTop;
        await windowManager.setAlwaysOnTop(true);
        break;
      case WindowMode.alwaysOnTop:
        nextMode = WindowMode.normal;
        await windowManager.setAlwaysOnTop(false);
        break;
    }
    setState(() {
      _mode = nextMode;
    });
  }

  Future<void> _snapWindow() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final screenWidth = display.size.width;
    final screenHeight = display.size.height;

    final x = (screenWidth - widget.snapWidth).clamp(0, screenWidth).toDouble();
    final taskbarOffset = widget.customSnapYOffset ?? 40;
    final y = (screenHeight - widget.snapHeight - taskbarOffset)
        .clamp(0, screenHeight)
        .toDouble();

    await windowManager.setSize(Size(
      widget.snapWidth.toDouble(),
      widget.snapHeight.toDouble(),
    ));
    await windowManager.setPosition(Offset(x, y));
    await windowManager.focus();
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String tooltip;
    Color? color;

    switch (_mode) {
      case WindowMode.normal:
        icon = Icons.push_pin_outlined;
        tooltip = 'Modo normal (Clique para fixar no topo)';
        color = Colors.white;
        break;
      case WindowMode.alwaysOnTop:
        icon = Icons.push_pin;
        tooltip = 'Fixado no topo (Clique para desfazer)';
        color = Colors.orange;
        break;
    }

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: _toggleMode,
        splashRadius: 20,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tight(Size(36, 36)),
      ),
    );
  }
}
