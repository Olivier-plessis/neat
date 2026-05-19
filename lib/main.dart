import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/error/error_handler.dart';
import 'package:neat/core/observers/provider_observer.dart';
import 'package:neat/core/utils/app_logger.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/generator/presentation/screens/main_layout.dart';

Future<void> main() async => bootstrap();

Future<void> bootstrap() async {
  registerErrorHandler();

  await runZonedGuarded(
    () async {
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

      final container = ProviderContainer(observers: [RiverpodObserver()]);

      // Le ProviderScope est indispensable pour faire fonctionner Riverpod
      runApp(
        UncontrolledProviderScope(container: container, child: const NeatApp()),
      );
    },
    (error, stackTrace) {
      AppLogger.f('Uncaught exception', error: error, stackTrace: stackTrace);
    },
  );
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
