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
    final webDownload =
        state.useWebDownload && state.sourceType == SourceType.online;

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
                if (webDownload)
                  _Row('Nom de l\'instance', state.officialDistroName ?? '—')
                else
                  _Row('Nom de l\'instance', state.instanceName),
                _Row('Utilisateur', state.username),
                const _Row('Mot de passe', '••••••••'),
                if (!webDownload)
                  _Row('Chemin d\'installation', state.installPath),
                if (webDownload)
                  const _Row('Emplacement', 'Géré automatiquement par WSL'),
                if (state.installDocker || state.installPodman) ...[
                  const Divider(height: 16),
                  if (state.installDocker)
                    _Row(
                      'Docker',
                      state.dockerVersion.isEmpty
                          ? 'Dernière version'
                          : 'v${state.dockerVersion}',
                    ),
                  if (state.installPodman)
                    _Row(
                      'Podman',
                      state.podmanVersion.isEmpty
                          ? 'Dernière version'
                          : 'v${state.podmanVersion}',
                    ),
                ],
              ],
            ),
          ),
        ),
        if (webDownload) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.download_for_offline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Installation via wsl --install --web-download',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
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
