class WslSnapshot {
  final String id;
  final String name;
  final String description;
  final String instanceName;
  final String tarPath;
  final int sizeBytes;
  final DateTime createdAt;

  const WslSnapshot({
    required this.id,
    required this.name,
    required this.description,
    required this.instanceName,
    required this.tarPath,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory WslSnapshot.fromJson(Map<String, dynamic> json) => WslSnapshot(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        instanceName: json['instance_name'] as String,
        tarPath: json['tar_path'] as String,
        sizeBytes: json['size_bytes'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'instance_name': instanceName,
        'tar_path': tarPath,
        'size_bytes': sizeBytes,
        'created_at': createdAt.toIso8601String(),
      };
}
