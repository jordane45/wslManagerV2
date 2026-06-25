import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/wsl_instance.dart';
import '../../../models/wsl_port.dart';
import '../../../providers/monitoring_provider.dart';
import '../../../providers/ports_provider.dart';
import '../../../services/wsl_service.dart';

class InfoPanel extends ConsumerStatefulWidget {
  final WslInstance instance;
  const InfoPanel({super.key, required this.instance});

  @override
  ConsumerState<InfoPanel> createState() => _InfoPanelState();
}

class _InfoPanelState extends ConsumerState<InfoPanel> {
  ({String? basePath, String? vhdxPath, int? sizeBytes})? _diskInfo;
  bool _diskLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDiskInfo();
  }

  @override
  void didUpdateWidget(InfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance.name != widget.instance.name) {
      _diskInfo = null;
      _loadDiskInfo();
    }
  }

  Future<void> _loadDiskInfo() async {
    setState(() => _diskLoading = true);
    final info =
        await WslService.instance.getInstanceDiskInfo(widget.instance.name);
    if (mounted) {
      setState(() {
        _diskInfo = info;
        _diskLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitoring = ref.watch(monitoringProvider);
    final data = monitoring.valueOrNull?[widget.instance.name];
    final isRunning = widget.instance.state == WslInstanceState.running;
    final ports = isRunning
        ? ref.watch(portsProvider(widget.instance.name))
        : const AsyncData(<WslPort>[]);
    final unavailable = isRunning ? 'En attente...' : 'Non disponible';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _InfoSection(title: 'Général', rows: [
          _InfoRow('Nom', widget.instance.name),
          if (widget.instance.description != null &&
              widget.instance.description!.isNotEmpty)
            _InfoRow('Description', widget.instance.description!),
          _InfoRow('État', _stateLabel(widget.instance.state)),
          _InfoRow(
            'Version WSL',
            widget.instance.version == WslVersion.wsl2 ? 'WSL 2' : 'WSL 1',
          ),
          _InfoRow(
              'Instance par défaut', widget.instance.isDefault ? 'Oui' : 'Non'),
        ]),
        const SizedBox(height: 16),
        _InfoSection(
          title: 'Stockage',
          rows: const [],
          child: _DiskInfoWidget(
            diskInfo: _diskInfo,
            loading: _diskLoading,
            onBrowse: _diskInfo?.basePath != null
                ? () => WslService.instance
                    .openInExplorerPath(_diskInfo!.basePath!)
                : null,
            onRefresh: _loadDiskInfo,
          ),
        ),
        const SizedBox(height: 16),
        _InfoSection(
          title: 'Réseau',
          rows: [
            _InfoRow('Adresse IP', data?.ipAddress ?? unavailable),
          ],
          child: _PortsList(
            instanceName: widget.instance.name,
            isRunning: isRunning,
            ports: ports,
          ),
        ),
      ],
    );
  }

  String _stateLabel(WslInstanceState state) => switch (state) {
        WslInstanceState.running => 'En cours d\'exécution',
        WslInstanceState.stopped => 'Arrêtée',
        WslInstanceState.installing => 'Installation...',
      };
}

class _DiskInfoWidget extends StatelessWidget {
  final ({String? basePath, String? vhdxPath, int? sizeBytes})? diskInfo;
  final bool loading;
  final VoidCallback? onBrowse;
  final VoidCallback onRefresh;

  const _DiskInfoWidget({
    required this.diskInfo,
    required this.loading,
    required this.onBrowse,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    final basePath = diskInfo?.basePath;
    final vhdxPath = diskInfo?.vhdxPath;
    final sizeBytes = diskInfo?.sizeBytes;

    if (basePath == null) {
      return Row(
        children: [
          Text(
            'Emplacement introuvable',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: onRefresh,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiskRow(
          label: 'Dossier',
          value: basePath,
          onBrowse: onBrowse,
        ),
        if (vhdxPath != null)
          _DiskRow(
            label: 'Fichier VHDX',
            value: vhdxPath.split('\\').last,
          ),
        if (sizeBytes != null)
          _DiskRow(
            label: 'Taille sur disque',
            value: _formatSize(sizeBytes),
          ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} Mo';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} Ko';
  }
}

class _DiskRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onBrowse;

  const _DiskRow({required this.label, required this.value, this.onBrowse});

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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                fontFamily: 'Courier New',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onBrowse != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Ouvrir dans l\'Explorateur',
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: onBrowse,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.folder_open,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            tooltip: 'Copier',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
          ),
        ],
      ),
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
              const SizedBox(height: 4),
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
              'Ports en écoute',
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
