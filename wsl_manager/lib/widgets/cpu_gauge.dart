import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CpuGauge extends StatelessWidget {
  final double cpuPercent;
  final double radius;
  const CpuGauge({super.key, required this.cpuPercent, this.radius = 40});

  Color get _color {
    if (cpuPercent > 80) return Colors.red;
    if (cpuPercent > 50) return Colors.orange;
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: 6,
      percent: (cpuPercent / 100).clamp(0.0, 1.0),
      center: Text('${cpuPercent.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      progressColor: _color,
      backgroundColor: _color.withAlpha(30),
      circularStrokeCap: CircularStrokeCap.round,
      header: const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Text('CPU', style: TextStyle(fontSize: 10)),
      ),
    );
  }
}
