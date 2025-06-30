import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

enum WindowMode {
  normal,
  alwaysOnTop,
  snapToDesktop,
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
    // Sequência: normal -> alwaysOnTop -> snapToDesktop -> normal
    WindowMode nextMode;
    switch (_mode) {
      case WindowMode.normal:
        nextMode = WindowMode.alwaysOnTop;
        await windowManager.setAlwaysOnTop(true);
        break;
      case WindowMode.alwaysOnTop:
        nextMode = WindowMode.snapToDesktop;
        await windowManager.setAlwaysOnTop(false); // desativa topo antes de snap
        await _snapWindow();
        break;
      case WindowMode.snapToDesktop:
        nextMode = WindowMode.normal;
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setSize(Size(widget.snapWidth, widget.snapHeight));
        await windowManager.center();
        break;
    }
    setState(() {
      _mode = nextMode;
    });
  }

  Future<void> _snapWindow() async {
    final display = await windowManager.getPrimaryDisplay();
    final screenWidth = display.size.width;
    final screenHeight = display.size.height;

    final x = (screenWidth - widget.snapWidth).clamp(0, screenWidth);
    final taskbarOffset = widget.customSnapYOffset ?? 40; // ajuste se necessário
    final y = (screenHeight - widget.snapHeight - taskbarOffset).clamp(0, screenHeight);

    await windowManager.setSize(Size(widget.snapWidth, widget.snapHeight));
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
        tooltip = 'Fixado no topo (Clique para encaixar na área de trabalho)';
        color = Colors.orange;
        break;
      case WindowMode.snapToDesktop:
        icon = Icons.fullscreen_exit;
        tooltip = 'Encaixado na área de trabalho (Clique para voltar ao normal)';
        color = Colors.green;
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
