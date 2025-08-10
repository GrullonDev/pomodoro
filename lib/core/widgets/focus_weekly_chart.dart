import 'package:flutter/material.dart';

class FocusWeeklyChart extends StatelessWidget {
  final Map<String, int> data; // key yyyy-m-d -> seconds
  final Color barColor;
  final Color avgLineColor;
  const FocusWeeklyChart(
      {super.key,
      required this.data,
      this.barColor = Colors.greenAccent,
      this.avgLineColor = Colors.white70});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = (entries
        .map((e) => e.value)
        .fold<int>(0, (a, b) => b > a ? b : a)).clamp(1, 1 << 31);
    // 3-day moving average list aligned to entries
    final List<double> movingAvg = [];
    for (int i = 0; i < entries.length; i++) {
      int start = (i - 2).clamp(0, i);
      final slice = entries.sublist(start, i + 1).map((e) => e.value).toList();
      movingAvg.add(slice.reduce((a, b) => a + b) / slice.length.toDouble());
    }
    return CustomPaint(
      size: const Size(double.infinity, 160),
      painter: _FocusChartPainter(
          entries: entries,
          maxVal: maxVal,
          movingAvg: movingAvg,
          barColor: barColor,
          avgLineColor: avgLineColor),
    );
  }
}

class _FocusChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int maxVal;
  final List<double> movingAvg;
  final Color barColor;
  final Color avgLineColor;
  _FocusChartPainter(
      {required this.entries,
      required this.maxVal,
      required this.movingAvg,
      required this.barColor,
      required this.avgLineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = barColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final avgPaint = Paint()
      ..color = avgLineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final textPainter =
        TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final barWidth = size.width / (entries.length * 2); // spacing
    final chartHeight = size.height - 18; // bottom labels space
    // Bars
    for (int i = 0; i < entries.length; i++) {
      final v = entries[i].value.toDouble();
      final h = (v / maxVal) * (chartHeight - 10);
      final xCenter = (i + 0.5) * (size.width / entries.length);
      final rect = Rect.fromCenter(
          center: Offset(xCenter, chartHeight - h / 2),
          width: barWidth,
          height: h);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)), barPaint);
      // value label if enough space
      if (h > 24 && v > 0) {
        final label = (v / 60).round().toString();
        textPainter.text = const TextSpan(text: '', style: TextStyle());
        textPainter.text = TextSpan(
            text: label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black));
        textPainter.layout();
        textPainter.paint(canvas,
            Offset(xCenter - textPainter.width / 2, chartHeight - h + 4));
      }
      // date label
      final parts = entries[i].key.split('-');
      final dateLabel = '${parts[1]}/${parts[2]}';
      textPainter.text = TextSpan(
          text: dateLabel,
          style: const TextStyle(fontSize: 10, color: Colors.greenAccent));
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(xCenter - textPainter.width / 2, chartHeight + 2));
    }
    // Moving average path
    final path = Path();
    for (int i = 0; i < entries.length; i++) {
      final v = movingAvg[i];
      final y = chartHeight - (v / maxVal) * (chartHeight - 10);
      final x = (i + 0.5) * (size.width / entries.length);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, avgPaint);
  }

  @override
  bool shouldRepaint(covariant _FocusChartPainter old) =>
      old.entries != entries ||
      old.maxVal != maxVal ||
      old.movingAvg != movingAvg;
}
