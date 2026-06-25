import 'package:flutter/material.dart';
import '../create_wizard_screen.dart';

class StepTools extends StatelessWidget {
  final WizardState state;
  final ValueChanged<WizardState> onChanged;
  const StepTools({super.key, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Sélectionnez les outils à installer automatiquement dans la nouvelle instance.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Les permissions sont configurées automatiquement (groupe docker/podman).',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _ToolCard(
          icon: Icons.hub,
          title: 'Docker',
          description: 'Docker Engine + CLI + Compose plugin (dépôt officiel Docker).',
          enabled: state.installDocker,
          version: state.dockerVersion,
          versionHint: 'Ex : 26.1.4 (vide = dernière version)',
          onToggle: (v) => onChanged(state.copyWith(installDocker: v)),
          onVersionChanged: (v) => onChanged(state.copyWith(dockerVersion: v)),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.inventory_2_outlined,
          title: 'Podman',
          description: 'Podman rootless — alternative à Docker sans démon.',
          enabled: state.installPodman,
          version: state.podmanVersion,
          versionHint: 'Ex : 4.9.3 (vide = dernière version)',
          onToggle: (v) => onChanged(state.copyWith(installPodman: v)),
          onVersionChanged: (v) => onChanged(state.copyWith(podmanVersion: v)),
        ),
        if (state.installDocker && state.installPodman) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Docker et Podman peuvent coexister mais des conflits de socket sont possibles.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!state.installDocker && !state.installPodman) ...[
          const SizedBox(height: 16),
          Text(
            'Aucun outil sélectionné — vous pourrez les installer manuellement plus tard.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ToolCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final String version;
  final String versionHint;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onVersionChanged;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.version,
    required this.versionHint,
    required this.onToggle,
    required this.onVersionChanged,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.version);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 24,
                    color: widget.enabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(widget.description,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ),
                Switch(
                  value: widget.enabled,
                  onChanged: widget.onToggle,
                ),
              ],
            ),
            if (widget.enabled) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  labelText: 'Version (optionnelle)',
                  hintText: widget.versionHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: widget.onVersionChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
