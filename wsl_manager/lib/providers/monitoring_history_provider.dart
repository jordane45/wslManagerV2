import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/monitoring_service.dart';
import 'monitoring_provider.dart';

class MonitoringSample {
  final DateTime timestamp;
  final double cpuPercent;
  final double ramPercent;

  const MonitoringSample({
    required this.timestamp,
    required this.cpuPercent,
    required this.ramPercent,
  });
}

class MonitoringHistoryNotifier
    extends Notifier<Map<String, List<MonitoringSample>>> {
  static const historyWindow = Duration(minutes: 5);

  @override
  Map<String, List<MonitoringSample>> build() {
    ref.listen<AsyncValue<Map<String, MonitoringData>>>(
      monitoringProvider,
      (_, next) {
        final data = next.valueOrNull;
        if (data == null || data.isEmpty) return;
        _append(data);
      },
    );
    return const {};
  }

  void _append(Map<String, MonitoringData> data) {
    final now = DateTime.now();
    final cutoff = now.subtract(historyWindow);
    final nextState = {
      for (final entry in state.entries)
        entry.key: entry.value
            .where((sample) => sample.timestamp.isAfter(cutoff))
            .toList(),
    };

    for (final entry in data.entries) {
      final samples = nextState[entry.key] ?? <MonitoringSample>[];
      samples.add(
        MonitoringSample(
          timestamp: now,
          cpuPercent: entry.value.cpuPercent,
          ramPercent: entry.value.ramPercent,
        ),
      );
      nextState[entry.key] = samples
          .where((sample) => sample.timestamp.isAfter(cutoff))
          .toList(growable: false);
    }

    state = nextState;
  }
}

final monitoringHistoryProvider = NotifierProvider<MonitoringHistoryNotifier,
    Map<String, List<MonitoringSample>>>(
  MonitoringHistoryNotifier.new,
);
