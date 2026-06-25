import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/instance_metadata.dart';
import 'storage_service.dart';

const _kFile = 'instance_metadata.json';

class InstanceMetadataService {
  static InstanceMetadataService? _instance;
  static InstanceMetadataService get instance =>
      _instance ??= InstanceMetadataService._();
  InstanceMetadataService._();

  Map<String, InstanceMetadata>? _cache;

  Future<Map<String, InstanceMetadata>> loadAll() async {
    if (_cache != null) return _cache!;
    try {
      final dir = await StorageService.instance.getAppDataDir();
      final file = File(p.join(dir.path, _kFile));
      if (!file.existsSync()) return _cache = {};
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return _cache = {};
      _cache = raw.map((key, value) => MapEntry(
            key,
            InstanceMetadata.fromJson(value as Map<String, dynamic>),
          ));
      return _cache!;
    } catch (_) {
      return _cache = {};
    }
  }

  Future<InstanceMetadata> get(String instanceName) async {
    final all = await loadAll();
    return all[instanceName] ?? const InstanceMetadata();
  }

  Future<void> save(String instanceName, InstanceMetadata metadata) async {
    final all = await loadAll();
    all[instanceName] = metadata;
    await _persist(all);
  }

  Future<void> delete(String instanceName) async {
    final all = await loadAll();
    all.remove(instanceName);
    await _persist(all);
  }

  Future<void> rename(String oldName, String newName) async {
    final all = await loadAll();
    final meta = all.remove(oldName);
    if (meta != null) all[newName] = meta;
    await _persist(all);
  }

  void invalidate() => _cache = null;

  Future<void> _persist(Map<String, InstanceMetadata> data) async {
    try {
      final dir = await StorageService.instance.getAppDataDir();
      final file = File(p.join(dir.path, _kFile));
      await file.writeAsString(
        jsonEncode(data.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (_) {}
  }
}
