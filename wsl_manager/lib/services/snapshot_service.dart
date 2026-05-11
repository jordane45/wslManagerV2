import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/snapshot.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'wsl_service.dart';

class SnapshotService {
  static SnapshotService? _instance;
  static SnapshotService get instance => _instance ??= SnapshotService._();
  SnapshotService._();

  final _uuid = const Uuid();

  Future<List<WslSnapshot>> listSnapshots() async {
    final data = await StorageService.instance.readJson(kSnapshotsFile, (m) => m);
    if (data == null) return [];
    return (data['snapshots'] as List? ?? [])
        .map((e) => WslSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WslSnapshot> createSnapshot(
    String instanceName,
    String snapshotName,
    String description,
  ) async {
    final dir = await StorageService.instance.getSnapshotsDir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tarPath = '$dir\\${instanceName}_${snapshotName}_$ts.tar';
    await WslService.instance.exportInstance(instanceName, tarPath);
    final size = File(tarPath).lengthSync();
    final snapshot = WslSnapshot(
      id: _uuid.v4(),
      name: snapshotName,
      description: description,
      instanceName: instanceName,
      tarPath: tarPath,
      sizeBytes: size,
      createdAt: DateTime.now(),
    );
    await _save(await listSnapshots()..add(snapshot));
    return snapshot;
  }

  Future<void> restoreSnapshot(
    String snapshotId,
    String targetInstanceName,
    String installDir,
  ) async {
    final list = await listSnapshots();
    final snapshot = list.firstWhere((s) => s.id == snapshotId);
    await WslService.instance.deleteInstance(targetInstanceName);
    await WslService.instance.importInstance(
      targetInstanceName,
      installDir,
      snapshot.tarPath,
    );
  }

  Future<void> deleteSnapshot(String id) async {
    final list = await listSnapshots();
    final snapshot = list.firstWhere((s) => s.id == id);
    final file = File(snapshot.tarPath);
    if (file.existsSync()) await file.delete();
    await _save(list.where((s) => s.id != id).toList());
  }

  Future<void> _save(List<WslSnapshot> snapshots) async {
    await StorageService.instance.writeJson(kSnapshotsFile, {
      'version': kJsonVersion,
      'snapshots': snapshots.map((s) => s.toJson()).toList(),
    });
  }
}
