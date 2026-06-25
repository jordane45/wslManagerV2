import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/command_log_entry.dart';
import '../utils/constants.dart';
import '../utils/wsl_parser.dart';
import 'storage_service.dart';

class CommandLogService extends ChangeNotifier {
  static CommandLogService? _instance;
  static CommandLogService get instance => _instance ??= CommandLogService._();
  CommandLogService._();

  final StreamController<String> _liveLogController =
      StreamController<String>.broadcast();

  Stream<String> get liveLogStream => _liveLogController.stream;

  static const int _maxEntries = 100;
  static const int _maxOutputChars = 60000;

  final List<CommandLogEntry> _entries = [];
  bool _loaded = false;
  Future<void>? _pendingWrite;
  bool _writeAgain = false;

  UnmodifiableListView<CommandLogEntry> get entries =>
      UnmodifiableListView(_entries);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final dir = await StorageService.instance.getAppDataDir();
      final file = File(p.join(dir.path, kCommandLogsFile));
      if (!file.existsSync()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return;
      final rawEntries = decoded['entries'];
      if (rawEntries is! List) return;
      _entries
        ..clear()
        ..addAll(
          rawEntries
              .whereType<Map<String, dynamic>>()
              .map(CommandLogEntry.fromJson),
        );
      _sortAndTrim();
      notifyListeners();
    } catch (_) {
      // Corrupt log history should never block command execution.
    }
  }

  CommandLogEntry start(String executable, List<String> arguments) {
    unawaited(load());
    final entry = CommandLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      executable: executable,
      arguments: List.unmodifiable(arguments),
      startedAt: DateTime.now(),
    );
    _entries.insert(0, entry);
    _sortAndTrim();
    notifyListeners();
    _schedulePersist();
    _liveLogController.add('> ${entry.commandLine}');
    return entry;
  }

  void finish(
    CommandLogEntry entry,
    ProcessResult result, {
    String? stdout,
    String? stderr,
  }) {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    final out = _trimOutput(stdout ?? _decode(result.stdout));
    final err = _trimOutput(stderr ?? _decode(result.stderr));
    _entries[index] = entry.copyWith(
      finishedAt: DateTime.now(),
      exitCode: result.exitCode,
      stdout: out,
      stderr: err,
    );
    notifyListeners();
    _schedulePersist();

    if (result.exitCode != 0) {
      _liveLogController.add('  [exit ${result.exitCode}]');
      if (err.isNotEmpty) _liveLogController.add(err);
    } else if (out.isNotEmpty) {
      _liveLogController.add(out);
    }
  }

  void clear() {
    _entries.clear();
    notifyListeners();
    _schedulePersist();
  }

  String _decode(Object? output) {
    if (output is List<int>) return WslParser.decodeWslOutput(output);
    if (output is String) return output;
    return '';
  }

  String _trimOutput(String value) {
    if (value.length <= _maxOutputChars) return value;
    final omitted = value.length - _maxOutputChars;
    return '${value.substring(0, _maxOutputChars)}\n\n... $omitted caracteres tronques';
  }

  void _sortAndTrim() {
    _entries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
  }

  void _schedulePersist() {
    if (_pendingWrite != null) {
      _writeAgain = true;
      return;
    }
    _pendingWrite = _persistSerially();
  }

  Future<void> _persistSerially() async {
    do {
      _writeAgain = false;
      await _persist();
    } while (_writeAgain);
    _pendingWrite = null;
  }

  Future<void> _persist() async {
    try {
      final dir = await StorageService.instance.getAppDataDir();
      final file = File(p.join(dir.path, kCommandLogsFile));
      final payload = {
        'version': kJsonVersion,
        'entries': _entries.map((entry) => entry.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Logging is diagnostic only; keep the app usable if persistence fails.
    }
  }
}
