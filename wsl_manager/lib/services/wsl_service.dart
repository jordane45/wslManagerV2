import 'dart:io';
import '../models/wsl_instance.dart';
import '../models/wsl_port.dart';
import '../utils/wsl_parser.dart';
import 'command_log_service.dart';

class WslService {
  static WslService? _instance;
  static WslService get instance => _instance ??= WslService._();
  WslService._();

  Future<ProcessResult> _runWsl(
    List<String> arguments, {
    bool logCommand = true,
  }) async {
    final logEntry =
        logCommand ? CommandLogService.instance.start('wsl', arguments) : null;
    final result = await Process.run(
      'wsl',
      arguments,
      runInShell: true,
      stdoutEncoding: null,
      stderrEncoding: null,
    );
    if (logEntry != null) CommandLogService.instance.finish(logEntry, result);
    if (result.exitCode != 0) {
      throw WslCommandException(
          arguments, result.exitCode, _resultOutput(result));
    }
    return result;
  }

  String _resultOutput(ProcessResult result) {
    final stderr = _decodeProcessOutput(result.stderr).trim();
    if (stderr.isNotEmpty) return stderr;
    return _decodeProcessOutput(result.stdout).trim();
  }

  String _decodeProcessOutput(Object? output) {
    if (output is List<int>) return WslParser.decodeWslOutput(output);
    if (output is String) return output;
    return '';
  }

  Future<List<WslInstance>> listInstances({bool logCommand = true}) async {
    final result =
        await _runWsl(['--list', '--verbose'], logCommand: logCommand);
    final bytes = result.stdout as List<int>;
    final decoded = WslParser.decodeWslOutput(bytes);
    return WslParser.parseVerboseList(decoded);
  }

  Future<void> startInstance(String name) async {
    await _runWsl(['-d', name, '--', 'exit']);
  }

  Future<void> stopInstance(String name) async {
    await _runWsl(['--terminate', name]);
  }

  Future<void> deleteInstance(String name) async {
    await stopInstance(name);
    final arguments = ['--unregister', name];
    final logEntry = CommandLogService.instance.start('wsl', arguments);
    final result = await Process.run('wsl', arguments, runInShell: true);
    CommandLogService.instance.finish(logEntry, result);
    if (result.exitCode != 0) {
      throw WslCommandException(
          arguments, result.exitCode, _resultOutput(result));
    }
  }

  Future<void> exportInstance(
    String name,
    String tarPath, {
    void Function(double)? onProgress,
  }) async {
    if (onProgress != null) {
      _pollExportProgress(tarPath, onProgress);
    }
    await _runWsl(['--export', name, tarPath]);
  }

  void _pollExportProgress(String tarPath, void Function(double) onProgress) {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      final file = File(tarPath);
      if (!file.existsSync()) return true;
      final size = file.lengthSync();
      onProgress(size / (1024 * 1024 * 1024)); // rough GB progress
      return true;
    });
  }

  Future<void> installDistroWebDownload(
    String wslName, {
    void Function(double?)? onProgress,
  }) async {
    final args = [
      '--install', wslName,
      '--web-download',
      '--no-launch',
    ];
    final logEntry = CommandLogService.instance.start('wsl.exe', args);
    final process = await Process.start('wsl.exe', args, runInShell: false);

    final progressRe = RegExp(r'(\d+(?:\.\d+)?)%');
    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();

    process.stdout.listen((chunk) {
      final text = _decodeProcessOutput(chunk);
      stdoutBuf.write(text);
      final match = progressRe.firstMatch(text);
      if (match != null) {
        onProgress?.call(double.parse(match.group(1)!) / 100.0);
      }
    });
    process.stderr.listen((chunk) {
      stderrBuf.write(_decodeProcessOutput(chunk));
    });

    final exitCode = await process.exitCode;
    CommandLogService.instance.finish(
      logEntry,
      ProcessResult(process.pid, exitCode, stdoutBuf.toString(), stderrBuf.toString()),
    );

    if (exitCode != 0) {
      final output = stderrBuf.isNotEmpty ? stderrBuf.toString() : stdoutBuf.toString();
      throw WslCommandException(args, exitCode, output.trim());
    }
  }

  Future<void> importInstance(
    String name,
    String installDir,
    String tarPath,
  ) async {
    final dir = Directory(installDir);
    if (!dir.existsSync()) await dir.create(recursive: true);
    await _runWsl(['--import', name, installDir, tarPath, '--version', '2']);
  }

  Future<void> renameInstance(
    String oldName,
    String newName,
    String installDir,
  ) async {
    final tmp = '${Directory.systemTemp.path}\\wsl_rename_$oldName.tar';
    await stopInstance(oldName);
    await exportInstance(oldName, tmp);
    await importInstance(newName, installDir, tmp);
    await deleteInstance(oldName);
    await File(tmp).delete();
  }

  Future<void> duplicateInstance(
    String sourceName,
    String newName,
    String installDir,
  ) async {
    final tmp = '${Directory.systemTemp.path}\\wsl_dup_$sourceName.tar';
    await stopInstance(sourceName);
    await exportInstance(sourceName, tmp);
    await importInstance(newName, installDir, tmp);
    await File(tmp).delete();
  }

  Future<void> setDefaultDistro(String name) async {
    await _runWsl(['--set-default', name]);
  }

  Future<void> setVersion(String name, int version) async {
    await _runWsl(['--set-version', name, version.toString()]);
  }

  Future<void> setupUser(
    String instanceName,
    String username,
    String password,
  ) async {
    await _runWsl(
      [
        '-d',
        instanceName,
        '-u',
        'root',
        '--',
        'useradd',
        '-m',
        '-s',
        '/bin/bash',
        username
      ],
    );
    await _runWsl(
      [
        '-d',
        instanceName,
        '-u',
        'root',
        '--',
        'usermod',
        '-aG',
        'sudo',
        username
      ],
    );
    await _runWsl(
      [
        '-d',
        instanceName,
        '-u',
        'root',
        '--',
        'bash',
        '-c',
        'echo "$username:$password" | chpasswd'
      ],
    );
    final wslConf = '[user]\\ndefault=$username\\n';
    await _runWsl(
      [
        '-d',
        instanceName,
        '-u',
        'root',
        '--',
        'bash',
        '-c',
        'printf "$wslConf" > /etc/wsl.conf'
      ],
    );
    await stopInstance(instanceName);
    password = ''; // clear from memory
  }

  Future<String> readWslConf(String instanceName) async {
    final result = await _runWsl(
      ['-d', instanceName, '-u', 'root', '--', 'cat', '/etc/wsl.conf'],
    );
    return _decodeProcessOutput(result.stdout);
  }

  Future<void> writeWslConf(String instanceName, String content) async {
    final escaped = content.replaceAll("'", "'\\''");
    await _runWsl(
      [
        '-d',
        instanceName,
        '-u',
        'root',
        '--',
        'bash',
        '-c',
        "printf '%s' '$escaped' > /etc/wsl.conf"
      ],
    );
  }

  Future<void> resetPassword(
    String instanceName,
    String username,
    String newPassword,
  ) async {
    await _runWsl(
      [
        '-d',
        instanceName,
        '-u',
        'root',
        '--',
        'bash',
        '-c',
        'echo "$username:$newPassword" | chpasswd'
      ],
    );
    newPassword = '';
  }

  Future<List<WslPort>> listListeningPorts(String instanceName) async {
    final result = await _runWsl(
      [
        '-d',
        instanceName,
        '--',
        'sh',
        '-lc',
        'if command -v ss >/dev/null 2>&1; then ss -H -lntu; '
            'elif command -v netstat >/dev/null 2>&1; then netstat -lntu; '
            'else true; fi'
      ],
    );
    final output = _decodeProcessOutput(result.stdout);
    return _parseListeningPorts(output);
  }

  List<WslPort> _parseListeningPorts(String output) {
    final ports = <String, WslPort>{};
    for (final rawLine in output.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('Proto')) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;

      final protocolToken = parts.first.toLowerCase();
      final protocol = protocolToken.startsWith('tcp')
          ? 'tcp'
          : protocolToken.startsWith('udp')
              ? 'udp'
              : null;
      if (protocol == null) continue;

      final localAddress = _localAddressPart(parts);
      if (localAddress == null) continue;

      final parsed = _parseAddressPort(localAddress);
      if (parsed == null || parsed.port <= 0) continue;

      ports['$protocol/${parsed.port}/${parsed.address}'] = WslPort(
        protocol: protocol.toUpperCase(),
        address: parsed.address,
        port: parsed.port,
      );
    }

    final list = ports.values.toList()
      ..sort((a, b) {
        final portCompare = a.port.compareTo(b.port);
        if (portCompare != 0) return portCompare;
        return a.protocol.compareTo(b.protocol);
      });
    return list;
  }

  String? _localAddressPart(List<String> parts) {
    if (parts.length >= 5 && (parts[1] == 'LISTEN' || parts[1] == 'UNCONN')) {
      return parts[4];
    }
    if (parts.length >= 4 &&
        (parts.first.startsWith('tcp') || parts.first.startsWith('udp'))) {
      return parts[3];
    }
    return null;
  }

  ({String address, int port})? _parseAddressPort(String value) {
    final clean = value.replaceAll('[', '').replaceAll(']', '');
    final separator = clean.lastIndexOf(':');
    if (separator < 0 || separator == clean.length - 1) return null;
    final port = int.tryParse(clean.substring(separator + 1));
    if (port == null) return null;
    var address = clean.substring(0, separator);
    if (address.isEmpty || address == '*' || address == '::') {
      address = '0.0.0.0';
    }
    return (address: address, port: port);
  }

  Future<void> openInVsCode(String name, {String? workDir}) async {
    final remote = 'wsl+$name';
    if (workDir != null && workDir.isNotEmpty) {
      await Process.run(
        'code',
        ['--remote', remote, '--folder-uri', 'vscode-remote://$remote$workDir'],
        runInShell: true,
      );
    } else {
      await Process.run('code', ['--remote', remote], runInShell: true);
    }
  }

  Future<void> openInExplorer(String name) async {
    await Process.run('explorer.exe', [r'\\wsl.localhost\' + name],
        runInShell: true);
  }

  Future<void> openInExplorerPath(String windowsPath) async {
    await Process.run('explorer.exe', ['/select,', windowsPath],
        runInShell: false);
  }

  Future<void> openInTerminal(String name, {String? workDir}) async {
    final wslArgs = workDir != null && workDir.isNotEmpty
        ? ['wsl', '-d', name, '--cd', workDir]
        : ['wsl', '-d', name];
    final arguments = wslArgs;
    final logEntry = CommandLogService.instance.start('wt', arguments);
    final result = await Process.run('wt', arguments, runInShell: true);
    CommandLogService.instance.finish(logEntry, result);
    if (result.exitCode != 0) {
      final fallbackCmd = workDir != null && workDir.isNotEmpty
          ? 'wsl -d $name --cd "$workDir"'
          : 'wsl -d $name';
      final fallbackArguments = ['/c', 'start', '', 'cmd.exe', '/k', fallbackCmd];
      final fallbackLogEntry =
          CommandLogService.instance.start('cmd.exe', fallbackArguments);
      final fallbackResult = await Process.run(
        'cmd.exe',
        fallbackArguments,
        runInShell: true,
      );
      CommandLogService.instance.finish(fallbackLogEntry, fallbackResult);
    }
  }

  Future<int?> getDriveFreeBytes(String windowsPath) async {
    if (windowsPath.isEmpty) return null;
    final drive = windowsPath[0].toUpperCase();
    if (!RegExp(r'[A-Z]').hasMatch(drive)) return null;
    try {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile', '-NonInteractive', '-Command',
          "[System.IO.DriveInfo]::new('$drive').AvailableFreeSpace",
        ],
        runInShell: false,
      );
      return int.tryParse(result.stdout.toString().trim());
    } catch (_) {
      return null;
    }
  }

  Future<({bool hasDocker, bool hasPodman})> detectInstalledTools(
      String instanceName) async {
    try {
      final result = await Process.run(
        'wsl',
        [
          '-d', instanceName, '--',
          'sh', '-c',
          r'echo "docker=$(command -v docker >/dev/null 2>&1 && echo 1 || echo 0)";'
          r'echo "podman=$(command -v podman >/dev/null 2>&1 && echo 1 || echo 0)"',
        ],
        runInShell: false,
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      final out = _decodeProcessOutput(result.stdout);
      final docker = RegExp(r'docker=1').hasMatch(out);
      final podman = RegExp(r'podman=1').hasMatch(out);
      return (hasDocker: docker, hasPodman: podman);
    } catch (_) {
      return (hasDocker: false, hasPodman: false);
    }
  }

  Future<void> installDockerInInstance(
      String instanceName, String username) async {
    const script = r'''
set -e
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker TARGET_USER
''';
    final cmd = script.replaceAll('TARGET_USER', username);
    final args = ['-d', instanceName, '-u', 'root', '--', 'bash', '-c', cmd];
    final logEntry = CommandLogService.instance.start('wsl', args);
    final process = await Process.start('wsl', args, runInShell: false);
    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();
    process.stdout.listen((c) => stdoutBuf.write(_decodeProcessOutput(c)));
    process.stderr.listen((c) => stderrBuf.write(_decodeProcessOutput(c)));
    final exitCode = await process.exitCode;
    CommandLogService.instance.finish(
      logEntry,
      ProcessResult(process.pid, exitCode, stdoutBuf.toString(), stderrBuf.toString()),
    );
    if (exitCode != 0) {
      throw WslCommandException(
          args, exitCode, stderrBuf.isNotEmpty ? stderrBuf.toString() : stdoutBuf.toString());
    }
  }

  Future<void> installPodmanInInstance(
      String instanceName, String username) async {
    const script = r'''
set -e
apt-get update -qq
apt-get install -y -qq podman
usermod -aG podman TARGET_USER 2>/dev/null || true
mkdir -p /etc/containers
grep -q 'unqualified-search-registries' /etc/containers/registries.conf 2>/dev/null \
  || echo 'unqualified-search-registries = ["docker.io"]' >> /etc/containers/registries.conf
''';
    final cmd = script.replaceAll('TARGET_USER', username);
    final args = ['-d', instanceName, '-u', 'root', '--', 'bash', '-c', cmd];
    final logEntry = CommandLogService.instance.start('wsl', args);
    final process = await Process.start('wsl', args, runInShell: false);
    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();
    process.stdout.listen((c) => stdoutBuf.write(_decodeProcessOutput(c)));
    process.stderr.listen((c) => stderrBuf.write(_decodeProcessOutput(c)));
    final exitCode = await process.exitCode;
    CommandLogService.instance.finish(
      logEntry,
      ProcessResult(process.pid, exitCode, stdoutBuf.toString(), stderrBuf.toString()),
    );
    if (exitCode != 0) {
      throw WslCommandException(
          args, exitCode, stderrBuf.isNotEmpty ? stderrBuf.toString() : stdoutBuf.toString());
    }
  }

  Future<({int aptCacheBytes, int tmpBytes, int logBytes, int total})>
      estimateCleanup(String instanceName) async {
    try {
      final result = await Process.run(
        'wsl',
        [
          '-d', instanceName, '--',
          'sh', '-c',
          r'apt_size=$(du -sb /var/cache/apt/archives 2>/dev/null | cut -f1 || echo 0);'
          r'tmp_size=$(du -sb /tmp 2>/dev/null | cut -f1 || echo 0);'
          r'log_size=$(find /var/log -type f -name "*.gz" -o -name "*.1" 2>/dev/null | xargs du -sb 2>/dev/null | awk "{s+=\$1} END {print s+0}");'
          r'echo "apt=$apt_size tmp=$tmp_size log=$log_size"',
        ],
        runInShell: false,
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      final out = _decodeProcessOutput(result.stdout).trim();
      int parseSize(String key) {
        final m = RegExp('$key=(\\d+)').firstMatch(out);
        return int.tryParse(m?.group(1) ?? '0') ?? 0;
      }
      final apt = parseSize('apt');
      final tmp = parseSize('tmp');
      final log = parseSize('log');
      return (aptCacheBytes: apt, tmpBytes: tmp, logBytes: log, total: apt + tmp + log);
    } catch (_) {
      return (aptCacheBytes: 0, tmpBytes: 0, logBytes: 0, total: 0);
    }
  }

  Future<void> runCleanup(String instanceName) async {
    const script = 'apt-get clean -y 2>/dev/null || true;'
        'rm -rf /tmp/* 2>/dev/null || true;'
        'find /var/log -type f \\( -name "*.gz" -o -name "*.1" \\) -delete 2>/dev/null || true;'
        'apt-get autoremove -y 2>/dev/null || true';
    await _runWsl(['-d', instanceName, '-u', 'root', '--', 'sh', '-c', script]);
  }

  Future<({String? basePath, String? vhdxPath, int? sizeBytes})>
      getInstanceDiskInfo(String instanceName) async {
    if (!RegExp(r"^[\w\-\.]+$").hasMatch(instanceName)) {
      return (basePath: null, vhdxPath: null, sizeBytes: null);
    }
    try {
      final psCmd = "\$key = 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Lxss';"
          "\$match = Get-ChildItem \$key -ErrorAction SilentlyContinue |"
          " Where-Object { (Get-ItemProperty \$_.PSPath -ErrorAction SilentlyContinue).DistributionName -eq '$instanceName' } | Select-Object -First 1;"
          "if (\$match) { (Get-ItemProperty \$match.PSPath).BasePath }";
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', psCmd],
        runInShell: false,
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      final basePath = _decodeProcessOutput(result.stdout).trim();
      if (basePath.isEmpty) {
        return (basePath: null, vhdxPath: null, sizeBytes: null);
      }
      final vhdx = '$basePath\\ext4.vhdx';
      final vhdxFile = File(vhdx);
      final size = vhdxFile.existsSync() ? vhdxFile.lengthSync() : null;
      return (
        basePath: basePath,
        vhdxPath: vhdxFile.existsSync() ? vhdx : null,
        sizeBytes: size,
      );
    } catch (_) {
      return (basePath: null, vhdxPath: null, sizeBytes: null);
    }
  }
}

class WslCommandException implements Exception {
  final List<String> arguments;
  final int exitCode;
  final String output;

  const WslCommandException(this.arguments, this.exitCode, this.output);

  @override
  String toString() {
    final command = ['wsl', ...arguments].join(' ');
    final details = output.isEmpty ? '' : ' : $output';
    return '$command a échoué (code $exitCode)$details';
  }
}
