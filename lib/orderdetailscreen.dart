import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List<dynamic>? ?? [];
    final createdAt = order['created_at'] is Timestamp
        ? (order['created_at'] as Timestamp).toDate()
        : null;

    final dateFormatted =
        createdAt != null ? DateFormat('d MMMM yyyy, hh:mm a').format(createdAt) : "نامعلوم";

    return Scaffold(
      appBar: AppBar(title: const Text("آرڈر کی تفصیل")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // HEADER
              detailRow("آرڈر نمبر", order['order_id'] ?? "نامعلوم"),
              detailRow("تاریخ", dateFormatted),
              detailRow(
                "اسٹیٹس",
                order['status'] ?? "نامعلوم",
                color: (order['status'] ?? "").toLowerCase() == "completed"
                    ? Colors.green
                    : (order['status'] ?? "").toLowerCase() == "pending"
                        ? Colors.orange
                        : Colors.red,
              ),
              const SizedBox(height: 20),

              // HORIZONTAL SCROLLABLE ITEMS TABLE
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    // HEADER ROW
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
                    const Divider(height: 0, color: Colors.black26),

                    // ITEMS ROWS
                    ...items.map((item) {
                      final name = item['name'] ?? "نامعلوم";
                      final qty = item['qty']?.toString() ?? "0";
                      final price = item['price']?.toString() ?? "0";
                      final total = item['total']?.toString() ?? "0";
                      final imageUrl = item['image'] ?? "";

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Row(
                          children: [
                            // IMAGE
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image),
                                    )
                                  : const Icon(Icons.image),
                            ),
                            const SizedBox(width: 10),

                            // ITEM NAME
                            SizedBox(
                              width: 150,
                              child: Text(name, textAlign: TextAlign.center),
                            ),

                            // QUANTITY
                            SizedBox(
                              width: 70,
                              child: Text(qty, textAlign: TextAlign.center),
                            ),

                            // PRICE
                            SizedBox(
                              width: 80,
                              child: Text("Rs. $price", textAlign: TextAlign.center),
                            ),

                            // TOTAL
                            SizedBox(
                              width: 80,
                              child: Text("Rs. $total", textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

  Widget detailRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
