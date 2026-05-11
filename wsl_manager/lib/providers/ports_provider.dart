import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wsl_port.dart';
import '../services/wsl_service.dart';

final portsProvider =
    FutureProvider.family<List<WslPort>, String>((ref, instanceName) async {
  return WslService.instance.listListeningPorts(instanceName);
});
