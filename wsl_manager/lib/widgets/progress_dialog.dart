import 'dart:async';

import 'package:flutter/material.dart';

import '../services/command_log_service.dart';

enum StepStatus { waiting, running, done, error }

class ProgressStep {
  final String label;
  StepStatus status;
  String? errorMessage;
  double? progress;

  ProgressStep(this.label, {this.status = StepStatus.waiting});
}

class _StopSignal {
  const _StopSignal();
}

class ProgressDialog extends StatefulWidget {
  final String title;
  final List<ProgressStep> steps;
  final Future<void> Function(
    void Function(int, StepStatus, [String?]) update,
    void Function(int, double?) setProgress,
  ) task;

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
  bool _showLog = true;

  final List<String> _logLines = [];
  final ScrollController _logScroll = ScrollController();
  StreamSubscription<String>? _logSub;

  @override
  void initState() {
    super.initState();
    _steps = widget.steps;
    _logSub = CommandLogService.instance.liveLogStream.listen(_addLog);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _logScroll.dispose();
    super.dispose();
  }

  void _addLog(String line) {
    if (!mounted) return;
    setState(() => _logLines.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(
          _logScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateStep(int index, StepStatus status, [String? error]) {
    setState(() {
      _steps[index].status = status;
      if (error != null) _steps[index].errorMessage = error;
      if (status == StepStatus.error) _hasError = true;
    });
    if (status == StepStatus.error) {
      _addLog('Erreur : ${error ?? "étape ${index + 1} échouée"}');
      throw const _StopSignal();
    }
  }

  Future<void> _run() async {
    try {
      await widget.task(_updateStep, (index, progress) {
        setState(() => _steps[index].progress = progress);
      });
      setState(() => _done = true);
    } on _StopSignal {
      setState(() => _done = true);
    } catch (e) {
      setState(() {
        _hasError = true;
        _done = true;
        final runningIdx =
            _steps.indexWhere((s) => s.status == StepStatus.running);
        if (runningIdx >= 0) {
          _steps[runningIdx].status = StepStatus.error;
          _steps[runningIdx].errorMessage = e.toString();
        }
      });
      _addLog('Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._steps.map((s) => _StepRow(step: s)),
            if (!_done) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _showLog = !_showLog),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _showLog
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Journal des commandes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_logLines.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${_logLines.length}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_showLog)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _logLines.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune commande exécutée',
                          style:
                              TextStyle(color: Color(0xFF888888), fontSize: 11),
                        ),
                      )
                    : ListView.builder(
                        controller: _logScroll,
                        padding: const EdgeInsets.all(8),
                        itemCount: _logLines.length,
                        itemBuilder: (_, i) {
                          final line = _logLines[i];
                          final isCmd = line.startsWith('>');
                          final isErr = line.startsWith('  [exit') ||
                              line.startsWith('Erreur');
                          return Text(
                            line,
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 11,
                              color: isErr
                                  ? const Color(0xFFFF6B6B)
                                  : isCmd
                                      ? const Color(0xFF89DDFF)
                                      : const Color(0xFFCCCCCC),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      Text(
                        step.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (step.status == StepStatus.running) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: LinearProgressIndicator(value: step.progress),
            ),
          ],
        ],
      ),
    );
  }
}
