import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/wsl_instance.dart';

class StatusBadge extends StatelessWidget {
  final WslInstanceState state;
  const StatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      WslInstanceState.running => ('Running', const Color(0xFF22C55E)),
      WslInstanceState.stopped => ('Stopped', const Color(0xFF6B7280)),
      WslInstanceState.installing => ('Installing', const Color(0xFFF59E0B)),
    };

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );

    if (state == WslInstanceState.installing) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 800.ms)
          .fadeOut(delay: 800.ms, duration: 800.ms);
    }

    return badge;
  }
}
