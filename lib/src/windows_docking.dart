import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';

final class RECT extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}

// Definição completa da struct APPBARDATA
final class APPBARDATA extends Struct {
  @Uint32()
  external int cbSize;
  @IntPtr()
  external int hWnd;
  @Uint32()
  external int uCallbackMessage;
  @Uint32()
  external int uEdge;
  external RECT rc;
  @Int32()
  external int lParam;
}

void dockWindowToRight() async {
  // Use GetForegroundWindow como fallback para o handle da janela (HWND)
  final hWnd = GetForegroundWindow();
  final appBarData = calloc<APPBARDATA>();
  try {
    appBarData.ref.cbSize = sizeOf<APPBARDATA>();
    appBarData.ref.hWnd = hWnd;
    appBarData.ref.uEdge = 2;

    final monitorInfo = calloc<MONITORINFO>();
    try {
      monitorInfo.ref.cbSize = sizeOf<MONITORINFO>();
      final hMonitor = MonitorFromWindow(hWnd, MONITOR_DEFAULTTONEAREST);
      GetMonitorInfo(hMonitor, monitorInfo);
      final workArea = monitorInfo.ref.rcWork;

      appBarData.ref.rc.left = workArea.right - 350; // Ajuste a largura conforme necessário
      appBarData.ref.rc.top = workArea.top;
      appBarData.ref.rc.right = workArea.right;
      appBarData.ref.rc.bottom = workArea.bottom;

      // Carregue SHAppBarMessage dinamicamente de shell32.dll
      final shell32 = DynamicLibrary.open('shell32.dll');
      final shAppBarMessage = shell32.lookupFunction<
          IntPtr Function(Uint32, Pointer<APPBARDATA>),
          int Function(int, Pointer<APPBARDATA>)>('SHAppBarMessage');

      shAppBarMessage(0x00000003, appBarData);
      shAppBarMessage(0x00000006, appBarData);
    } finally {
      free(monitorInfo);
    }

    // Defina a posição e tamanho da janela
    await windowManager.setPosition(
      Offset(appBarData.ref.rc.left.toDouble(), appBarData.ref.rc.top.toDouble()),
    );
    await windowManager.setSize(
      Size(
        (appBarData.ref.rc.right - appBarData.ref.rc.left).toDouble(),
        (appBarData.ref.rc.bottom - appBarData.ref.rc.top).toDouble(),
      ),
    );
  } finally {
    free(appBarData);
  }
}

void undockWindow() async {
  final hWnd = GetForegroundWindow();
  final appBarData = calloc<APPBARDATA>();
  try {
    appBarData.ref.cbSize = sizeOf<APPBARDATA>();
    appBarData.ref.hWnd = hWnd;

    final shell32 = DynamicLibrary.open('shell32.dll');
    final shAppBarMessage = shell32.lookupFunction<
        IntPtr Function(Uint32, Pointer<APPBARDATA>),
        int Function(int, Pointer<APPBARDATA>)>('SHAppBarMessage');

    shAppBarMessage(0x00000001, appBarData);
  } finally {
    free(appBarData);
  }
}

void minimizeWindow() async {
  await windowManager.minimize();
}

bool _isDocked = false;
void toggleDockRight() {
  if (_isDocked) {
    undockWindow();
  } else {
    dockWindowToRight();
  }
  _isDocked = !_isDocked;
}