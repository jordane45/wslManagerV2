import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/monitoring_service.dart';
import '../services/wsl_service.dart';
import 'config_provider.dart';

final monitoringProvider = StreamProvider<Map<String, MonitoringData>>((ref) {
  final config = ref.watch(configProvider);
  final interval = config.valueOrNull?.monitoringIntervalSeconds ?? 5;
  return MonitoringService.instance.stream(
    interval: Duration(seconds: interval),
    getInstances: () => WslService.instance.listInstances(logCommand: false),
  );
});
