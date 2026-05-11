import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  Directory? _appDataDir;

  Future<Directory> getAppDataDir() async {
    if (_appDataDir != null) return _appDataDir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'WSLManager'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    _appDataDir = dir;
    return dir;
  }

  Future<String> getTemplatesDir() async {
    return _ensureDir(await _configuredDir('templates_dir', 'templates'));
  }

  Future<String> getSnapshotsDir() async {
    return _ensureDir(await _configuredDir('snapshots_dir', 'snapshots'));
  }

  Future<String> _configuredDir(String key, String fallbackName) async {
    final config = await readJson(kConfigFile, (m) => m);
    final configured = config?[key];
    if (configured is String && configured.trim().isNotEmpty) {
      return configured;
    }
    return p.join(Directory.current.path, fallbackName);
  }

  Future<String> _ensureDir(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<T?> readJson<T>(
    String filename,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final dir = await getAppDataDir();
      final file = File(p.join(dir.path, filename));
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String filename, Map<String, dynamic> data) async {
    final dir = await getAppDataDir();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(jsonEncode(data));
  }
}
