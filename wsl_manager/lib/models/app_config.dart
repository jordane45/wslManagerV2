class AppConfig {
  final String templatesDir;
  final String snapshotsDir;
  final int monitoringIntervalSeconds;
  final String theme;
  final String locale;
  final bool minimizeToTray;
  final bool launchAtStartup;
  final bool resourceAlertsEnabled;
  final int cpuAlertThreshold;
  final int ramAlertThreshold;
  final int alertCooldownMinutes;

  const AppConfig({
    required this.templatesDir,
    required this.snapshotsDir,
    this.monitoringIntervalSeconds = 5,
    this.theme = 'system',
    this.locale = 'system',
    this.minimizeToTray = true,
    this.launchAtStartup = false,
    this.resourceAlertsEnabled = false,
    this.cpuAlertThreshold = 90,
    this.ramAlertThreshold = 90,
    this.alertCooldownMinutes = 5,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        templatesDir: json['templates_dir'] as String,
        snapshotsDir: json['snapshots_dir'] as String,
        monitoringIntervalSeconds:
            json['monitoring_interval_seconds'] as int? ?? 5,
        theme: json['theme'] as String? ?? 'system',
        locale: json['locale'] as String? ?? 'system',
        minimizeToTray: json['minimize_to_tray'] as bool? ?? true,
        launchAtStartup: json['launch_at_startup'] as bool? ?? false,
        resourceAlertsEnabled:
            json['resource_alerts_enabled'] as bool? ?? false,
        cpuAlertThreshold: json['cpu_alert_threshold'] as int? ?? 90,
        ramAlertThreshold: json['ram_alert_threshold'] as int? ?? 90,
        alertCooldownMinutes: json['alert_cooldown_minutes'] as int? ?? 5,
      );

  Map<String, dynamic> toJson() => {
        'version': 1,
        'templates_dir': templatesDir,
        'snapshots_dir': snapshotsDir,
        'monitoring_interval_seconds': monitoringIntervalSeconds,
        'theme': theme,
        'locale': locale,
        'minimize_to_tray': minimizeToTray,
        'launch_at_startup': launchAtStartup,
        'resource_alerts_enabled': resourceAlertsEnabled,
        'cpu_alert_threshold': cpuAlertThreshold,
        'ram_alert_threshold': ramAlertThreshold,
        'alert_cooldown_minutes': alertCooldownMinutes,
      };

  AppConfig copyWith({
    String? templatesDir,
    String? snapshotsDir,
    int? monitoringIntervalSeconds,
    String? theme,
    String? locale,
    bool? minimizeToTray,
    bool? launchAtStartup,
    bool? resourceAlertsEnabled,
    int? cpuAlertThreshold,
    int? ramAlertThreshold,
    int? alertCooldownMinutes,
  }) =>
      AppConfig(
        templatesDir: templatesDir ?? this.templatesDir,
        snapshotsDir: snapshotsDir ?? this.snapshotsDir,
        monitoringIntervalSeconds:
            monitoringIntervalSeconds ?? this.monitoringIntervalSeconds,
        theme: theme ?? this.theme,
        locale: locale ?? this.locale,
        minimizeToTray: minimizeToTray ?? this.minimizeToTray,
        launchAtStartup: launchAtStartup ?? this.launchAtStartup,
        resourceAlertsEnabled:
            resourceAlertsEnabled ?? this.resourceAlertsEnabled,
        cpuAlertThreshold: cpuAlertThreshold ?? this.cpuAlertThreshold,
        ramAlertThreshold: ramAlertThreshold ?? this.ramAlertThreshold,
        alertCooldownMinutes: alertCooldownMinutes ?? this.alertCooldownMinutes,
      );
}
