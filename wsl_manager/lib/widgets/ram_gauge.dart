import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class RamGauge extends StatelessWidget {
  final int usedMb;
  final int totalMb;
  const RamGauge({super.key, required this.usedMb, required this.totalMb});

  @override
  Widget build(BuildContext context) {
    final pct = totalMb > 0 ? usedMb / totalMb : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('RAM', style: TextStyle(fontSize: 10)),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          width: 120,
          lineHeight: 8,
          percent: pct.clamp(0.0, 1.0),
          progressColor: const Color(0xFF0078D4),
          backgroundColor: const Color(0xFF0078D4).withAlpha(30),
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 2),
        Text(
          '$usedMb Mo / $totalMb Mo (${(pct * 100).toStringAsFixed(1)}%)',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
