import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'base_card.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final String currency;
  final int? transactionCount;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.currency = 'Rp',
    this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard.highlight(
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (transactionCount != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$transactionCount transaksi',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currency${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
