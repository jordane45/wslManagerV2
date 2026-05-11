import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ConfigNotifier extends AsyncNotifier<AppConfig> {
  @override
  Future<AppConfig> build() async {
    final templatesDir = await StorageService.instance.getTemplatesDir();
    final snapshotsDir = await StorageService.instance.getSnapshotsDir();
    final saved = await StorageService.instance.readJson(
      kConfigFile,
      AppConfig.fromJson,
    );
    return saved ??
        AppConfig(templatesDir: templatesDir, snapshotsDir: snapshotsDir);
  }

  Future<void> save(AppConfig config) async {
    await StorageService.instance.writeJson(kConfigFile, config.toJson());
    state = AsyncData(config);
  }
}

final configProvider = AsyncNotifierProvider<ConfigNotifier, AppConfig>(
  ConfigNotifier.new,
);
