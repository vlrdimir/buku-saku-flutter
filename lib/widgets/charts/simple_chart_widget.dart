import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

abstract class ChartDataPoint {
  String get date;
  double get income;
  double get expense;
  String get dayName;
}

/// Simple chart data implementation
class SimpleChartDataPoint implements ChartDataPoint {
  @override
  final String date;
  @override
  final double income;
  @override
  final double expense;
  @override
  final String dayName;

  const SimpleChartDataPoint({
    required this.date,
    required this.income,
    required this.expense,
    required this.dayName,
  });
}

class SimpleChartWidget extends StatefulWidget {
  final List<ChartDataPoint> data;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;

  const SimpleChartWidget({
    super.key,
    required this.data,
    this.title = 'Grafik 7 Hari Terakhir',
    this.primaryColor = Colors.green,
    this.secondaryColor = Colors.red,
  });

  @override
  State<SimpleChartWidget> createState() => _SimpleChartWidgetState();
}

class _SimpleChartWidgetState extends State<SimpleChartWidget> {
  int? _selectedIndex;
  Offset? _tapPosition;

  void _handleTap(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    
    // Find the nearest data point
    final double padding = 60.0;
    final double chartWidth = box.size.width - 2 * padding;
    final double xStep = chartWidth / (widget.data.length - 1);
    
    for (int i = 0; i < widget.data.length; i++) {
      final double x = padding + i * xStep;
      if ((localPosition.dx - x).abs() < 20) { // Within 20 pixels of the point
        setState(() {
          _selectedIndex = i;
          _tapPosition = localPosition;
        });
        return;
      }
    }
    
    // Tapped outside any data point
    setState(() {
      _selectedIndex = null;
      _tapPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Data chart akan ditampilkan ketika API tersedia',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Menunggu data dari backend',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate max values for scaling
    double maxValue = 0;
    for (final point in widget.data) {
      maxValue = maxValue > point.income ? maxValue : point.income;
      maxValue = maxValue > point.expense ? maxValue : point.expense;
    }
    maxValue = maxValue > 0 ? (maxValue / 1000) * 1.2 : 100; // Convert to thousands and add padding

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildLegend('Pengeluaran', widget.secondaryColor),
                  const SizedBox(width: 8),
                  _buildLegend('Pemasukan', widget.primaryColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleChart(maxValue),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(double maxValue) {
    return GestureDetector(
      onTapDown: (details) {
        _handleTap(details);
      },
      child: Stack(
        children: [
          CustomPaint(
            painter: _SimpleChartPainter(
              data: widget.data,
              maxValue: maxValue,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              selectedIndex: _selectedIndex,
            ),
            child: Container(),
          ),
          // Tooltip overlay
          if (_selectedIndex != null && _tapPosition != null)
            _buildTooltip(),
        ],
      ),
    );
  }

  Widget _buildTooltip() {
    final point = widget.data[_selectedIndex!];
    final RenderBox box = context.findRenderObject() as RenderBox;
    final tooltipWidth = 150.0; // Increased width for date
    final tooltipHeight = 100.0; // Estimated height
    final screenWidth = box.size.width;
    
    // Adjust tooltip position to keep it within screen bounds
    double leftPosition = _tapPosition!.dx - 75; // Center of tooltip
    double topPosition = _tapPosition!.dy - tooltipHeight - 20;
    
    // Check if tooltip would go beyond right edge
    if (leftPosition + tooltipWidth > screenWidth) {
      leftPosition = screenWidth - tooltipWidth - 10;
    }
    // Check if tooltip would go beyond left edge
    if (leftPosition < 10) {
      leftPosition = 10;
    }
    // Check if tooltip would go beyond top edge
    if (topPosition < 10) {
      topPosition = _tapPosition!.dy + 20; // Show below instead
    }
    
    return Positioned(
      left: leftPosition,
      top: topPosition,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              point.dayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDate(point.date),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pemasukan: Rp${_formatCurrency(point.income)}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 10,
              ),
            ),
            Text(
              'Pengeluaran: Rp${_formatCurrency(point.expense)}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

class _SimpleChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double maxValue;
  final Color primaryColor;
  final Color secondaryColor;
  final int? selectedIndex;

  _SimpleChartPainter({
    required this.data,
    required this.maxValue,
    required this.primaryColor,
    required this.secondaryColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    
    final Paint incomePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
      
    final Paint expensePaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint dotPaint = Paint()
      ..style = PaintingStyle.fill;

    final padding = 60.0;
    final chartWidth = size.width - 2 * padding;
    final chartHeight = size.height - 2 * padding - 20; // Reserve space for X-axis labels

    // Draw grid lines
    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
      
      // Draw Y-axis labels
      if (i % 2 == 0) { // Show labels for every other line to avoid crowding
        final value = (maxValue * 1000 * (4 - i) / 4);
        final String label = _formatCurrencyValue(value);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        
        textPainter.paint(
          canvas,
          Offset(padding - textPainter.width - 12, y - textPainter.height / 2),
        );
      }
    }

    if (data.isEmpty) return;

    double xStep = chartWidth / (data.length - 1);

    // Draw chart lines
    final incomePath = Path();
    final expensePath = Path();

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = padding + i * xStep;
      final yIncome = padding + chartHeight - (point.income / 1000 / maxValue) * chartHeight;
      final yExpense = padding + chartHeight - (point.expense / 1000 / maxValue) * chartHeight;

      if (i == 0) {
        incomePath.moveTo(x, yIncome);
        expensePath.moveTo(x, yExpense);
      } else {
        incomePath.lineTo(x, yIncome);
        expensePath.lineTo(x, yExpense);
      }
    }

    canvas.drawPath(incomePath, incomePaint);
    canvas.drawPath(expensePath, expensePaint);

    // Draw dots
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = padding + i * xStep;
      final yIncome = padding + chartHeight - (point.income / 1000 / maxValue) * chartHeight;
      final yExpense = padding + chartHeight - (point.expense / 1000 / maxValue) * chartHeight;

      // Highlight selected point
      final bool isSelected = selectedIndex == i;
      final double dotRadius = isSelected ? 6 : 4;

      // Income dots
      dotPaint.color = primaryColor;
      if (isSelected) {
        // Draw white border for selected dot
        final Paint borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, yIncome), dotRadius + 2, borderPaint);
      }
      canvas.drawCircle(Offset(x, yIncome), dotRadius, dotPaint);
      
      // Expense dots
      dotPaint.color = secondaryColor;
      if (isSelected) {
        // Draw white border for selected dot
        final Paint borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, yExpense), dotRadius + 2, borderPaint);
      }
      canvas.drawCircle(Offset(x, yExpense), dotRadius, dotPaint);
    }

    // Draw X-axis labels (dates)
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = padding + i * xStep;
      final y = padding + chartHeight + 25; // Position below the chart

      // Use dayName for better readability (e.g., "Sen", "Sel", etc.)
      final textPainter = TextPainter(
        text: TextSpan(
          text: point.dayName,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  String _formatCurrencyValue(double value) {
    if (value >= 1000000000) {
      // For values 1 billion and above, show like "1.2M"
      final billions = value / 1000000000;
      return '${billions.toStringAsFixed(1).replaceFirst('.0', '')}M';
    } else if (value >= 1000000) {
      // For values 1 million and above, show like "1.2jt"
      final millions = value / 1000000;
      return '${millions.toStringAsFixed(1).replaceFirst('.0', '')}jt';
    } else if (value >= 1000) {
      // For values 1000 and above, format with dots like "1.000"
      return value
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match match) => '${match[1]}.',
          );
    } else {
      // For values less than 1000, just show as integer
      return value.toInt().toString();
    }
  }
}
