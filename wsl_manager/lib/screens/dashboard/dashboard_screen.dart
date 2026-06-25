import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/instance_group.dart';
import '../../models/wsl_instance.dart';
import '../../providers/groups_provider.dart';
import '../../providers/instances_provider.dart';
import '../../widgets/uac_banner.dart';
import 'widgets/global_stats_bar.dart';
import 'widgets/instance_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _search = '';
  _SortMode _sort = _SortMode.name;
  _StateFilter _stateFilter = _StateFilter.all;
  bool _filterDocker = false;
  bool _filterPodman = false;

  @override
  Widget build(BuildContext context) {
    final instances = ref.watch(instancesProvider);
    final groups = ref.watch(groupsProvider);

    return Column(
      children: [
        const UacBanner(),
        const GlobalStatsBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Toutes'),
                selected: _stateFilter == _StateFilter.all,
                onSelected: (_) =>
                    setState(() => _stateFilter = _StateFilter.all),
              ),
              FilterChip(
                avatar: const Icon(Icons.circle, size: 10, color: Color(0xFF22C55E)),
                label: const Text('Démarrées'),
                selected: _stateFilter == _StateFilter.running,
                onSelected: (_) =>
                    setState(() => _stateFilter = _StateFilter.running),
              ),
              FilterChip(
                avatar: const Icon(Icons.circle, size: 10, color: Colors.grey),
                label: const Text('Arrêtées'),
                selected: _stateFilter == _StateFilter.stopped,
                onSelected: (_) =>
                    setState(() => _stateFilter = _StateFilter.stopped),
              ),
              FilterChip(
                avatar: const Icon(Icons.hub, size: 14),
                label: const Text('Docker'),
                selected: _filterDocker,
                onSelected: (v) => setState(() => _filterDocker = v),
              ),
              FilterChip(
                avatar: const Icon(Icons.inventory_2_outlined, size: 14),
                label: const Text('Podman'),
                selected: _filterPodman,
                onSelected: (v) => setState(() => _filterPodman = v),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final searchField = TextField(
                decoration: const InputDecoration(
                  hintText: 'Rechercher une instance...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                onChanged: (v) => setState(() => _search = v),
              );
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<_SortMode>(
                    value: _sort,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: _SortMode.name,
                        child: Text('Nom A-Z'),
                      ),
                      DropdownMenuItem(
                        value: _SortMode.state,
                        child: Text('Etat'),
                      ),
                      DropdownMenuItem(
                        value: _SortMode.version,
                        child: Text('Version WSL'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _sort = v!),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.create_new_folder, size: 18),
                    label: const Text('Groupe'),
                    onPressed: () => _showCreateGroupDialog(context),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nouvelle instance'),
                    onPressed: () => context.go('/create'),
                  ),
                ],
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: controls,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  controls,
                ],
              );
            },
          ),
        ),
        Expanded(
          child: instances.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 8),
                  Text('Erreur : $e'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        ref.read(instancesProvider.notifier).refresh(),
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            ),
            data: (list) {
              final groupsState =
                  groups.valueOrNull ?? InstanceGroupsState.empty();
              final filtered = list.where((i) {
                if (!i.name.toLowerCase().contains(_search.toLowerCase())) {
                  return false;
                }
                final stateOk = switch (_stateFilter) {
                  _StateFilter.all => true,
                  _StateFilter.running => i.state == WslInstanceState.running,
                  _StateFilter.stopped => i.state == WslInstanceState.stopped,
                };
                if (!stateOk) return false;
                if (_filterDocker || _filterPodman) {
                  final matchD = _filterDocker && (i.hasDocker == true);
                  final matchP = _filterPodman && (i.hasPodman == true);
                  if (!matchD && !matchP) return false;
                }
                return true;
              }).toList()
                ..sort(_comparator);

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.terminal, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        list.isEmpty
                            ? 'Aucune instance WSL trouvee'
                            : 'Aucun resultat pour "$_search"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return _GroupedGrid(
                instances: filtered,
                groupsState: groupsState,
                searchActive: _search.trim().isNotEmpty,
                onToggleGroup: (groupId) =>
                    ref.read(groupsProvider.notifier).toggleCollapsed(groupId),
                onRenameGroup: (group) =>
                    _showRenameGroupDialog(context, group),
                onDeleteGroup: (group) =>
                    _showDeleteGroupDialog(context, group),
                onMoveGroup: (groupId, direction) =>
                    ref.read(groupsProvider.notifier).move(groupId, direction),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau groupe'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom du groupe',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Creer'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name != null && name.trim().isNotEmpty) {
      await ref.read(groupsProvider.notifier).create(name);
    }
  }

  Future<void> _showRenameGroupDialog(
    BuildContext context,
    InstanceGroup group,
  ) async {
    final controller = TextEditingController(text: group.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le groupe'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom du groupe',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name != null && name.trim().isNotEmpty) {
      await ref.read(groupsProvider.notifier).rename(group.id, name);
    }
  }

  Future<void> _showDeleteGroupDialog(
    BuildContext context,
    InstanceGroup group,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe'),
        content: Text(
          'Supprimer "${group.name}" ? Les instances associees seront remises '
          'dans "Non classees".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(groupsProvider.notifier).delete(group.id);
    }
  }

  int _comparator(WslInstance a, WslInstance b) {
    switch (_sort) {
      case _SortMode.name:
        return a.name.compareTo(b.name);
      case _SortMode.state:
        return a.state.index.compareTo(b.state.index);
      case _SortMode.version:
        return a.version.index.compareTo(b.version.index);
    }
  }
}

class _GroupedGrid extends StatelessWidget {
  final List<WslInstance> instances;
  final InstanceGroupsState groupsState;
  final bool searchActive;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<InstanceGroup> onRenameGroup;
  final ValueChanged<InstanceGroup> onDeleteGroup;
  final void Function(String groupId, int direction) onMoveGroup;

  const _GroupedGrid({
    required this.instances,
    required this.groupsState,
    required this.searchActive,
    required this.onToggleGroup,
    required this.onRenameGroup,
    required this.onDeleteGroup,
    required this.onMoveGroup,
  });

  @override
  Widget build(BuildContext context) {
    final validGroupIds = groupsState.groups.map((g) => g.id).toSet();
    final byGroup = <String?, List<WslInstance>>{};
    for (final instance in instances) {
      final groupId = groupsState.assignments[instance.name];
      final effectiveGroupId = validGroupIds.contains(groupId) ? groupId : null;
      byGroup.putIfAbsent(effectiveGroupId, () => []).add(instance);
    }

    final sections = <Widget>[];
    for (var index = 0; index < groupsState.groups.length; index++) {
      final group = groupsState.groups[index];
      final groupInstances = byGroup[group.id] ?? [];
      if (groupInstances.isEmpty && searchActive) continue;
      sections.add(
        _GroupSection(
          group: group,
          title: group.name,
          count: groupInstances.length,
          collapsed: group.collapsed && !searchActive,
          onToggle: () => onToggleGroup(group.id),
          onRename: () => onRenameGroup(group),
          onDelete: () => onDeleteGroup(group),
          onMoveUp: index == 0 ? null : () => onMoveGroup(group.id, -1),
          onMoveDown: index == groupsState.groups.length - 1
              ? null
              : () => onMoveGroup(group.id, 1),
          instances: groupInstances,
        ),
      );
    }

    final ungrouped = byGroup[null] ?? [];
    if (ungrouped.isNotEmpty) {
      sections.add(
        _GroupSection(
          title: 'Non classees',
          count: ungrouped.length,
          collapsed: false,
          instances: ungrouped,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: sections,
    );
  }
}

class _GroupSection extends StatelessWidget {
  final InstanceGroup? group;
  final String title;
  final int count;
  final bool collapsed;
  final VoidCallback? onToggle;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final List<WslInstance> instances;

  const _GroupSection({
    this.group,
    required this.title,
    required this.count,
    required this.collapsed,
    required this.instances,
    this.onToggle,
    this.onRename,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onToggle != null)
                IconButton(
                  tooltip: collapsed ? 'Deplier' : 'Replier',
                  onPressed: onToggle,
                  icon: Icon(
                    collapsed
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_down,
                  ),
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (group != null)
                PopupMenuButton<_GroupAction>(
                  tooltip: 'Administrer le groupe',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (action) {
                    switch (action) {
                      case _GroupAction.rename:
                        onRename?.call();
                      case _GroupAction.delete:
                        onDelete?.call();
                      case _GroupAction.moveUp:
                        onMoveUp?.call();
                      case _GroupAction.moveDown:
                        onMoveDown?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _GroupAction.rename,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit, size: 18),
                        title: Text('Renommer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _GroupAction.moveUp,
                      enabled: onMoveUp != null,
                      child: const ListTile(
                        dense: true,
                        leading: Icon(Icons.arrow_upward, size: 18),
                        title: Text('Monter'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _GroupAction.moveDown,
                      enabled: onMoveDown != null,
                      child: const ListTile(
                        dense: true,
                        leading: Icon(Icons.arrow_downward, size: 18),
                        title: Text('Descendre'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: _GroupAction.delete,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.delete_outline, size: 18),
                        title: Text('Supprimer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (!collapsed) ...[
            const SizedBox(height: 8),
            if (instances.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 8, bottom: 12),
                child: Text(
                  'Aucune instance dans ce groupe',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = math.max(
                    1,
                    math.min(5, (constraints.maxWidth / 280).floor()),
                  );
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 168,
                    ),
                    itemCount: instances.length,
                    itemBuilder: (_, index) =>
                        InstanceCard(instance: instances[index]),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

enum _GroupAction { rename, delete, moveUp, moveDown }

enum _SortMode { name, state, version }

enum _StateFilter { all, running, stopped }
