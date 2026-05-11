import 'package:flutter/material.dart';
import '../../../services/wsl_service.dart';

class WslConfEditor extends StatefulWidget {
  final String instanceName;
  const WslConfEditor({super.key, required this.instanceName});

  @override
  State<WslConfEditor> createState() => _WslConfEditorState();
}

class _WslConfEditorState extends State<WslConfEditor> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final content = await WslService.instance.readWslConf(widget.instanceName);
      _controller.text = content.isEmpty ? _placeholder : content;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await WslService.instance.writeWslConf(
          widget.instanceName, _controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sauvegardé. Redémarrez l\'instance pour appliquer les changements.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Text('Erreur de lecture : $_error',
              style: const TextStyle(color: Colors.red)));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Text(
                  'L\'instance doit être redémarrée pour appliquer les modifications.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onTertiaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save, size: 16),
                label: const Text('Sauvegarder'),
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réinitialiser'),
                onPressed: _saving ? null : _load,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _placeholder = '''[automount]
enabled = true
root = /mnt/

[network]
generateHosts = true
generateResolvConf = true

[user]
default =
''';
}
