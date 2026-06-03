import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/error/error_handler.dart';
import 'package:neat/core/observers/provider_observer.dart';
import 'package:neat/core/theme/app_theme.dart';
import 'package:neat/core/utils/app_logger.dart';
import 'package:neat/features/splash/presentation/screens/splash_screen.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async => bootstrap();

Future<void> bootstrap() async {
  registerErrorHandler();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await windowManager.ensureInitialized();
      // Configuration de la taille de la fenêtre de NEAT
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1400, 900),
        minimumSize: Size(1200, 800),
        center: true,
        title: 'NEAT - Flutter Architect',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      final container = ProviderContainer(observers: [RiverpodObserver()]);

      // Le ProviderScope est indispensable pour faire fonctionner Riverpod
      runApp(UncontrolledProviderScope(container: container, child: const NeatApp()));
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
      home: const SplashScreen(),
    );
  }
}
