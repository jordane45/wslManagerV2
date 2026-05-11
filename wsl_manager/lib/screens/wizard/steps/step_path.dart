import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../create_wizard_screen.dart';

class StepPath extends StatefulWidget {
  final WizardState state;
  final ValueChanged<WizardState> onChanged;
  const StepPath({super.key, required this.state, required this.onChanged});

  @override
  State<StepPath> createState() => _StepPathState();
}

class _StepPathState extends State<StepPath> {
  late final TextEditingController _ctrl;
  String? _warning;

  @override
  void initState() {
    super.initState();
    final defaultPath = widget.state.installPath.isNotEmpty
        ? widget.state.installPath
        : 'C:\\WSL\\${widget.state.instanceName}';
    _ctrl = TextEditingController(text: defaultPath);
    widget.onChanged(widget.state.copyWith(installPath: defaultPath));
    _checkDiskSpace(defaultPath);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkDiskSpace(String path) async {
    try {
      final drive = path.substring(0, 3);
      final stat = await FileStat.stat(drive);
      if (stat.type == FileSystemEntityType.notFound) {
        setState(() => _warning = null);
      }
    } catch (_) {}
  }

  Future<void> _browse() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choisir le dossier d\'installation',
    );
    if (result != null) {
      _ctrl.text = result;
      widget.onChanged(widget.state.copyWith(installPath: result));
      _checkDiskSpace(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dossier d\'installation de l\'image disque.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Chemin d\'installation',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    widget.onChanged(widget.state.copyWith(installPath: v));
                    _checkDiskSpace(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Parcourir'),
                onPressed: _browse,
              ),
            ],
          ),
          if (_warning != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(_warning!,
                    style: const TextStyle(fontSize: 12, color: Colors.orange)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Le dossier sera créé automatiquement s\'il n\'existe pas.',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
