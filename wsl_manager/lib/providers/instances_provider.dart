import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wsl_instance.dart';
import '../services/wsl_service.dart';

class InstancesNotifier extends AsyncNotifier<List<WslInstance>> {
  @override
  Future<List<WslInstance>> build() => WslService.instance.listInstances();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(WslService.instance.listInstances);
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
