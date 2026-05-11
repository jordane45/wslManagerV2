import 'package:flutter/material.dart';
import '../../../utils/validators.dart';
import '../create_wizard_screen.dart';

class StepPassword extends StatefulWidget {
  final WizardState state;
  final ValueChanged<WizardState> onChanged;
  const StepPassword({super.key, required this.state, required this.onChanged});

  @override
  State<StepPassword> createState() => _StepPasswordState();
}

class _StepPasswordState extends State<StepPassword> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _passError;
  String? _confirmError;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    final passErr = validatePassword(_passCtrl.text);
    final confirmErr = validatePasswordConfirm(_confirmCtrl.text, _passCtrl.text);
    setState(() {
      _passError = passErr;
      _confirmError = confirmErr;
    });
    if (passErr == null && confirmErr == null) {
      widget.onChanged(widget.state.copyWith(password: _passCtrl.text));
    } else {
      widget.onChanged(widget.state.copyWith(password: ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mot de passe du compte utilisateur.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          TextField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              border: const OutlineInputBorder(),
              errorText: _passError,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePass ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            onChanged: (_) => _validate(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              border: const OutlineInputBorder(),
              errorText: _confirmError,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            onChanged: (_) => _validate(),
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum 8 caractères.',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
