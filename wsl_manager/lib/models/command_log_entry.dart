class CommandLogEntry {
  final String id;
  final String executable;
  final List<String> arguments;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? exitCode;
  final String stdout;
  final String stderr;

  const CommandLogEntry({
    required this.id,
    required this.executable,
    required this.arguments,
    required this.startedAt,
    this.finishedAt,
    this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  bool get isRunning => finishedAt == null;
  bool get succeeded => exitCode == 0;
  String get output => [stdout.trim(), stderr.trim()]
      .where((part) => part.isNotEmpty)
      .join('\n\n');

  String get commandLine {
    return [executable, ...arguments].map(_quote).join(' ');
  }

  Duration? get duration {
    final end = finishedAt;
    if (end == null) return null;
    return end.difference(startedAt);
  }

  CommandLogEntry copyWith({
    DateTime? finishedAt,
    int? exitCode,
    String? stdout,
    String? stderr,
  }) {
    return CommandLogEntry(
      id: id,
      executable: executable,
      arguments: arguments,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      exitCode: exitCode ?? this.exitCode,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'executable': executable,
        'arguments': arguments,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'exitCode': exitCode,
        'stdout': stdout,
        'stderr': stderr,
      };

  factory CommandLogEntry.fromJson(Map<String, dynamic> json) {
    return CommandLogEntry(
      id: json['id'] as String? ?? '',
      executable: json['executable'] as String? ?? '',
      arguments: (json['arguments'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      finishedAt: _tryDate(json['finishedAt']),
      exitCode: json['exitCode'] as int?,
      stdout: json['stdout'] as String? ?? '',
      stderr: json['stderr'] as String? ?? '',
    );
  }

  static String _quote(String value) {
    if (value.isEmpty) return '""';
    if (!RegExp(r'\s|["]').hasMatch(value)) return value;
    return '"${value.replaceAll('"', r'\"')}"';
  }

  static DateTime? _tryDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
