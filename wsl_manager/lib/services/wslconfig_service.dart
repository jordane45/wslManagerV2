import 'dart:io';

class WslconfigService {
  WslconfigService._();
  static final instance = WslconfigService._();

  static const _knownSections = {
    'wsl2', 'network', 'interop', 'user', 'automount', 'experimental',
  };

  String get _path {
    final userProfile = Platform.environment['USERPROFILE'] ??
        '${Platform.environment['HOMEDRIVE']}${Platform.environment['HOMEPATH']}';
    return '$userProfile\\.wslconfig';
  }

  String get resolvedPath => _path;

  Future<String> readWslconfig() async {
    final file = File(_path);
    if (!await file.exists()) return '';
    return file.readAsString();
  }

  Future<void> writeWslconfig(String content) async {
    await File(_path).writeAsString(content);
  }

  /// Returns a warning message if suspicious lines are found, null otherwise.
  String? validate(String content) {
    final lines = content.split('\n');
    final invalidLines = <int>[];
    String? currentSection;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }
      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1).toLowerCase();
        if (!_knownSections.contains(currentSection)) {
          invalidLines.add(i + 1);
        }
        continue;
      }
      if (!line.contains('=')) {
        invalidLines.add(i + 1);
      }
    }

    if (invalidLines.isEmpty) return null;
    return 'Lignes suspectes (${invalidLines.join(', ')}) — vérifiez la syntaxe.';
  }
}
