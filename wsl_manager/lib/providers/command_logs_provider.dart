import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/command_log_service.dart';

final commandLogsProvider = ChangeNotifierProvider<CommandLogService>((ref) {
  final service = CommandLogService.instance;
  service.load();
  return service;
});
