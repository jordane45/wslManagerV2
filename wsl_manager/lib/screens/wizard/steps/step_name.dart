import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/instances_provider.dart';
import '../../../utils/validators.dart';
import '../create_wizard_screen.dart';

class StepName extends ConsumerStatefulWidget {
  final WizardState state;
  final ValueChanged<WizardState> onChanged;
  const StepName({super.key, required this.state, required this.onChanged});

  @override
  ConsumerState<StepName> createState() => _StepNameState();
}

class _StepNameState extends ConsumerState<StepName> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.instanceName);
    _descCtrl = TextEditingController(text: widget.state.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _validateName(String value) {
    final existing = ref.read(instancesProvider).valueOrNull
            ?.map((i) => i.name)
            .toList() ??
        [];
    setState(() => _error = validateInstanceName(value, existing: existing));
    widget.onChanged(widget.state.copyWith(
      instanceName: _error == null ? value : '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choisissez un nom pour la nouvelle instance.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nom de l\'instance',
              hintText: 'Ex. : Ubuntu-dev',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onChanged: _validateName,
          ),
          const SizedBox(height: 8),
          Text(
            'Alphanumérique, tirets et underscores uniquement (2–64 caractères).',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optionnelle)',
              hintText: 'Ex. : serveur de dev Node.js 18, usage personnel...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                widget.onChanged(widget.state.copyWith(description: v)),
          ),
        ],
      ),
    );
  }
}
