import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/template.dart';

class TemplateCard extends StatelessWidget {
  final WslTemplate template;
  final VoidCallback onCreateInstance;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onCreateInstance,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sizeMb = template.sizeBytes ~/ (1024 * 1024);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.layers, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(template.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (template.isOrphan) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Fichier manquant',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.orange)),
                        ),
                      ],
                    ],
                  ),
                  if (template.description.isNotEmpty)
                    Text(template.description,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  Text(
                    '${template.sourceDistro} · $sizeMb Mo · '
                    '${timeago.format(template.createdAt, locale: 'fr')}',
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Créer une instance',
              onPressed: template.isOrphan ? null : onCreateInstance,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exporter',
              onPressed: template.isOrphan ? null : onExport,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Supprimer',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
