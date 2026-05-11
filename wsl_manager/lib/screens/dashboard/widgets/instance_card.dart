import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/wsl_instance.dart';
import '../../../providers/groups_provider.dart';
import '../../../providers/instances_provider.dart';
import '../../../providers/monitoring_provider.dart';
import '../../../services/monitoring_service.dart';
import '../../../services/wsl_service.dart';
import '../../../widgets/cpu_gauge.dart';
import '../../../widgets/ram_gauge.dart';
import '../../../widgets/status_badge.dart';

class InstanceCard extends ConsumerWidget {
  final WslInstance instance;
  const InstanceCard({super.key, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoring = ref.watch(monitoringProvider);
    final data = monitoring.valueOrNull?[instance.name];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Card(
          margin: compact
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/instance/${instance.name}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: compact
                  ? _CompactContent(instance: instance, data: data, ref: ref)
                  : _WideContent(instance: instance, data: data, ref: ref),
            ),
          ),
        );
      },
    );
  }
}

class _WideContent extends StatelessWidget {
  final WslInstance instance;
  final MonitoringData? data;
  final WidgetRef ref;
  const _WideContent({
    required this.instance,
    required this.data,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DistroIcon(name: instance.name),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      instance.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(state: instance.state),
                  const SizedBox(width: 6),
                  _VersionBadge(version: instance.version),
                  if (instance.isDefault) ...[
                    const SizedBox(width: 6),
                    _DefaultBadge(),
                  ],
                ],
              ),
              if (instance.state == WslInstanceState.running &&
                  data != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    CpuGauge(cpuPercent: data!.cpuPercent, radius: 28),
                    const SizedBox(width: 24),
                    RamGauge(
                      usedMb: data!.ramUsedMb,
                      totalMb: data!.ramTotalMb,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        _QuickActions(instance: instance, ref: ref),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}

class _CompactContent extends StatelessWidget {
  final WslInstance instance;
  final MonitoringData? data;
  final WidgetRef ref;
  const _CompactContent({
    required this.instance,
    required this.data,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DistroIcon(name: instance.name),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  instance.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _QuickActions(instance: instance, ref: ref),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(state: instance.state),
              _VersionBadge(version: instance.version),
              if (instance.isDefault) _DefaultBadge(),
            ],
          ),
          const Spacer(),
          if (instance.state == WslInstanceState.running && data != null)
            Row(
              children: [
                CpuGauge(cpuPercent: data!.cpuPercent, radius: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: RamGauge(
                    usedMb: data!.ramUsedMb,
                    totalMb: data!.ramTotalMb,
                  ),
                ),
              ],
            )
          else
            Text(
              'Monitoring indisponible',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }
}

class _DistroIcon extends StatelessWidget {
  final String name;
  const _DistroIcon({required this.name});

  String get _iconAsset {
    final n = name.toLowerCase();
    if (n.contains('ubuntu')) return 'assets/icons/distros/ubuntu.png';
    if (n.contains('debian')) return 'assets/icons/distros/debian.png';
    if (n.contains('kali')) return 'assets/icons/distros/kali.png';
    if (n.contains('alpine')) return 'assets/icons/distros/alpine.png';
    if (n.contains('opensuse')) return 'assets/icons/distros/opensuse.png';
    if (n.contains('oracle')) return 'assets/icons/distros/oracle.png';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_iconAsset.isEmpty) {
      return Container(
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.terminal, size: 20),
      );
    }
    return Image.asset(
      _iconAsset,
      width: 36,
      height: 36,
      errorBuilder: (_, __, ___) => const Icon(Icons.terminal, size: 36),
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
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        version == WslVersion.wsl2 ? 'WSL2' : 'WSL1',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Defaut',
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final WslInstance instance;
  final WidgetRef ref;
  const _QuickActions({required this.instance, required this.ref});

  @override
  Widget build(BuildContext context) {
    final stopped = instance.state == WslInstanceState.stopped;
    final running = instance.state == WslInstanceState.running;
    final groupState = ref.watch(groupsProvider).valueOrNull;
    final currentGroupId = groupState?.assignments[instance.name];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stopped)
          _ActionButton(
            icon: Icons.play_arrow_rounded,
            tooltip: 'Demarrer',
            color: const Color(0xFF22C55E),
            onPressed: () =>
                ref.read(instancesProvider.notifier).start(instance.name),
          ),
        if (running)
          _ActionButton(
            icon: Icons.stop_rounded,
            tooltip: 'Arreter',
            color: Colors.orange,
            onPressed: () =>
                ref.read(instancesProvider.notifier).stop(instance.name),
          ),
        if (!stopped && !running) const SizedBox(width: 34),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'Actions',
          icon: const Icon(Icons.more_horiz, size: 20),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'open:vscode',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.code, size: 18),
                title: Text('VSCode'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'open:terminal',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.terminal, size: 18),
                title: Text('Terminal'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'open:explorer',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.folder_open, size: 18),
                title: Text('Explorateur'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              enabled: false,
              child: Text('Changer de groupe'),
            ),
            PopupMenuItem(
              value: 'group:',
              child: ListTile(
                dense: true,
                leading: Icon(
                  currentGroupId == null ? Icons.check : Icons.clear,
                  size: 18,
                ),
                title: const Text('Non classees'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            ...?groupState?.groups.map(
              (group) => PopupMenuItem(
                value: 'group:${group.id}',
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    currentGroupId == group.id ? Icons.check : Icons.folder,
                    size: 18,
                  ),
                  title: Text(group.name),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'open:vscode') {
              WslService.instance.openInVsCode(instance.name);
            } else if (value == 'open:terminal') {
              WslService.instance.openInTerminal(instance.name);
            } else if (value == 'open:explorer') {
              WslService.instance.openInExplorer(instance.name);
            } else if (value.startsWith('group:')) {
              final groupId = value.substring('group:'.length);
              ref
                  .read(groupsProvider.notifier)
                  .assign(instance.name, groupId.isEmpty ? null : groupId);
            }
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 34,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }
}
