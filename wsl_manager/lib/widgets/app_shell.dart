import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/config_provider.dart';
import '../providers/instances_provider.dart';
import '../providers/monitoring_alerts_provider.dart';
import '../services/systray_service.dart';
import '../services/wsl_service.dart';
import 'custom_title_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WindowListener {
  bool _hasShownTrayHint = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initSystray();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    SystrayService.instance.destroy();
    super.dispose();
  }

  Future<void> _initSystray() async {
    final service = SystrayService.instance;

    service.onShowWindow = () async {
      await windowManager.show();
      await windowManager.focus();
    };

    service.onQuit = () async {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    };

    service.onToggleInstance = (name, start) async {
      if (start) {
        await WslService.instance.startInstance(name);
      } else {
        await WslService.instance.stopInstance(name);
      }
      ref.read(instancesProvider.notifier).refresh();
    };

    await service.init();
  }

  @override
  void onWindowClose() async {
    final config = ref.read(configProvider).valueOrNull;
    final minimizeToTray = config?.minimizeToTray ?? true;

    if (minimizeToTray) {
      await windowManager.hide();
      if (!_hasShownTrayHint && mounted) {
        _hasShownTrayHint = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('WSL Manager tourne en arriere-plan dans le systray.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final instances = ref.read(instancesProvider).valueOrNull ?? [];
    SystrayService.instance.updateMenu(instances);
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/instance') || loc == '/') return 0;
    if (loc == '/templates') return 1;
    if (loc == '/snapshots') return 2;
    if (loc == '/logs') return 3;
    if (loc == '/settings') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(monitoringAlertsProvider);

    ref.listen(instancesProvider, (_, next) {
      SystrayService.instance.updateMenu(next.valueOrNull ?? []);
    });

    final idx = _selectedIndex(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const CustomTitleBar(),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  selectedIndex: idx,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 84,
                  useIndicator: true,
                  indicatorColor: colorScheme.primaryContainer,
                  selectedLabelTextStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  selectedIconTheme: IconThemeData(
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  onDestinationSelected: (i) {
                    switch (i) {
                      case 0:
                        context.go('/');
                      case 1:
                        context.go('/templates');
                      case 2:
                        context.go('/snapshots');
                      case 3:
                        context.go('/logs');
                      case 4:
                        context.go('/settings');
                    }
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.layers_outlined),
                      selectedIcon: Icon(Icons.layers),
                      label: Text('Templates'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.camera_alt_outlined),
                      selectedIcon: Icon(Icons.camera_alt),
                      label: Text('Snapshots'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.terminal_outlined),
                      selectedIcon: Icon(Icons.terminal),
                      label: Text('Logs'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Parametres'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
