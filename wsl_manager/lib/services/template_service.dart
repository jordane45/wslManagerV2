import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/template.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'wsl_service.dart';

class TemplateService {
  static TemplateService? _instance;
  static TemplateService get instance => _instance ??= TemplateService._();
  TemplateService._();

  final _uuid = const Uuid();

  Future<List<WslTemplate>> listTemplates() async {
    final data = await StorageService.instance.readJson(
      kTemplatesFile,
      (m) => m,
    );
    if (data == null) return [];
    final list = (data['templates'] as List? ?? [])
        .map((e) => WslTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    return list.map((t) {
      final exists = File(t.tarPath).existsSync();
      return exists ? t : WslTemplate(
        id: t.id, name: t.name, description: t.description,
        sourceDistro: t.sourceDistro, tarPath: t.tarPath,
        sizeBytes: t.sizeBytes, createdAt: t.createdAt, isOrphan: true,
      );
    }).toList();
  }

  Future<WslTemplate> createFromInstance(
    String instanceName,
    String templateName,
    String description,
  ) async {
    final dir = await StorageService.instance.getTemplatesDir();
    final tarPath = '$dir\\$templateName.tar';
    await WslService.instance.exportInstance(instanceName, tarPath);
    final size = File(tarPath).lengthSync();
    final template = WslTemplate(
      id: _uuid.v4(),
      name: templateName,
      description: description,
      sourceDistro: instanceName,
      tarPath: tarPath,
      sizeBytes: size,
      createdAt: DateTime.now(),
    );
    await _save(await listTemplates()..add(template));
    return template;
  }

  Future<WslTemplate> importFromFile(
    String sourceTarPath,
    String templateName,
    String description,
  ) async {
    final dir = await StorageService.instance.getTemplatesDir();
    final dest = '$dir\\$templateName.tar';
    await File(sourceTarPath).copy(dest);
    final size = File(dest).lengthSync();
    final template = WslTemplate(
      id: _uuid.v4(),
      name: templateName,
      description: description,
      sourceDistro: '',
      tarPath: dest,
      sizeBytes: size,
      createdAt: DateTime.now(),
    );
    await _save(await listTemplates()..add(template));
    return template;
  }

  Future<void> deleteTemplate(String id) async {
    final list = await listTemplates();
    final template = list.firstWhere((t) => t.id == id);
    final file = File(template.tarPath);
    if (file.existsSync()) await file.delete();
    await _save(list.where((t) => t.id != id).toList());
  }

  Future<void> exportToFile(String id, String destinationPath) async {
    final list = await listTemplates();
    final template = list.firstWhere((t) => t.id == id);
    await File(template.tarPath).copy(destinationPath);
  }

  Future<void> _save(List<WslTemplate> templates) async {
    await StorageService.instance.writeJson(kTemplatesFile, {
      'version': kJsonVersion,
      'templates': templates.map((t) => t.toJson()).toList(),
    });
  }
}
