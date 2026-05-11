import 'package:uuid/uuid.dart';

import '../models/instance_group.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class GroupService {
  static GroupService? _instance;
  static GroupService get instance => _instance ??= GroupService._();
  GroupService._();

  final _uuid = const Uuid();

  Future<InstanceGroupsState> load() async {
    final state = await StorageService.instance.readJson(
      kGroupsFile,
      InstanceGroupsState.fromJson,
    );
    return state ?? InstanceGroupsState.empty();
  }

  Future<void> save(InstanceGroupsState state) async {
    await StorageService.instance.writeJson(kGroupsFile, state.toJson());
  }

  Future<InstanceGroupsState> createGroup(String name) async {
    final state = await load();
    final trimmed = name.trim();
    if (trimmed.isEmpty) return state;

    final group = InstanceGroup(
      id: _uuid.v4(),
      name: trimmed,
      order: state.groups.length,
    );
    final next = state.copyWith(groups: [...state.groups, group]);
    await save(next);
    return next;
  }

  Future<InstanceGroupsState> renameGroup(String groupId, String name) async {
    final state = await load();
    final trimmed = name.trim();
    if (trimmed.isEmpty) return state;

    final groups = state.groups
        .map((group) =>
            group.id == groupId ? group.copyWith(name: trimmed) : group)
        .toList();
    final next = state.copyWith(groups: _normalizeOrder(groups));
    await save(next);
    return next;
  }

  Future<InstanceGroupsState> deleteGroup(String groupId) async {
    final state = await load();
    final groups = state.groups.where((group) => group.id != groupId).toList();
    final assignments = Map<String, String>.from(state.assignments)
      ..removeWhere((_, assignedGroupId) => assignedGroupId == groupId);

    final next = state.copyWith(
      groups: _normalizeOrder(groups),
      assignments: assignments,
    );
    await save(next);
    return next;
  }

  Future<InstanceGroupsState> moveGroup(String groupId, int direction) async {
    final state = await load();
    final groups = [...state.groups]
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = groups.indexWhere((group) => group.id == groupId);
    if (index < 0) return state;

    final targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= groups.length) return state;

    final group = groups.removeAt(index);
    groups.insert(targetIndex, group);

    final next = state.copyWith(groups: _normalizeOrder(groups));
    await save(next);
    return next;
  }

  Future<InstanceGroupsState> assignInstance(
    String instanceName,
    String? groupId,
  ) async {
    final state = await load();
    final assignments = Map<String, String>.from(state.assignments);
    if (groupId == null || groupId.isEmpty) {
      assignments.remove(instanceName);
    } else {
      assignments[instanceName] = groupId;
    }
    final next = state.copyWith(assignments: assignments);
    await save(next);
    return next;
  }

  Future<InstanceGroupsState> toggleCollapsed(String groupId) async {
    final state = await load();
    final groups = state.groups
        .map((group) => group.id == groupId
            ? group.copyWith(collapsed: !group.collapsed)
            : group)
        .toList();
    final next = state.copyWith(groups: groups);
    await save(next);
    return next;
  }

  List<InstanceGroup> _normalizeOrder(List<InstanceGroup> groups) {
    return [
      for (var i = 0; i < groups.length; i++) groups[i].copyWith(order: i),
    ];
  }
}
