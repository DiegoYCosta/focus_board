import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter/material.dart';
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

bool filterActive = false;


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
if (e.message.contains('requer elevação') ||
e.message.contains('requires elevation')) {
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
slideshowTimer =
Timer.periodic(Duration(seconds: slideshowInterval), (_) => _nextTip());
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
  final imageWidget = (tip.hasImage && file != null)
      ? ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: 320, // ou qualquer valor apropriado
      minHeight: 60,  // se quiser uma altura mínima
      maxWidth: double.infinity,
    ),
    child: Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      // height: double.infinity, // REMOVA ESSA LINHA!
    ),
  )
      : Image.asset(
    'assets/Athenas_Smile.png',
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
  );

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Stack(
        alignment: Alignment.topRight,
        children: [
          // Fundo com imagem (sempre exibida)
          Stack(
            children: [
              // Imagem com opacidade ajustada
              Opacity(
                opacity: filterActive ? 0.05 : 1.0,
                child: imageWidget,
              ),
              // Quando filtro está ativo, centraliza o texto sobre a imagem, com alta legibilidade
              if (filterActive && tip.content.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.87),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          tip.content,
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Botão de abrir link, se só houver link e nenhum texto
          if (tip != null && (tip.link ?? '').isNotEmpty && tip.content.isEmpty)
            Padding(
              padding: EdgeInsets.all(4),
              child: Tooltip(
                message: 'Clique para abrir o link',
                child: Icon(Icons.open_in_new,
                    size: 15, color: Colors.blue.withOpacity(0.30)),
              ),
            ),
        ],
      ),
      // Espaçamento e conteúdo textual original (quando não está filtrando, exibe o texto normal)
      if (tip.content.isNotEmpty && !filterActive) SizedBox(height: 16),
      if (tip.content.isNotEmpty && !filterActive)
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
      // Link preview, se houver link e opção showLink estiver ativada
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

@override
Widget build(BuildContext context) {
final tipList = visibleTips;
final tip = tipList.isNotEmpty && currentIndex < tipList.length
? tipList[currentIndex]
    : null;
final themeManager = Provider.of<ThemeManager>(context);

return Scaffold(
extendBodyBehindAppBar: true,
body: Stack(
children: [
// 1) Conteúdo principal
Center(
child: tip == null
? EmptyTipsPlaceholder()
    : Container(
height: MediaQuery.of(context).size.height * 0.85,
child: SingleChildScrollView(
child: Padding(
padding: EdgeInsets.all(12),
child: _buildTipContent(tip),
),
),
),
),
// 2) Container flutuante com botões
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
bottomNavigationBar: tipList.isEmpty
? null
    : SizedBox(
height: kToolbarHeight,
child: BottomAppBar(
child: Row(
children: [
// Lado esquerdo
Expanded(
child: Row(
mainAxisAlignment: MainAxisAlignment.start,
children: [
  IconButton(
    icon: Icon(Icons.filter_list, size: 14, color: Colors.grey[600]),
    onPressed: () {
      setState(() {
        filterActive = !filterActive;
      });
    },
    tooltip: 'Ocultar Tela',
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
icon: Icon(Icons.grid_view,
size: 14, color: Colors.grey[600]),
onPressed: _openTipGallery,
tooltip: 'Galeria',
splashRadius: 20,
padding: EdgeInsets.zero,
constraints: BoxConstraints.tight(Size(36, 36)),
),
],
),
),
// Lado direito
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