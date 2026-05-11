import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/templates_provider.dart';
import '../../services/template_service.dart';
import '../../widgets/confirm_dialog.dart';
import 'widgets/template_card.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importer un template (.tar)',
            onPressed: () => _import(context, ref),
          ),
        ],
      ),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Aucun template disponible.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Importer un template'),
                    onPressed: () => _import(context, ref),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 80),
            itemCount: list.length,
            itemBuilder: (_, i) => TemplateCard(
              template: list[i],
              onCreateInstance: () =>
                  context.go('/create'),
              onExport: () => _export(context, ref, list[i].id),
              onDelete: () => _delete(context, ref, list[i].id, list[i].name),
            ),
          );
        },
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['tar'],
      dialogTitle: 'Sélectionner un template .tar',
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final name = result.files.single.name.replaceAll('.tar', '');
    await TemplateService.instance.importFromFile(path, name, '');
    await ref.read(templatesProvider.notifier).refresh();
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, String id) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter le template',
      fileName: 'template.tar',
    );
    if (result == null) return;
    await TemplateService.instance.exportToFile(id, result);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Supprimer le template',
        message: 'Supprimer "$name" ? Le fichier .tar sera supprimé.',
        confirmLabel: 'Supprimer',
        destructive: true);
    if (!confirmed) return;
    await ref.read(templatesProvider.notifier).delete(id);
  }
}
