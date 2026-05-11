class InstanceGroup {
  final String id;
  final String name;
  final int order;
  final bool collapsed;

  const InstanceGroup({
    required this.id,
    required this.name,
    required this.order,
    this.collapsed = false,
  });

  factory InstanceGroup.fromJson(Map<String, dynamic> json) => InstanceGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        order: json['order'] as int? ?? 0,
        collapsed: json['collapsed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
        'collapsed': collapsed,
      };

  InstanceGroup copyWith({
    String? name,
    int? order,
    bool? collapsed,
  }) {
    return InstanceGroup(
      id: id,
      name: name ?? this.name,
      order: order ?? this.order,
      collapsed: collapsed ?? this.collapsed,
    );
  }
}

class InstanceGroupsState {
  final List<InstanceGroup> groups;
  final Map<String, String> assignments;

  const InstanceGroupsState({
    required this.groups,
    required this.assignments,
  });

  factory InstanceGroupsState.empty() => const InstanceGroupsState(
        groups: [],
        assignments: {},
      );

  factory InstanceGroupsState.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List<dynamic>? ?? [];
    final rawAssignments =
        json['assignments'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return InstanceGroupsState(
      groups: rawGroups
          .whereType<Map<String, dynamic>>()
          .map(InstanceGroup.fromJson)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      assignments: rawAssignments.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'groups': groups.map((g) => g.toJson()).toList(),
        'assignments': assignments,
      };

  InstanceGroupsState copyWith({
    List<InstanceGroup>? groups,
    Map<String, String>? assignments,
  }) {
    return InstanceGroupsState(
      groups: groups ?? this.groups,
      assignments: assignments ?? this.assignments,
    );
  }
}
