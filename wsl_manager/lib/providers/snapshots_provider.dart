import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/snapshot.dart';
import '../services/snapshot_service.dart';

class SnapshotsNotifier extends AsyncNotifier<List<WslSnapshot>> {
  @override
  Future<List<WslSnapshot>> build() => SnapshotService.instance.listSnapshots();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(SnapshotService.instance.listSnapshots);
  }

  Future<void> delete(String id) async {
    await SnapshotService.instance.deleteSnapshot(id);
    await refresh();
  }
}

final snapshotsProvider =
    AsyncNotifierProvider<SnapshotsNotifier, List<WslSnapshot>>(
  SnapshotsNotifier.new,
);
