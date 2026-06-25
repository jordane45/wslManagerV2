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
    // Persist detected values to metadata for stopped instances to read later
    for (final entry in toolMap.entries) {
      final meta = metadata[entry.key];
      final detected = entry.value;
      if (meta == null ||
          meta.hasDocker != detected.hasDocker ||
          meta.hasPodman != detected.hasPodman) {
        final updated = (meta ?? const InstanceMetadata()).copyWith(
          hasDocker: detected.hasDocker,
          hasPodman: detected.hasPodman,
        );
        await InstanceMetadataService.instance.save(entry.key, updated);
        metadata[entry.key] = updated;
      }
    }

    return instances.map((i) {
      final meta = metadata[i.name];
      if (meta == null) return i;
      return i.copyWith(
        description: meta.description.isEmpty ? null : meta.description,
        defaultWorkDir: meta.defaultWorkDir.isEmpty ? null : meta.defaultWorkDir,
        hasDocker: meta.hasDocker,
        hasPodman: meta.hasPodman,
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
