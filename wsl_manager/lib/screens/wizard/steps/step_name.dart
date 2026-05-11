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
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.state.instanceName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validate(String value) {
    final existing = ref.read(instancesProvider).valueOrNull
            ?.map((i) => i.name)
            .toList() ??
        [];
    setState(() => _error = validateInstanceName(value, existing: existing));
    if (_error == null) {
      widget.onChanged(widget.state.copyWith(instanceName: value));
    } else {
      widget.onChanged(widget.state.copyWith(instanceName: ''));
    }
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
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nom de l\'instance',
              hintText: 'Ex. : Ubuntu-dev',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onChanged: _validate,
          ),
          const SizedBox(height: 8),
          Text(
            'Alphanumérique, tirets et underscores uniquement (2–64 caractères).',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
