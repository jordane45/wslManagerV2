class WslTemplate {
  final String id;
  final String name;
  final String description;
  final String sourceDistro;
  final String tarPath;
  final int sizeBytes;
  final DateTime createdAt;
  final bool isOrphan;

  const WslTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.sourceDistro,
    required this.tarPath,
    required this.sizeBytes,
    required this.createdAt,
    this.isOrphan = false,
  });

  factory WslTemplate.fromJson(Map<String, dynamic> json) => WslTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        sourceDistro: json['source_distro'] as String? ?? '',
        tarPath: json['tar_path'] as String,
        sizeBytes: json['size_bytes'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'source_distro': sourceDistro,
        'tar_path': tarPath,
        'size_bytes': sizeBytes,
        'created_at': createdAt.toIso8601String(),
      };
}
