import 'package:abacus/cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'orderdetailscreen.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  String userId = "";
  bool loadingUser = true;

  // Filters
  String selectedPayment = "All"; // All, Paid, Unpaid, Pending
  String selectedSort = "Newest"; // Newest / Oldest

  late Stream<QuerySnapshot> ordersStream;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // 🔹 Helper to safely lowercase a value
  String safeLowerCase(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.toLowerCase();
    return value.toString().toLowerCase();
  }

  Future<void> _loadUserId() async {
    final id = await readData("customerId");
    if (id != null && id.isNotEmpty) {
      setState(() {
        userId = id;
        loadingUser = false;

        // 🔹 Stream only pending orders
        ordersStream = FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .snapshots();
      });
    } else {
      setState(() => loadingUser = false);
    }
  }

  Color _statusColor(String status) {
    switch (safeLowerCase(status)) {
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

  Color _paymentColor(String payment) {
    switch (safeLowerCase(payment)) {
      case "paid":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "unpaid":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelOrder(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(docId)
          .update({'status': 'cancelled'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order cancelled successfully")));
      }
    }
  }

  List<Map<String, dynamic>> _sortAndFilterOrders(List<Map<String, dynamic>> orders) {
    final filtered = orders.where((data) {
      final orderId = safeLowerCase(data['order_id']);
      final payment = safeLowerCase(data['payment_status']);

      final matchesSearch = orderId.contains(searchCtrl.text.toLowerCase());
      final matchesPayment =
          selectedPayment.toLowerCase() == "all" || payment == selectedPayment.toLowerCase();

      return matchesSearch && matchesPayment;
    }).toList();

    filtered.sort((a, b) {
      final aTime = a['createdAt'] is Timestamp
          ? (a['createdAt'] as Timestamp).toDate()
          : DateTime(2000);
      final bTime = b['createdAt'] is Timestamp
          ? (b['createdAt'] as Timestamp).toDate()
          : DateTime(2000);

      return selectedSort == "Newest" ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });

    return filtered;
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
        body: Center(child: Text("No user found")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Active Orders")),
      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search by Order ID",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Filters Row: Payment + Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text("Payment: "),
                const SizedBox(width: 5),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedPayment,
                    items: const [
                      DropdownMenuItem(value: "All", child: Text("All")),
                      DropdownMenuItem(value: "paid", child: Text("Paid")),
                      DropdownMenuItem(value: "unpaid", child: Text("Unpaid")),
                      DropdownMenuItem(value: "pending", child: Text("Pending")),
                    ],
                    onChanged: (value) {
                      setState(() => selectedPayment = value!);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Text("Sort: "),
                const SizedBox(width: 5),
                DropdownButton<String>(
                  value: selectedSort,
                  items: const [
                    DropdownMenuItem(value: "Newest", child: Text("Newest")),
                    DropdownMenuItem(value: "Oldest", child: Text("Oldest")),
                  ],
                  onChanged: (value) {
                    setState(() => selectedSort = value!);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ordersStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['doc_id'] = doc.id;
                  return data;
                }).toList();

                final sortedFilteredOrders = _sortAndFilterOrders(orders);

                if (sortedFilteredOrders.isEmpty) {
                  return const Center(child: Text("No pending orders found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedFilteredOrders.length,
                  itemBuilder: (context, index) {
                    final data = sortedFilteredOrders[index];
                    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                    final createdAt = data['createdAt'] is Timestamp
                        ? (data['createdAt'] as Timestamp).toDate()
                        : null;
                    final dateFormatted = createdAt != null
                        ? "${createdAt.day}-${createdAt.month}-${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}"
                        : "Unknown";
                    final docId = data['doc_id'] ?? "";
                    final paymentStatus = data['payment_status']?.toString() ?? "unpaid";

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Order ID: ${data['order_id'] ?? "Unknown"}",
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => _cancelOrder(docId),
                                    child: const Text("Cancel"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text("Date: $dateFormatted"),
                              Text("Total: Rs. ${data['grand_total'] ?? "0"}"),
                              const SizedBox(height: 6),

                              // Status and Payment together
                              Row(
                                children: [
                                  Text("Status: ${data['status'] ?? "Unknown"}",
                                      style: TextStyle(
                                          color: _statusColor(data['status'] ?? ""),
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 20),
                                  Text("Payment: $paymentStatus",
                                      style: TextStyle(
                                          color: _paymentColor(paymentStatus),
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),

                              const SizedBox(height: 10),
                              const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                              ...items.map((item) {
                                final name = item['name'] ?? "Unknown";
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
