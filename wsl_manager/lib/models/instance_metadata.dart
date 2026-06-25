class InstanceMetadata {
  final String description;
  final String defaultWorkDir;

  const InstanceMetadata({
    this.description = '',
    this.defaultWorkDir = '',
  });

  factory InstanceMetadata.fromJson(Map<String, dynamic> json) =>
      InstanceMetadata(
        description: json['description'] as String? ?? '',
        defaultWorkDir: json['default_work_dir'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'default_work_dir': defaultWorkDir,
      };

  InstanceMetadata copyWith({String? description, String? defaultWorkDir}) =>
      InstanceMetadata(
        description: description ?? this.description,
        defaultWorkDir: defaultWorkDir ?? this.defaultWorkDir,
      );
}
