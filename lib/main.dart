import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/generator/presentation/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Configuration de la taille de la fenêtre de NEAT
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(1000, 700),
    center: true,
    title: 'NEAT - Flutter Architect',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Le ProviderScope est indispensable pour faire fonctionner Riverpod
  runApp(const ProviderScope(child: NeatApp()));
}

class NeatApp extends StatelessWidget {
  const NeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEAT',
      theme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}
