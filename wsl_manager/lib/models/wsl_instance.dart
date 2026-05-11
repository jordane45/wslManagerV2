enum WslInstanceState { running, stopped, installing }

enum WslVersion { wsl1, wsl2 }

class WslInstance {
  final String name;
  final WslInstanceState state;
  final WslVersion version;
  final bool isDefault;
  double? cpuPercent;
  double? ramPercent;
  int? ramUsedMb;
  int? ramTotalMb;
  String? ipAddress;

  WslInstance({
    required this.name,
    required this.state,
    required this.version,
    required this.isDefault,
    this.cpuPercent,
    this.ramPercent,
    this.ramUsedMb,
    this.ramTotalMb,
    this.ipAddress,
  });

  WslInstance copyWith({
    WslInstanceState? state,
    bool? isDefault,
    double? cpuPercent,
    double? ramPercent,
    int? ramUsedMb,
    int? ramTotalMb,
    String? ipAddress,
  }) {
    return WslInstance(
      name: name,
      state: state ?? this.state,
      version: version,
      isDefault: isDefault ?? this.isDefault,
      cpuPercent: cpuPercent ?? this.cpuPercent,
      ramPercent: ramPercent ?? this.ramPercent,
      ramUsedMb: ramUsedMb ?? this.ramUsedMb,
      ramTotalMb: ramTotalMb ?? this.ramTotalMb,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }
}
