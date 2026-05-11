import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:system_tray/system_tray.dart';
import '../models/wsl_instance.dart';

class SystrayService {
  static SystrayService? _instance;
  static SystrayService get instance => _instance ??= SystrayService._();
  SystrayService._();

  final _tray = SystemTray();
  bool _initialized = false;

  VoidCallback? onShowWindow;
  VoidCallback? onQuit;
  void Function(String name, bool start)? onToggleInstance;

  String get _iconPath {
    if (kReleaseMode) {
      return p.join(
        p.dirname(Platform.resolvedExecutable),
        'data', 'flutter_assets', 'assets', 'icons', 'app_icon.ico',
      );
    }
    return 'assets/icons/app_icon.ico';
  }

  Future<void> init() async {
    try {
      await _tray.initSystemTray(
        title: 'WSL Manager',
        iconPath: _iconPath,
        toolTip: 'WSL Manager',
      );
      _tray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick ||
            eventName == kSystemTrayEventRightClick) {
          _tray.popUpContextMenu();
        }
      });
      _initialized = true;
      await updateMenu([]);
    } catch (e) {
      // Systray unavailable (missing .ico or unsupported environment)
      debugPrint('SystrayService init failed: $e');
    }
  }

  Future<void> updateMenu(List<WslInstance> instances) async {
    if (!_initialized) return;
    try {
      final menu = Menu();
      final items = <MenuItemBase>[];

      for (final inst in instances) {
        final running = inst.state == WslInstanceState.running;
        items.add(MenuItemLabel(
          label: '${inst.name}  (${running ? 'Running' : 'Stopped'})',
          onClicked: (_) =>
              onToggleInstance?.call(inst.name, !running),
        ));
      }

      if (instances.isNotEmpty) items.add(MenuSeparator());

      items.add(MenuItemLabel(
        label: 'Ouvrir WSL Manager',
        onClicked: (_) => onShowWindow?.call(),
      ));

      items.add(MenuSeparator());

      items.add(MenuItemLabel(
        label: 'Quitter',
        onClicked: (_) => onQuit?.call(),
      ));

      await menu.buildFrom(items);
      await _tray.setContextMenu(menu);
    } catch (e) {
      debugPrint('SystrayService updateMenu failed: $e');
    }
  }

  Future<void> destroy() async {
    if (!_initialized) return;
    await _tray.destroy();
    _initialized = false;
  }
}
