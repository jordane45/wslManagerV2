import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wsl_manager/app.dart';
import 'package:wsl_manager/models/wsl_instance.dart';
import 'package:wsl_manager/providers/instances_provider.dart';
import 'package:wsl_manager/providers/monitoring_alerts_provider.dart';
import 'package:wsl_manager/providers/monitoring_provider.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          instancesProvider.overrideWith(_FakeInstancesNotifier.new),
          monitoringProvider.overrideWith((ref) => const Stream.empty()),
          monitoringAlertsProvider.overrideWith(_NoopAlertsNotifier.new),
        ],
        child: const App(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class _FakeInstancesNotifier extends InstancesNotifier {
  @override
  Future<List<WslInstance>> build() async => const [];
}

class _NoopAlertsNotifier extends MonitoringAlertsNotifier {
  @override
  void build() {}
}
