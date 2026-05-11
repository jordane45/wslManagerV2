import 'package:flutter/material.dart';

enum StepStatus { waiting, running, done, error }

class ProgressStep {
  final String label;
  StepStatus status;
  String? errorMessage;

  ProgressStep(this.label, {this.status = StepStatus.waiting});
}

class ProgressDialog extends StatefulWidget {
  final String title;
  final List<ProgressStep> steps;
  final Future<void> Function(void Function(int, StepStatus, [String?]) update) task;

  const ProgressDialog({
    super.key,
    required this.title,
    required this.steps,
    required this.task,
  });

  @override
  State<ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  late List<ProgressStep> _steps;
  bool _done = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _steps = widget.steps;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      await widget.task((index, status, [error]) {
        setState(() {
          _steps[index].status = status;
          if (error != null) _steps[index].errorMessage = error;
        });
      });
      setState(() => _done = true);
    } catch (e) {
      setState(() {
        _hasError = true;
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._steps.map((s) => _StepRow(step: s)),
          if (!_done) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: _done
          ? [
              FilledButton(
                onPressed: () => Navigator.pop(context, !_hasError),
                child: Text(_hasError ? 'Fermer' : 'Terminé'),
              ),
            ]
          : null,
    );
  }
}

class _StepRow extends StatelessWidget {
  final ProgressStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (step.status) {
      StepStatus.waiting => (Icons.radio_button_unchecked, Colors.grey),
      StepStatus.running => (Icons.sync, Colors.blue),
      StepStatus.done => (Icons.check_circle, const Color(0xFF22C55E)),
      StepStatus.error => (Icons.error, Colors.red),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          step.status == StepStatus.running
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label),
                if (step.errorMessage != null)
                  Text(step.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
