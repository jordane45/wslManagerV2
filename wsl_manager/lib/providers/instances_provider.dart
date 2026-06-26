import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/instance_metadata.dart';
import '../models/wsl_instance.dart';
import '../services/instance_metadata_service.dart';
import '../services/wsl_service.dart';

class InstancesNotifier extends AsyncNotifier<List<WslInstance>> {
  @override
  Future<List<WslInstance>> build() => _load();

  Future<List<WslInstance>> _load() async {
    final instances = await WslService.instance.listInstances();
    final metadata = await InstanceMetadataService.instance.loadAll();

    // Detect docker/podman for running instances in parallel
    final runningNames = instances
        .where((i) => i.state == WslInstanceState.running)
        .map((i) => i.name)
        .toList();
    final toolResults = await Future.wait(
      runningNames.map((n) => WslService.instance.detectInstalledTools(n)),
    );
    final toolMap = {
      for (var k = 0; k < runningNames.length; k++)
        runningNames[k]: toolResults[k],
    };
    // Persist detected values to metadata for stopped instances to read later.
    // Detection uses OR logic: a badge set by explicit install (true) is never
    // cleared by a negative detection result (dpkg might be unreliable/locked).
    for (final entry in toolMap.entries) {
      final meta = metadata[entry.key];
      final detected = entry.value;
      // Merge: detection can only upgrade null/false → true, never true → false.
      final mergedDocker = detected.hasDocker ? true : meta?.hasDocker;
      final mergedPodman = detected.hasPodman ? true : meta?.hasPodman;
      if (meta?.hasDocker != mergedDocker || meta?.hasPodman != mergedPodman) {
        final updated = (meta ?? const InstanceMetadata()).copyWith(
          hasDocker: mergedDocker,
          hasPodman: mergedPodman,
        );
        await InstanceMetadataService.instance.save(entry.key, updated);
        metadata[entry.key] = updated;
      }
    }

    final diskInfoList = await Future.wait(
      instances.map((i) => WslService.instance.getInstanceDiskInfo(i.name)),
    );
    final diskMap = {
      for (var k = 0; k < instances.length; k++)
        instances[k].name: diskInfoList[k],
    };

    return instances.map((i) {
      final meta = metadata[i.name];
      final disk = diskMap[i.name];
      return i.copyWith(
        description: meta == null || meta.description.isEmpty ? null : meta.description,
        defaultWorkDir: meta == null || meta.defaultWorkDir.isEmpty ? null : meta.defaultWorkDir,
        hasDocker: meta?.hasDocker,
        hasPodman: meta?.hasPodman,
        vhdxPath: disk?.vhdxPath,
        diskSizeBytes: disk?.sizeBytes,
      );
    }).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> start(String name) async {
    await WslService.instance.startInstance(name);
    await refresh();
  }

  Future<void> stop(String name) async {
    await WslService.instance.stopInstance(name);
    await refresh();
  }

  Future<void> delete(String name) async {
    await WslService.instance.deleteInstance(name);
    await InstanceMetadataService.instance.delete(name);
    await refresh();
  }

  Future<void> setDefault(String name) async {
    await WslService.instance.setDefaultDistro(name);
    await refresh();
  }
}

final instancesProvider =
    AsyncNotifierProvider<InstancesNotifier, List<WslInstance>>(
  InstancesNotifier.new,
);
