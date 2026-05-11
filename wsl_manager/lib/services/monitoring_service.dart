import 'dart:io';
import '../models/wsl_instance.dart';

class MonitoringData {
  final double cpuPercent;
  final double ramPercent;
  final int ramUsedMb;
  final int ramTotalMb;
  final String? ipAddress;

  const MonitoringData({
    required this.cpuPercent,
    required this.ramPercent,
    required this.ramUsedMb,
    required this.ramTotalMb,
    this.ipAddress,
  });
}

class _CpuReading {
  final int total;
  final int idle;
  const _CpuReading(this.total, this.idle);
}

class MonitoringService {
  static MonitoringService? _instance;
  static MonitoringService get instance => _instance ??= MonitoringService._();
  MonitoringService._();

  Stream<Map<String, MonitoringData>> stream({
    required Duration interval,
    required Future<List<WslInstance>> Function() getInstances,
  }) {
    return Stream.periodic(interval).asyncMap((_) async {
      final instances = await getInstances();
      final running =
          instances.where((i) => i.state == WslInstanceState.running);
      final results = <String, MonitoringData>{};
      for (final inst in running) {
        try {
          results[inst.name] = await _getMetrics(inst.name);
        } catch (_) {
          // instance may have stopped
        }
      }
      return results;
    });
  }

  Future<MonitoringData> _getMetrics(String instanceName) async {
    final cpu = await _getCpuPercent(instanceName);
    final (usedMb, totalMb) = await _getRamInfo(instanceName);
    final ipAddress = await _getIpAddress(instanceName);
    final ramPct = totalMb > 0 ? 100.0 * usedMb / totalMb : 0.0;
    return MonitoringData(
      cpuPercent: cpu,
      ramPercent: ramPct,
      ramUsedMb: usedMb,
      ramTotalMb: totalMb,
      ipAddress: ipAddress,
    );
  }

  Future<double> _getCpuPercent(String instanceName) async {
    final r1 = await _readCpu(instanceName);
    await Future.delayed(const Duration(milliseconds: 500));
    final r2 = await _readCpu(instanceName);
    final deltaIdle = r2.idle - r1.idle;
    final deltaTotal = r2.total - r1.total;
    if (deltaTotal == 0) return 0.0;
    return 100.0 * (1.0 - deltaIdle / deltaTotal);
  }

  Future<_CpuReading> _readCpu(String instanceName) async {
    final result = await Process.run(
      'wsl',
      ['-d', instanceName, '--', 'bash', '-c', 'cat /proc/stat'],
      runInShell: true,
    );
    final output = result.stdout as String? ?? '';
    final line = output.split('\n').firstWhere(
          (l) => l.startsWith('cpu '),
          orElse: () => '',
        );
    if (line.isEmpty) return const _CpuReading(1, 0);
    final parts = line.trim().split(RegExp(r'\s+'));
    final values = parts.skip(1).map(int.tryParse).whereType<int>().toList();
    if (values.length < 4) return const _CpuReading(1, 0);
    final idle = values[3];
    final total = values.fold(0, (a, b) => a + b);
    return _CpuReading(total, idle);
  }

  Future<(int usedMb, int totalMb)> _getRamInfo(String instanceName) async {
    final result = await Process.run(
      'wsl',
      ['-d', instanceName, '--', 'bash', '-c', 'cat /proc/meminfo'],
      runInShell: true,
    );
    final output = result.stdout as String? ?? '';
    int memTotal = _extractKb(output, 'MemTotal');
    int memAvailable = _extractKb(output, 'MemAvailable');
    final usedKb = memTotal - memAvailable;
    return (usedKb ~/ 1024, memTotal ~/ 1024);
  }

  Future<String?> _getIpAddress(String instanceName) async {
    final result = await Process.run(
      'wsl',
      ['-d', instanceName, '--', 'hostname', '-I'],
      runInShell: true,
    );
    if (result.exitCode != 0) return null;
    final output = (result.stdout as String? ?? '').trim();
    if (output.isEmpty) return null;
    final addresses = output.split(RegExp(r'\s+'));
    return addresses.isEmpty ? null : addresses.first;
  }

  int _extractKb(String content, String key) {
    final match = RegExp('$key:\\s+(\\d+)\\s+kB').firstMatch(content);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }
}
