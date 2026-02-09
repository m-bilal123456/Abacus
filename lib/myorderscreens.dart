import 'package:abacus/cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'orderdetailscreen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  String selectedStatus = "all";
  String userId = "";
  bool loadingUser = true;

  late Stream<QuerySnapshot> ordersStream;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await readData("customerId");
    if (id != null && id.isNotEmpty) {
      setState(() {
        userId = id;
        loadingUser = false;
        // Initialize stream **once** after UID is loaded
        ordersStream = FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: userId)
            .snapshots();
      });
    } else {
      setState(() => loadingUser = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("کوئی یوزر نہیں ملا")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("میرے آرڈر")),
      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}), // only triggers filtering
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
          // 🎯 Status Filter
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
                    DropdownMenuItem(value: "all", child: Text("سب")),
                    DropdownMenuItem(value: "pending", child: Text("زیرِ التواء")),
                    DropdownMenuItem(value: "completed", child: Text("مکمل")),
                    DropdownMenuItem(value: "cancelled", child: Text("منسوخ")),
                  ],
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 📦 Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ordersStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['doc_id'] = doc.id;
                      return data;
                    })
                    .where((data) {
                      final orderId = (data['order_id'] ?? '').toString().toLowerCase();
                      final status = (data['status'] ?? '').toString().toLowerCase();
                      final matchesSearch = orderId.contains(searchCtrl.text.toLowerCase());
                      final matchesStatus = selectedStatus == "all" || status == selectedStatus;
                      return matchesSearch && matchesStatus;
                    })
                    .toList();

                docs.sort((a, b) {
                  final aTime = a['created_at'] is Timestamp
                      ? (a['created_at'] as Timestamp).toDate()
                      : DateTime(2000);
                  final bTime = b['created_at'] is Timestamp
                      ? (b['created_at'] as Timestamp).toDate()
                      : DateTime(2000);
                  return bTime.compareTo(aTime);
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("کوئی آرڈر نہیں ملا"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                    final createdAt = data['created_at'] is Timestamp
                        ? (data['created_at'] as Timestamp).toDate()
                        : null;
                    final dateFormatted = createdAt != null
                        ? "${createdAt.day}-${createdAt.month}-${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}"
                        : "نامعلوم";

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: data)),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("آرڈر نمبر: ${data['order_id'] ?? "نامعلوم"}",
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text("تاریخ: $dateFormatted"),
                              Text("رقم: Rs. ${data['grand_total'] ?? "0"}"),
                              const SizedBox(height: 6),
                              Text("اسٹیٹس: ${data['status'] ?? "نامعلوم"}",
                                  style: TextStyle(
                                      color: _statusColor(data['status'] ?? ""),
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              const Text("آئٹمز:", style: TextStyle(fontWeight: FontWeight.bold)),
                              ...items.map((item) {
                                final name = item['name'] ?? "نامعلوم";
                                final qty = item['qty']?.toString() ?? "0";
                                return Text("$name x $qty");
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
