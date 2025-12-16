import 'package:flutter/material.dart';
import 'orderdetailscreen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  String selectedStatus = "سب";

  // Dummy past orders
  final List<Map<String, dynamic>> allOrders = [
    {
      "orderId": "ORD-1001",
      "date": "10 ستمبر 2025",
      "amount": "Rs. 2,450",
      "status": "مکمل",
    },
    {
      "orderId": "ORD-1002",
      "date": "12 ستمبر 2025",
      "amount": "Rs. 1,120",
      "status": "مکمل",
    },
    {
      "orderId": "ORD-1003",
      "date": "14 ستمبر 2025",
      "amount": "Rs. 3,800",
      "status": "منسوخ",
    },
  ];

  List<Map<String, dynamic>> get filteredOrders {
    return allOrders.where((order) {
      final matchesSearch = order['orderId']
          .toString()
          .toLowerCase()
          .contains(searchCtrl.text.toLowerCase());
      final matchesStatus =
          selectedStatus == "سب" || order['status'] == selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("میرے آرڈر")),
      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "آرڈر نمبر تلاش کریں",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 🎯 FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("فلٹر کریں: "),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: "سب", child: Text("سب")),
                    DropdownMenuItem(value: "مکمل", child: Text("مکمل")),
                    DropdownMenuItem(value: "منسوخ", child: Text("منسوخ")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 📦 ORDER LIST
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(
                    child: Text(
                      "کوئی آرڈر نہیں ملا",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];

                      // ✅ Tap to order details, always returns a Widget
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: order),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "آرڈر نمبر: ${order['orderId']}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text("تاریخ: ${order['date']}"),
                                Text("رقم: ${order['amount']}"),
                                const SizedBox(height: 6),
                                Text(
                                  "اسٹیٹس: ${order['status']}",
                                  style: TextStyle(
                                    color: order['status'] == "مکمل"
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
