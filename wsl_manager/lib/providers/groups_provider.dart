import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/instance_group.dart';
import '../services/group_service.dart';

class GroupsNotifier extends AsyncNotifier<InstanceGroupsState> {
  @override
  Future<InstanceGroupsState> build() => GroupService.instance.load();

  Future<void> create(String name) async {
    state = AsyncData(await GroupService.instance.createGroup(name));
  }

  Future<void> rename(String groupId, String name) async {
    state = AsyncData(await GroupService.instance.renameGroup(groupId, name));
  }

  Future<void> delete(String groupId) async {
    state = AsyncData(await GroupService.instance.deleteGroup(groupId));
  }

  Future<void> move(String groupId, int direction) async {
    state =
        AsyncData(await GroupService.instance.moveGroup(groupId, direction));
  }

  Future<void> assign(String instanceName, String? groupId) async {
    state = AsyncData(
      await GroupService.instance.assignInstance(instanceName, groupId),
    );
  }

  Future<void> toggleCollapsed(String groupId) async {
    state = AsyncData(await GroupService.instance.toggleCollapsed(groupId));
  }
}

final groupsProvider =
    AsyncNotifierProvider<GroupsNotifier, InstanceGroupsState>(
  GroupsNotifier.new,
);
