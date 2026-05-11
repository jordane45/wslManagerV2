import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/wsl_instance.dart';
import '../../../providers/instances_provider.dart';
import '../../../providers/monitoring_provider.dart';

class GlobalStatsBar extends ConsumerWidget {
  const GlobalStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instances = ref.watch(instancesProvider);
    final monitoring = ref.watch(monitoringProvider);

    return instances.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final total = list.length;
        final running = list.where((i) => i.state == WslInstanceState.running).length;
        final monData = monitoring.valueOrNull ?? {};
        final cpuSum = monData.values.fold<double>(0, (a, b) => a + b.cpuPercent);
        final ramUsed = monData.values.fold<int>(0, (a, b) => a + b.ramUsedMb);
        final ramTotal = monData.values.fold<int>(0, (a, b) => a + b.ramTotalMb);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
            border: Border(
              bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant, width: 1),
            ),
          ),
          child: Row(
            children: [
              _StatChip(
                icon: Icons.computer,
                label: '$running / $total instances actives',
              ),
              const SizedBox(width: 24),
              if (running > 0) ...[
                _StatChip(
                  icon: Icons.memory,
                  label: 'CPU ${cpuSum.toStringAsFixed(1)}%',
                ),
                const SizedBox(width: 24),
                if (ramTotal > 0)
                  _StatChip(
                    icon: Icons.storage,
                    label: 'RAM $ramUsed Mo / $ramTotal Mo',
                  ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Rafraîchir',
                onPressed: () => ref.read(instancesProvider.notifier).refresh(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
