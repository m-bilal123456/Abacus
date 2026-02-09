import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  Color _orderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _orderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _paymentColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _paymentIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.payment;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.money_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = Map<String, dynamic>.from(order['customer'] ?? {});
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);

    final createdAt = order['createdAt'] is DateTime
        ? order['createdAt'] as DateTime
        : order['createdAt'] is Timestamp
            ? (order['createdAt'] as Timestamp).toDate()
            : null;

    final dateFormatted = createdAt != null
        ? DateFormat('d MMMM yyyy, hh:mm a').format(createdAt)
        : "نامعلوم";

    final orderStatus = (order['status'] ?? "نامعلوم").toString();
    final paymentStatus = (order['payment_status'] ?? "نامعلوم").toString();

    return Scaffold(
      appBar: AppBar(title: const Text("آرڈر کی تفصیل")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ORDER INFO
              _detailRow("آرڈر نمبر", order['order_id'] ?? "نامعلوم"),
              _detailRow("تاریخ", dateFormatted),
              _detailRow("کسٹمر", customer['name'] ?? "-"),
              _detailRow("دکان", customer['shop_name'] ?? "-"),
              _detailRow("فون نمبر", customer['phone'] ?? "-"),
              const SizedBox(height: 10),

              // STATUS CHIPS
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  _statusChip(
                    label: "آرڈر اسٹیٹس",
                    value: orderStatus,
                    color: _orderStatusColor(orderStatus),
                    icon: _orderStatusIcon(orderStatus),
                  ),
                  _statusChip(
                    label: "ادائیگی کی حالت",
                    value: paymentStatus,
                    color: _paymentColor(paymentStatus),
                    icon: _paymentIcon(paymentStatus),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ITEMS TABLE
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      color: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      child: Row(
                        children: const [
                          SizedBox(width: 60, child: Text("تصویر", textAlign: TextAlign.center)),
                          SizedBox(width: 10),
                          SizedBox(width: 150, child: Text("نام", textAlign: TextAlign.center)),
                          SizedBox(width: 70, child: Text("مقدار", textAlign: TextAlign.center)),
                          SizedBox(width: 80, child: Text("قیمت", textAlign: TextAlign.center)),
                          SizedBox(width: 80, child: Text("کل", textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const Divider(height: 0),

                    // ITEMS
                    ...items.map((item) {
                      final name = item['name'] ?? "نامعلوم";
                      final qty = item['qty']?.toString() ?? "0";
                      final price = item['price']?.toString() ?? "0";
                      final total = item['total']?.toString() ?? "0";
                      final imageUrl = item['image'] ?? "";

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                                    )
                                  : const Icon(Icons.image),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(width: 150, child: Text(name, textAlign: TextAlign.center)),
                            SizedBox(width: 70, child: Text(qty, textAlign: TextAlign.center)),
                            SizedBox(width: 80, child: Text("Rs. $price", textAlign: TextAlign.center)),
                            SizedBox(width: 80, child: Text("Rs. $total", textAlign: TextAlign.center)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // GRAND TOTAL
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "کل رقم",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    Text(
                      "Rs. ${order['grand_total'] ?? 0}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
