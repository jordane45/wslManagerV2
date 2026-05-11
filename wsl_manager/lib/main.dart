import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/command_log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Window.initialize();
  await windowManager.ensureInitialized();
  await CommandLogService.instance.load();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1200, 750),
    minimumSize: Size(900, 600),
    center: true,
    title: 'WSL Manager',
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await Window.setEffect(
    effect: WindowEffect.mica,
    dark: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: App()));
}
