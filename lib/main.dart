import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'src/home_page.dart';
import 'src/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do window_manager (fundamental para manipulação de janela no desktop!)
  await windowManager.ensureInitialized();

  // Configuração extra opcional para melhorar a experiência desktop
  WindowOptions windowOptions = const WindowOptions(
    size: Size(420, 600),
    minimumSize: Size(320, 380),
    center: true,
    backgroundColor: Colors.transparent,
    title: "Focus Board",
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // ThemeManager precisa ser carregado antes de iniciar o app (senão o tema inicial pode piscar)
  final themeManager = ThemeManager();
  await themeManager.loadPreferences();

  runApp(
    ChangeNotifierProvider.value(
      value: themeManager,
      child: const FocusBoardApp(),
    ),
  );
}

class FocusBoardApp extends StatelessWidget {
  const FocusBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      title: 'Focus Board',
      debugShowCheckedModeBanner: false,
      theme: themeManager.themeData,
      home: HomePage(),
    );
  }
}
