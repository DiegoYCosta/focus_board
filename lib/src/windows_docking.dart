// lib/src/windows_docking.dart
import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';

// Constantes para mensagens do SHAppBarMessage
const int ABM_NEW = 0x00000000; // Registra uma nova barra de aplicativos
const int ABM_REMOVE = 0x00000001; // Remove uma barra de aplicativos
const int ABM_SETPOS = 0x00000003; // Define a posição da barra de aplicativos

// Constantes para bordas da barra de aplicativos
const int ABE_RIGHT = 2; // Dock na borda direita

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

class WindowDocking {
static bool _isDocked = false;
static int _hWnd = 0;
static double _aspectRatio = 0.0;
static Size _previousSize = Size.zero;
static Offset _previousPosition = Offset.zero;

static Future<void> dockWindowToRight() async {
// Obtém o handle da janela atual
final hWnd = GetForegroundWindow();
if (hWnd == 0) return; // Evita prosseguir se o handle for inválido

// Armazena o handle para uso posterior
_hWnd = hWnd;

// Salva o tamanho e posição atuais para restauração futura
_previousSize = await windowManager.getSize();
_previousPosition = await windowManager.getPosition();
_aspectRatio = _previousSize.width / _previousSize.height;

// Obtém informações do monitor primário
final monitorInfo = calloc<MONITORINFO>();
try {
monitorInfo.ref.cbSize = sizeOf<MONITORINFO>();
final hMonitor = MonitorFromWindow(hWnd, MONITOR_DEFAULTTONEAREST);
if (GetMonitorInfo(hMonitor, monitorInfo) == 0) {
return; // Falha ao obter informações do monitor
}
final workArea = monitorInfo.ref.rcWork;

// Configura a barra de aplicativos
final appBarData = calloc<APPBARDATA>();
try {
appBarData.ref.cbSize = sizeOf<APPBARDATA>();
appBarData.ref.hWnd = hWnd;
appBarData.ref.uEdge = ABE_RIGHT; // Dock na direita
appBarData.ref.rc.left = workArea.right - 350; // Largura fixa de 350px
appBarData.ref.rc.top = workArea.top;
appBarData.ref.rc.right = workArea.right;
appBarData.ref.rc.bottom = workArea.bottom;

final shell32 = DynamicLibrary.open('shell32.dll');
final shAppBarMessage = shell32.lookupFunction<
IntPtr Function(Uint32, Pointer<APPBARDATA>),
int Function(int, Pointer<APPBARDATA>)>('SHAppBarMessage');

// Registra a janela como uma barra de aplicativos
shAppBarMessage(ABM_NEW, appBarData);

// Define a posição da barra
shAppBarMessage(ABM_SETPOS, appBarData);

// Define a posição e tamanho da janela
await windowManager.setPosition(
Offset(appBarData.ref.rc.left.toDouble(), appBarData.ref.rc.top.toDouble()),
);
await windowManager.setSize(
Size(
(appBarData.ref.rc.right - appBarData.ref.rc.left).toDouble(),
(appBarData.ref.rc.bottom - appBarData.ref.rc.top).toDouble(),
),
);

// Configurações da janela
await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
await windowManager.setResizable(false); // Janela não redimensionável quando dockada
await windowManager.setAspectRatio(_aspectRatio);
await windowManager.setAlwaysOnTop(true); // Garante que a janela fique visível
_isDocked = true;
} finally {
free(appBarData);
}
} finally {
free(monitorInfo);
}
}

static Future<void> undockWindow() async {
if (!_isDocked || _hWnd == 0) return;

final appBarData = calloc<APPBARDATA>();
try {
appBarData.ref.cbSize = sizeOf<APPBARDATA>();
appBarData.ref.hWnd = _hWnd;

final shell32 = DynamicLibrary.open('shell32.dll');
final shAppBarMessage = shell32.lookupFunction<
IntPtr Function(Uint32, Pointer<APPBARDATA>),
int Function(int, Pointer<APPBARDATA>)>('SHAppBarMessage');

// Remove a janela do registro de barra de aplicativos
shAppBarMessage(ABM_REMOVE, appBarData);

// Restaura configurações normais
await windowManager.setTitleBarStyle(TitleBarStyle.normal);
await windowManager.setResizable(true); // Janela volta a ser redimensionável
await windowManager.setAspectRatio(0.0); // Remove proporção fixa
await windowManager.setAlwaysOnTop(false);

// Restaura tamanho e posição anteriores
await windowManager.setSize(_previousSize);
await windowManager.setPosition(_previousPosition);

_isDocked = false;
_hWnd = 0;
} finally {
free(appBarData);
}
}

static Future<void> minimizeWindow() async {
await windowManager.minimize();
}

static Future<void> toggleDockRight() async {
if (_isDocked) {
await undockWindow();
} else {
await dockWindowToRight();
}
}

static bool isDocked() => _isDocked;
}