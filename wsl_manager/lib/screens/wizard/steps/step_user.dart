import 'package:flutter/material.dart';
import '../../../utils/validators.dart';
import '../create_wizard_screen.dart';

class StepUser extends StatefulWidget {
  final WizardState state;
  final ValueChanged<WizardState> onChanged;
  const StepUser({super.key, required this.state, required this.onChanged});

  @override
  State<StepUser> createState() => _StepUserState();
}

class _StepUserState extends State<StepUser> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.state.username);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validate(String value) {
    setState(() => _error = validateLinuxUsername(value));
    if (_error == null) {
      widget.onChanged(widget.state.copyWith(username: value));
    } else {
      widget.onChanged(widget.state.copyWith(username: ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nom d\'utilisateur Linux de l\'instance.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nom d\'utilisateur',
              hintText: 'Ex. : jordan',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onChanged: _validate,
          ),
          const SizedBox(height: 8),
          Text(
            'Minuscules, chiffres et tirets uniquement. Ne peut pas être "root".',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
