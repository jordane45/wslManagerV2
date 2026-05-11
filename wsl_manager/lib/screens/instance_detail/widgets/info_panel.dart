import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/wsl_instance.dart';
import '../../../models/wsl_port.dart';
import '../../../providers/monitoring_provider.dart';
import '../../../providers/ports_provider.dart';

class InfoPanel extends ConsumerWidget {
  final WslInstance instance;
  const InfoPanel({super.key, required this.instance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoring = ref.watch(monitoringProvider);
    final data = monitoring.valueOrNull?[instance.name];
    final isRunning = instance.state == WslInstanceState.running;
    final ports = isRunning
        ? ref.watch(portsProvider(instance.name))
        : const AsyncData(<WslPort>[]);
    final unavailable = isRunning ? 'En attente...' : 'Non disponible';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _InfoSection(title: 'Général', rows: [
          _InfoRow('Nom', instance.name),
          _InfoRow('État', instance.state.name),
          _InfoRow(
            'Version WSL',
            instance.version == WslVersion.wsl2 ? 'WSL 2' : 'WSL 1',
          ),
          _InfoRow('Instance par défaut', instance.isDefault ? 'Oui' : 'Non'),
        ]),
        const SizedBox(height: 16),
        _InfoSection(
          title: 'Réseau',
          rows: [
            _InfoRow('Adresse IP', data?.ipAddress ?? unavailable),
          ],
          child: _PortsList(
            instanceName: instance.name,
            isRunning: isRunning,
            ports: ports,
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  final Widget? child;
  const _InfoSection({
    required this.title,
    required this.rows,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 16),
            ...rows,
            if (child != null) ...[
              const SizedBox(height: 8),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortsList extends ConsumerWidget {
  final String instanceName;
  final bool isRunning;
  final AsyncValue<List<WslPort>> ports;

  const _PortsList({
    required this.instanceName,
    required this.isRunning,
    required this.ports,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ports forwardés',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Rafraîchir',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: isRunning
                  ? () => ref.invalidate(portsProvider(instanceName))
                  : null,
            ),
          ],
        ),
        if (!isRunning)
          const Text(
            'Non disponible',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          )
        else
          ports.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (e, _) => Text(
              'Erreur : $e',
              style: TextStyle(color: colorScheme.error, fontSize: 13),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Text(
                  'Aucun port en écoute détecté',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final port in items)
                    Chip(
                      label: Text('${port.protocol} ${port.endpoint}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
