import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../providers/templates_provider.dart';
import '../create_wizard_screen.dart';

class StepSource extends ConsumerStatefulWidget {
  final WizardState state;
  final ValueChanged<WizardState> onChanged;
  const StepSource({super.key, required this.state, required this.onChanged});

  @override
  ConsumerState<StepSource> createState() => _StepSourceState();
}

class _StepSourceState extends ConsumerState<StepSource> {
  List<_OfficialDistro> _distros = [];
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDistros();
    _urlCtrl.text = widget.state.remoteUrl ?? '';
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDistros() async {
    try {
      final raw = await rootBundle.loadString('assets/data/official_distros.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['distros'] as List)
          .map((d) => _OfficialDistro(
                name: d['name'] as String,
                wslName: d['wsl_name'] as String,
                icon: d['icon'] as String,
                downloadUrl: d['download_url'] as String,
              ))
          .toList();
      if (mounted) setState(() => _distros = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesProvider).valueOrNull ?? [];
    final type = widget.state.sourceType;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SourceCard(
          icon: Icons.cloud_download,
          title: 'En ligne',
          subtitle: 'Télécharger une distro officielle',
          selected: type == SourceType.online,
          onTap: () => widget.onChanged(
              widget.state.copyWith(sourceType: SourceType.online)),
          child: type == SourceType.online
              ? _DistroGrid(
                  distros: _distros,
                  selected: widget.state.officialDistroUrl,
                  onSelect: (d) => widget.onChanged(widget.state.copyWith(
                    officialDistroName: d.wslName,
                    officialDistroUrl: d.downloadUrl,
                  )),
                )
              : null,
        ),
        const SizedBox(height: 12),
        _SourceCard(
          icon: Icons.file_open,
          title: 'Fichier .tar local',
          subtitle: 'Sélectionner un fichier sur ce poste',
          selected: type == SourceType.localFile,
          onTap: () => widget.onChanged(
              widget.state.copyWith(sourceType: SourceType.localFile)),
          child: type == SourceType.localFile
              ? _FilePicker(
                  path: widget.state.localTarPath,
                  onPick: (p) => widget.onChanged(
                      widget.state.copyWith(localTarPath: p)),
                )
              : null,
        ),
        const SizedBox(height: 12),
        _SourceCard(
          icon: Icons.link,
          title: 'URL',
          subtitle: 'Saisir une URL HTTP/HTTPS vers un .tar',
          selected: type == SourceType.url,
          onTap: () => widget.onChanged(
              widget.state.copyWith(sourceType: SourceType.url)),
          child: type == SourceType.url
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL du fichier .tar/.tar.gz',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => widget
                        .onChanged(widget.state.copyWith(remoteUrl: v)),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        _SourceCard(
          icon: Icons.layers,
          title: 'Template',
          subtitle: templates.isEmpty
              ? 'Aucun template disponible'
              : 'Créer depuis un template existant',
          selected: type == SourceType.template,
          enabled: templates.isNotEmpty,
          onTap: templates.isEmpty
              ? null
              : () => widget.onChanged(
                  widget.state.copyWith(sourceType: SourceType.template)),
          child: type == SourceType.template
              ? Column(
                  children: templates.map((t) {
                    final sel = widget.state.templateId == t.id;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        sel ? Icons.check_circle : Icons.circle_outlined,
                        color: sel
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        size: 20,
                      ),
                      title: Text(t.name),
                      subtitle: Text('${t.sizeBytes ~/ (1024 * 1024)} Mo'),
                      onTap: () => widget.onChanged(
                          widget.state.copyWith(templateId: t.id)),
                    );
                  }).toList(),
                )
              : null,
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? child;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.enabled = true,
    this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: selected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      color: enabled
                          ? (selected
                              ? Theme.of(context).colorScheme.primary
                              : null)
                          : Colors.grey),
                  const SizedBox(width: 10),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: enabled ? null : Colors.grey)),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              if (child != null) ...[
                const SizedBox(height: 8),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DistroGrid extends StatelessWidget {
  final List<_OfficialDistro> distros;
  final String? selected;
  final ValueChanged<_OfficialDistro> onSelect;
  const _DistroGrid(
      {required this.distros,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (distros.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: distros.map((d) {
        final isSelected = selected == d.downloadUrl;
        return ChoiceChip(
          label: Text(d.name),
          selected: isSelected,
          onSelected: d.downloadUrl.isEmpty ? null : (_) => onSelect(d),
        );
      }).toList(),
    );
  }
}

class _FilePicker extends StatelessWidget {
  final String? path;
  final ValueChanged<String> onPick;
  const _FilePicker({this.path, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              path ?? 'Aucun fichier sélectionné',
              style: TextStyle(
                  fontSize: 12,
                  color: path != null
                      ? null
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.file_open, size: 16),
            label: const Text('Parcourir'),
            onPressed: () async {
              // file_picker integration
              onPick('/placeholder.tar');
            },
          ),
        ],
      ),
    );
  }
}

class _OfficialDistro {
  final String name;
  final String wslName;
  final String icon;
  final String downloadUrl;
  const _OfficialDistro(
      {required this.name,
      required this.wslName,
      required this.icon,
      required this.downloadUrl});
}
