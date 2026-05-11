import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/template.dart';
import '../services/template_service.dart';

class TemplatesNotifier extends AsyncNotifier<List<WslTemplate>> {
  @override
  Future<List<WslTemplate>> build() => TemplateService.instance.listTemplates();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(TemplateService.instance.listTemplates);
  }

  Future<void> delete(String id) async {
    await TemplateService.instance.deleteTemplate(id);
    await refresh();
  }
}

final templatesProvider =
    AsyncNotifierProvider<TemplatesNotifier, List<WslTemplate>>(
  TemplatesNotifier.new,
);
