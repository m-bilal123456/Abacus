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

  String userName = "";
  String userPhone = "";

  // Filters
  String selectedSort = "Newest";
  String selectedStatus = "All";
  String selectedPayment = "All";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await readData("name");
    final phone = await readData("phoneno");

    setState(() {
      userName = name?.trim() ?? "";
      userPhone = phone?.trim() ?? "";
    });
  }

  Stream<QuerySnapshot> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('customer.name', isEqualTo: userName)
        .where('customer.phone', isEqualTo: userPhone)
        .snapshots();
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

  List<Map<String, dynamic>> _sortOrders(
      List<Map<String, dynamic>> orders, String sortOption) {
    final sorted = List<Map<String, dynamic>>.from(orders);

    switch (sortOption) {
      case "Newest":
        sorted.sort((a, b) {
          final aTime = a['created_at'] is Timestamp
              ? (a['created_at'] as Timestamp).toDate()
              : DateTime(2000);
          final bTime = b['created_at'] is Timestamp
              ? (b['created_at'] as Timestamp).toDate()
              : DateTime(2000);
          return bTime.compareTo(aTime);
        });
        break;
      case "Oldest":
        sorted.sort((a, b) {
          final aTime = a['created_at'] is Timestamp
              ? (a['created_at'] as Timestamp).toDate()
              : DateTime(2000);
          final bTime = b['created_at'] is Timestamp
              ? (b['created_at'] as Timestamp).toDate()
              : DateTime(2000);
          return aTime.compareTo(bTime);
        });
        break;
      case "Highest Total":
        sorted.sort((a, b) =>
            (b['grand_total'] ?? 0).compareTo(a['grand_total'] ?? 0));
        break;
      case "Lowest Total":
        sorted.sort((a, b) =>
            (a['grand_total'] ?? 0).compareTo(b['grand_total'] ?? 0));
        break;
    }

    return sorted;
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'cancelled'});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Order cancelled")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Active Orders")),
      body: userName.isEmpty || userPhone.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 SEARCH
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

                // ⚡ FILTERS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Order Status Filter
                        Flexible(
                          child: Row(
                            children: [
                              const Text("Order Status: "),
                              const SizedBox(width: 5),
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true, // ensures it uses available space
                                  value: selectedStatus,
                                  items: const [
                                    DropdownMenuItem(value: "All", child: Text("All")),
                                    DropdownMenuItem(value: "pending", child: Text("Pending")),
                                    DropdownMenuItem(value: "completed", child: Text("Completed")),
                                    DropdownMenuItem(value: "cancelled", child: Text("Cancelled")),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedStatus = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Payment Status Filter
                        Flexible(
                          child: Row(
                            children: [
                              const Text("Payment Status: "),
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
                                    setState(() {
                                      selectedPayment = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ⚡ SORT DROPDOWN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text("Sort by: "),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: selectedSort,
                        items: const [
                          DropdownMenuItem(value: "Newest", child: Text("Newest")),
                          DropdownMenuItem(value: "Oldest", child: Text("Oldest")),
                          DropdownMenuItem(
                              value: "Highest Total", child: Text("Highest Total")),
                          DropdownMenuItem(
                              value: "Lowest Total", child: Text("Lowest Total")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedSort = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // 📦 ORDERS LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _ordersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No active orders found",
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }

                      final filteredDocs = snapshot.data!.docs
                          .map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            data['doc_id'] = doc.id;
                            return data;
                          })
                          .where((data) {
                        final status =
                            (data['status'] ?? '').toString().toLowerCase();
                        final payment =
                            (data['payment_status'] ?? '').toString().toLowerCase();

                        if (status == 'cancelled') return false;

                        final matchesSearch = data['order_id']
                            .toString()
                            .toLowerCase()
                            .contains(searchCtrl.text.toLowerCase());

                        final matchesStatus =
                            selectedStatus == "All" || status == selectedStatus;

                        final matchesPayment =
                            selectedPayment == "All" || payment == selectedPayment;

                        return matchesSearch && matchesStatus && matchesPayment;
                      }).toList();

                      final sortedDocs = _sortOrders(filteredDocs, selectedSort);

                      if (sortedDocs.isEmpty) {
                        return const Center(
                          child: Text("No active orders found"),
                        );
                      }

                      return ListView.builder(
  padding: const EdgeInsets.all(12),
  itemCount: sortedDocs.length,
  itemBuilder: (context, index) {
    final data = sortedDocs[index];
    final items = data['items'] as List<dynamic>? ?? [];
    final paymentStatus =
        (data['payment_status'] ?? 'unpaid').toString();
    final docId = data['doc_id'] ?? '';

    final isUrgent = (data['status'] ?? '').toString().toLowerCase() ==
            'pending' &&
        paymentStatus.toLowerCase() == 'unpaid';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: data),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Row: Order ID + Cancel Button ---
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          "Order ID: ${data['order_id'] ?? "Unknown"}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: constraints.maxWidth * 0.3),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => _cancelOrder(docId),
                          child: const Text(
                            "Cancel",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 6),

              Text("Total: Rs. ${data['grand_total'] ?? 0}"),
              const SizedBox(height: 6),
              Text(
                "Status: ${data['status'] ?? "Unknown"}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                "Payment: $paymentStatus",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _paymentColor(paymentStatus),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                "Items:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              // --- Scrollable item list ---
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 150, // max height for items list
                ),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final name = item['name'] ?? "Unknown";
                    final qty = item['qty']?.toString() ?? "0";
                    return Text(
                      "$name x $qty",
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
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
