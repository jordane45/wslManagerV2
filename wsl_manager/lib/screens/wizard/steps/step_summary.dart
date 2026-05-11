import 'package:flutter/material.dart';
import '../create_wizard_screen.dart';

class StepSummary extends StatelessWidget {
  final WizardState state;
  const StepSummary({super.key, required this.state});

  String get _sourceLabel {
    switch (state.sourceType) {
      case SourceType.online:
        return state.officialDistroName ?? '—';
      case SourceType.localFile:
        return state.localTarPath ?? '—';
      case SourceType.url:
        return state.remoteUrl ?? '—';
      case SourceType.template:
        return 'Template : ${state.templateId ?? '—'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Vérifiez les informations avant de créer l\'instance.',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Row('Source', _sourceLabel),
                _Row('Nom de l\'instance', state.instanceName),
                _Row('Utilisateur', state.username),
                const _Row('Mot de passe', '••••••••'),
                _Row('Chemin d\'installation', state.installPath),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cliquez sur "Créer" pour démarrer la création. '
                  'L\'opération peut prendre plusieurs minutes.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
