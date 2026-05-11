import 'dart:io';

class UacService {
  static UacService? _instance;
  static UacService get instance => _instance ??= UacService._();
  UacService._();

  bool isElevated() {
    if (!Platform.isWindows) return true;
    try {
      final result = Process.runSync(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          '([Security.Principal.WindowsPrincipal]'
              '[Security.Principal.WindowsIdentity]::GetCurrent())'
              '.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)',
        ],
      );
      return (result.stdout as String).trim().toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> relaunchAsAdmin() async {
    final exe = Platform.resolvedExecutable;
    await Process.run(
      'powershell',
      ['-NoProfile', '-Command', 'Start-Process -FilePath "$exe" -Verb RunAs'],
    );
    exit(0);
  }
}
