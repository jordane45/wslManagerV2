import 'package:flutter/material.dart';
import '../services/wsl_service.dart';
import 'progress_dialog.dart';

class CleanupDialog extends StatefulWidget {
  final String instanceName;
  const CleanupDialog({super.key, required this.instanceName});

  @override
  State<CleanupDialog> createState() => _CleanupDialogState();
}

class _CleanupDialogState extends State<CleanupDialog> {
  ({int aptCacheBytes, int tmpBytes, int logBytes, int total})? _estimate;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEstimate();
  }

  Future<void> _loadEstimate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await WslService.instance.estimateCleanup(widget.instanceName);
      if (mounted) setState(() => _estimate = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} Mo';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '$bytes o';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cleaning_services_outlined),
          const SizedBox(width: 8),
          Expanded(child: Text('Nettoyage — ${widget.instanceName}')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Estimation de l\'espace récupérable...'),
                  ],
                ),
              )
            : _error != null
                ? Text(
                    'Erreur : $_error',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  )
                : _estimate == null
                    ? const Text('Impossible d\'estimer l\'espace.')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Espace potentiellement récupérable :',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          _EstimateRow(
                            label: 'Cache apt',
                            icon: Icons.download_done_outlined,
                            value: _fmt(_estimate!.aptCacheBytes),
                          ),
                          _EstimateRow(
                            label: 'Fichiers temporaires (/tmp)',
                            icon: Icons.folder_outlined,
                            value: _fmt(_estimate!.tmpBytes),
                          ),
                          _EstimateRow(
                            label: 'Logs rotatés (.gz, .1)',
                            icon: Icons.description_outlined,
                            value: _fmt(_estimate!.logBytes),
                          ),
                          const Divider(height: 24),
                          _EstimateRow(
                            label: 'Total estimé',
                            icon: Icons.savings_outlined,
                            value: _fmt(_estimate!.total),
                            bold: true,
                          ),
                          if (_estimate!.total == 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 16, color: Color(0xFF22C55E)),
                                const SizedBox(width: 6),
                                Text(
                                  'Rien à nettoyer pour l\'instant.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        if (!_loading && _error == null)
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Recalculer'),
            onPressed: _loadEstimate,
          ),
        if (!_loading && _error == null && (_estimate?.total ?? 0) > 0)
          FilledButton.icon(
            icon: const Icon(Icons.cleaning_services, size: 16),
            label: const Text('Nettoyer'),
            onPressed: () => _runCleanup(context),
          ),
      ],
    );
  }

  Future<void> _runCleanup(BuildContext context) async {
    Navigator.pop(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Nettoyage — ${widget.instanceName}',
        steps: [
          ProgressStep('Nettoyage du cache apt...'),
          ProgressStep('Suppression des fichiers temporaires...'),
          ProgressStep('Suppression des logs rotatés...'),
          ProgressStep('Paquets orphelins (autoremove)...'),
        ],
        task: (update, _) async {
          update(0, StepStatus.running);
          await WslService.instance.runCleanup(widget.instanceName);
          update(0, StepStatus.done);
          update(1, StepStatus.done);
          update(2, StepStatus.done);
          update(3, StepStatus.done);
        },
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool bold;

  const _EstimateRow({
    required this.label,
    required this.icon,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Courier New',
              color: bold
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
