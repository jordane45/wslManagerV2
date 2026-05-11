import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/command_log_entry.dart';
import '../../providers/command_logs_provider.dart';

class CommandLogsScreen extends ConsumerStatefulWidget {
  const CommandLogsScreen({super.key});

  @override
  ConsumerState<CommandLogsScreen> createState() => _CommandLogsScreenState();
}

class _CommandLogsScreenState extends ConsumerState<CommandLogsScreen> {
  String _search = '';
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(commandLogsProvider);
    final entries = service.entries
        .where((entry) =>
            entry.commandLine.toLowerCase().contains(_search.toLowerCase()) ||
            entry.output.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final selected = entries.cast<CommandLogEntry?>().firstWhere(
          (entry) => entry?.id == _selectedId,
          orElse: () => entries.isEmpty ? null : entries.first,
        );
    _selectedId = selected?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs WSL'),
        actions: [
          IconButton(
            tooltip: 'Vider les logs',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: service.entries.isEmpty
                ? null
                : () async {
                    final confirmed = await _confirmClear(context);
                    if (confirmed) {
                      service.clear();
                      setState(() => _selectedId = null);
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher une commande ou une sortie...',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const _EmptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 860) {
                        return _NarrowLogsList(
                          entries: entries,
                          onTap: (entry) => _showDetails(context, entry),
                        );
                      }
                      return Row(
                        children: [
                          SizedBox(
                            width: 390,
                            child: _LogsList(
                              entries: entries,
                              selectedId: selected?.id,
                              onSelected: (entry) =>
                                  setState(() => _selectedId = entry.id),
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: selected == null
                                ? const _EmptyState()
                                : _LogDetails(entry: selected),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context, CommandLogEntry entry) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: _LogDetails(entry: entry),
      ),
    );
  }

  Future<bool> _confirmClear(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vider les logs WSL'),
            content: const Text('Supprimer tout l\'historique des commandes ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Vider'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _LogsList extends StatelessWidget {
  final List<CommandLogEntry> entries;
  final String? selectedId;
  final ValueChanged<CommandLogEntry> onSelected;

  const _LogsList({
    required this.entries,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _LogTile(
          entry: entry,
          selected: entry.id == selectedId,
          onTap: () => onSelected(entry),
        );
      },
    );
  }
}

class _NarrowLogsList extends StatelessWidget {
  final List<CommandLogEntry> entries;
  final ValueChanged<CommandLogEntry> onTap;

  const _NarrowLogsList({
    required this.entries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _LogTile(entry: entry, onTap: () => onTap(entry));
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  final CommandLogEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _LogTile({
    required this.entry,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = selected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLowest;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusIcon(entry: entry),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.commandLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatTime(entry.startedAt)}  •  ${_statusText(entry)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogDetails extends StatelessWidget {
  final CommandLogEntry entry;
  const _LogDetails({required this.entry});

  @override
  Widget build(BuildContext context) {
    final output =
        entry.output.isEmpty ? 'Aucune sortie console.' : entry.output;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusIcon(entry: entry),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  entry.commandLine,
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copier la commande',
                icon: const Icon(Icons.content_copy, size: 18),
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: entry.commandLine),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                  icon: Icons.schedule, label: _formatTime(entry.startedAt)),
              _MetaChip(
                  icon: Icons.timer_outlined, label: _durationText(entry)),
              _MetaChip(icon: Icons.numbers, label: _exitCodeText(entry)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Sortie console',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copier la sortie',
                icon: const Icon(Icons.copy_all, size: 18),
                onPressed: entry.output.isEmpty
                    ? null
                    : () =>
                        Clipboard.setData(ClipboardData(text: entry.output)),
              ),
            ],
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  output,
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final CommandLogEntry entry;
  const _StatusIcon({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.isRunning) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final color = entry.succeeded ? const Color(0xFF16A34A) : Colors.red;
    return Icon(
      entry.succeeded ? Icons.check_circle : Icons.error_outline,
      size: 18,
      color: color,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.terminal_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun log WSL disponible.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.day)}/${_two(local.month)}/${local.year} '
      '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
}

String _statusText(CommandLogEntry entry) {
  if (entry.isRunning) return 'En cours';
  return entry.succeeded ? 'Terminee avec succes' : 'Erreur';
}

String _durationText(CommandLogEntry entry) {
  final duration = entry.duration;
  if (duration == null) return 'En cours';
  if (duration.inSeconds < 1) return '${duration.inMilliseconds} ms';
  return '${duration.inSeconds}.${(duration.inMilliseconds % 1000) ~/ 100} s';
}

String _exitCodeText(CommandLogEntry entry) {
  if (entry.exitCode == null) return 'Code en attente';
  return 'Code ${entry.exitCode}';
}

String _two(int value) => value.toString().padLeft(2, '0');
