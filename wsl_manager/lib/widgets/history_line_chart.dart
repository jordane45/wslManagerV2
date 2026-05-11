import 'package:flutter/material.dart';

import '../providers/monitoring_history_provider.dart';

class HistoryLineChart extends StatelessWidget {
  final List<MonitoringSample> samples;

  const HistoryLineChart({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _HistoryLineChartPainter(
          samples: samples,
          cpuColor: const Color(0xFF22C55E),
          ramColor: Theme.of(context).colorScheme.primary,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
          labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HistoryLineChartPainter extends CustomPainter {
  final List<MonitoringSample> samples;
  final Color cpuColor;
  final Color ramColor;
  final Color gridColor;
  final Color labelColor;

  const _HistoryLineChartPainter({
    required this.samples,
    required this.cpuColor,
    required this.ramColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(34, 8, size.width - 42, size.height - 34);
    _drawGrid(canvas, chartRect);
    _drawLabels(canvas, chartRect);

    if (samples.length < 2) {
      _drawEmptyState(canvas, chartRect);
      return;
    }

    final now = DateTime.now();
    final start = now.subtract(MonitoringHistoryNotifier.historyWindow);
    _drawLine(
        canvas, chartRect, start, now, cpuColor, (sample) => sample.cpuPercent);
    _drawLine(
        canvas, chartRect, start, now, ramColor, (sample) => sample.ramPercent);
    _drawLegend(canvas, size);
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final ratio in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = rect.bottom - rect.height * ratio;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
    canvas.drawRect(rect, paint..style = PaintingStyle.stroke);
  }

  void _drawLabels(Canvas canvas, Rect rect) {
    for (final value in [0, 50, 100]) {
      final y = rect.bottom - rect.height * value / 100;
      _drawText(canvas, '$value%', Offset(0, y - 7), 11);
    }
    _drawText(canvas, '-5 min', Offset(rect.left, rect.bottom + 8), 11);
    _drawText(
        canvas, 'Maintenant', Offset(rect.right - 58, rect.bottom + 8), 11);
  }

  void _drawLine(
    Canvas canvas,
    Rect rect,
    DateTime start,
    DateTime end,
    Color color,
    double Function(MonitoringSample sample) valueOf,
  ) {
    final totalMs = end.difference(start).inMilliseconds;
    if (totalMs <= 0) return;

    final path = Path();
    var hasPoint = false;
    for (final sample in samples) {
      final elapsedMs = sample.timestamp.difference(start).inMilliseconds;
      final x = rect.left + rect.width * elapsedMs.clamp(0, totalMs) / totalMs;
      final value = valueOf(sample).clamp(0.0, 100.0);
      final y = rect.bottom - rect.height * value / 100;
      if (!hasPoint) {
        path.moveTo(x, y);
        hasPoint = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawLegend(Canvas canvas, Size size) {
    _drawLegendItem(canvas, Offset(size.width - 132, 8), cpuColor, 'CPU');
    _drawLegendItem(canvas, Offset(size.width - 72, 8), ramColor, 'RAM');
  }

  void _drawLegendItem(
      Canvas canvas, Offset offset, Color color, String label) {
    canvas.drawLine(
      offset,
      offset.translate(18, 0),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    _drawText(canvas, label, offset.translate(24, -7), 11);
  }

  void _drawEmptyState(Canvas canvas, Rect rect) {
    _drawText(
      canvas,
      'Historique en cours de collecte',
      Offset(rect.left + 12, rect.center.dy - 8),
      12,
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_HistoryLineChartPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.cpuColor != cpuColor ||
        oldDelegate.ramColor != ramColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}
