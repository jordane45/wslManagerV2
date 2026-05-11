import 'package:flutter/material.dart';
import '../services/uac_service.dart';

class UacBanner extends StatefulWidget {
  const UacBanner({super.key});

  @override
  State<UacBanner> createState() => _UacBannerState();
}

class _UacBannerState extends State<UacBanner> {
  bool _dismissed = false;
  late bool _elevated;

  @override
  void initState() {
    super.initState();
    _elevated = UacService.instance.isElevated();
  }

  @override
  Widget build(BuildContext context) {
    if (_elevated || _dismissed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.shield_outlined,
              color: Theme.of(context).colorScheme.onTertiaryContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'L\'application ne tourne pas en administrateur. '
              'La conversion WSL1↔WSL2 nécessite une élévation.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onTertiaryContainer),
            ),
          ),
          TextButton(
            onPressed: () => UacService.instance.relaunchAsAdmin(),
            child: const Text('Relancer en admin'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _dismissed = true),
            tooltip: 'Masquer',
          ),
        ],
      ),
    );
  }
}
