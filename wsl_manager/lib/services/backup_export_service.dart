import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../utils/constants.dart';
import 'storage_service.dart';

class BackupExportService {
  static BackupExportService? _instance;
  static BackupExportService get instance =>
      _instance ??= BackupExportService._();
  BackupExportService._();

  Future<void> exportFullConfiguration(String destinationPath) async {
    final encoder = ZipFileEncoder();
    encoder.create(destinationPath);
    try {
      await _addConfigFiles(encoder);
      await _addDirectory(
        encoder,
        Directory(await StorageService.instance.getTemplatesDir()),
        'templates',
      );
      await _addDirectory(
        encoder,
        Directory(await StorageService.instance.getSnapshotsDir()),
        'snapshots',
      );
      _addManifest(encoder);
    } finally {
      encoder.close();
    }
  }

  Future<void> _addConfigFiles(ZipFileEncoder encoder) async {
    final appDataDir = await StorageService.instance.getAppDataDir();
    for (final filename in [
      kConfigFile,
      kTemplatesFile,
      kSnapshotsFile,
      kGroupsFile,
    ]) {
      final file = File(p.join(appDataDir.path, filename));
      if (file.existsSync()) {
        encoder.addFile(file, p.posix.join('config', filename));
      }
    }
  }

  Future<void> _addDirectory(
    ZipFileEncoder encoder,
    Directory directory,
    String archiveRoot,
  ) async {
    if (!directory.existsSync()) return;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: directory.path);
      final zipPath = p.posix.join(
        archiveRoot,
        relative.replaceAll(r'\', '/'),
      );
      encoder.addFile(entity, zipPath);
    }
  }

  void _addManifest(ZipFileEncoder encoder) {
    final manifest = {
      'version': 1,
      'application': kAppName,
      'created_at': DateTime.now().toIso8601String(),
      'content': {
        'config': [kConfigFile, kTemplatesFile, kSnapshotsFile, kGroupsFile],
        'directories': ['templates', 'snapshots'],
      },
    };
    final bytes =
        utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest));
    encoder.addArchiveFile(ArchiveFile('manifest.json', bytes.length, bytes));
  }
}
