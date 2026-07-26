import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/palette_controller.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    developer.log(
      details.exceptionAsString(),
      name: 'clipval.flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      '$error',
      name: 'clipval.platform',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  final themeController = ThemeController();
  final paletteController = PaletteController();
  Object? bootstrapError;
  StackTrace? bootstrapStack;

  try {
    await themeController.load();
    await paletteController.load();
    PaletteControllerHolder.instance = paletteController;
    await AppBootstrap.initialize();
  } catch (error, stack) {
    bootstrapError = error;
    bootstrapStack = stack;
    developer.log(
      'Startup failed',
      name: 'clipval.bootstrap',
      error: error,
      stackTrace: stack,
    );
  }

  runApp(
    bootstrapError != null
        ? _BootstrapErrorApp(error: bootstrapError, stackTrace: bootstrapStack)
        : ClipVaultApp(
            themeController: themeController,
            paletteController: paletteController,
          ),
  );
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ClipVal failed to start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text('$error'),
                if (kDebugMode && stackTrace != null) ...[
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        '$stackTrace',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
