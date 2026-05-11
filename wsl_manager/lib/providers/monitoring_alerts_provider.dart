import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_config.dart';
import '../services/monitoring_service.dart';
import '../services/windows_notification_service.dart';
import 'config_provider.dart';
import 'monitoring_provider.dart';

class MonitoringAlertsNotifier extends Notifier<void> {
  final Map<String, DateTime> _lastAlerts = {};

  @override
  void build() {
    ref.listen<AsyncValue<Map<String, MonitoringData>>>(
      monitoringProvider,
      (_, next) {
        final data = next.valueOrNull;
        final config = ref.read(configProvider).valueOrNull;
        if (data == null || config == null) return;
        _checkMetrics(data, config);
      },
    );
  }

  void _checkMetrics(Map<String, MonitoringData> data, AppConfig config) {
    if (!config.resourceAlertsEnabled) return;

    for (final entry in data.entries) {
      final metric = entry.value;
      final cpuExceeded = metric.cpuPercent >= config.cpuAlertThreshold;
      final ramExceeded = metric.ramPercent >= config.ramAlertThreshold;
      if (!cpuExceeded && !ramExceeded) continue;
      if (!_canNotify(entry.key, config.alertCooldownMinutes)) continue;

      final details = [
        if (cpuExceeded)
          'CPU ${metric.cpuPercent.toStringAsFixed(1)}% '
              '(seuil ${config.cpuAlertThreshold}%)',
        if (ramExceeded)
          'RAM ${metric.ramPercent.toStringAsFixed(1)}% '
              '(seuil ${config.ramAlertThreshold}%)',
      ].join(' - ');

      _lastAlerts[entry.key] = DateTime.now();
      WindowsNotificationService.instance
          .showToast(
            title: 'Alerte ressources WSL',
            message: '${entry.key} : $details',
          )
          .catchError((_) {});
    }
  }

  bool _canNotify(String instanceName, int cooldownMinutes) {
    final lastAlert = _lastAlerts[instanceName];
    if (lastAlert == null) return true;
    return DateTime.now().difference(lastAlert) >=
        Duration(minutes: cooldownMinutes);
  }
}

final monitoringAlertsProvider =
    NotifierProvider<MonitoringAlertsNotifier, void>(
  MonitoringAlertsNotifier.new,
);
