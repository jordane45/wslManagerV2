class InstanceMetadata {
  final String description;
  final String defaultWorkDir;
  final bool? hasDocker;
  final bool? hasPodman;

  const InstanceMetadata({
    this.description = '',
    this.defaultWorkDir = '',
    this.hasDocker,
    this.hasPodman,
  });

  factory InstanceMetadata.fromJson(Map<String, dynamic> json) =>
      InstanceMetadata(
        description: json['description'] as String? ?? '',
        defaultWorkDir: json['default_work_dir'] as String? ?? '',
        hasDocker: json['has_docker'] as bool?,
        hasPodman: json['has_podman'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'default_work_dir': defaultWorkDir,
        if (hasDocker != null) 'has_docker': hasDocker,
        if (hasPodman != null) 'has_podman': hasPodman,
      };

  InstanceMetadata copyWith({
    String? description,
    String? defaultWorkDir,
    bool? hasDocker,
    bool? hasPodman,
  }) =>
      InstanceMetadata(
        description: description ?? this.description,
        defaultWorkDir: defaultWorkDir ?? this.defaultWorkDir,
        hasDocker: hasDocker ?? this.hasDocker,
        hasPodman: hasPodman ?? this.hasPodman,
      );
}
