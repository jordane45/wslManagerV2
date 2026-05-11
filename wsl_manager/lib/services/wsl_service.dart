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

  Future<void> openInVsCode(String name) async {
    await Process.run('code', ['--remote', 'wsl+$name'], runInShell: true);
  }

  Future<void> openInExplorer(String name) async {
    await Process.run('explorer.exe', [r'\\wsl.localhost\' + name],
        runInShell: true);
  }

  Future<void> openInTerminal(String name) async {
    final arguments = ['wsl', '-d', name];
    final logEntry = CommandLogService.instance.start('wt', arguments);
    final result = await Process.run('wt', arguments, runInShell: true);
    CommandLogService.instance.finish(logEntry, result);
    if (result.exitCode != 0) {
      // Fallback for users without Windows Terminal installed
      final fallbackArguments = [
        '/c',
        'start',
        '',
        'cmd.exe',
        '/k',
        'wsl -d $name'
      ];
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
