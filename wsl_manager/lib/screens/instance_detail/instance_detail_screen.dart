import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wsl_instance.dart';
import '../../providers/instances_provider.dart';
import '../../widgets/status_badge.dart';
import 'widgets/info_panel.dart';
import 'widgets/actions_panel.dart';
import 'widgets/monitoring_panel.dart';
import 'widgets/wsl_conf_editor.dart';
import 'widgets/snapshots_tab.dart';

class InstanceDetailScreen extends ConsumerWidget {
  final String name;
  const InstanceDetailScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instances = ref.watch(instancesProvider);
    final instance = instances.valueOrNull?.firstWhere(
      (i) => i.name == name,
      orElse: () => WslInstance(
        name: name,
        state: WslInstanceState.stopped,
        version: WslVersion.wsl2,
        isDefault: false,
      ),
    );

    if (instance == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          _InstanceHeader(instance: instance),
          const TabBar(
            tabs: [
              Tab(text: 'Informations'),
              Tab(text: 'Actions'),
              Tab(text: 'Monitoring'),
              Tab(text: 'wsl.conf'),
              Tab(text: 'Snapshots'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                InfoPanel(instance: instance),
                ActionsPanel(instance: instance),
                MonitoringPanel(instance: instance),
                WslConfEditor(instanceName: instance.name),
                SnapshotsTab(instanceName: instance.name),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstanceHeader extends StatelessWidget {
  final WslInstance instance;
  const _InstanceHeader({required this.instance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(instance.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(width: 12),
          StatusBadge(state: instance.state),
          const SizedBox(width: 8),
          _VersionBadge(version: instance.version),
          if (instance.isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Défaut',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer)),
            ),
          ],
        ],
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final WslVersion version;
  const _VersionBadge({required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        version == WslVersion.wsl2 ? 'WSL2' : 'WSL1',
        style:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
