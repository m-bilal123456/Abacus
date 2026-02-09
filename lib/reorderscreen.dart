import 'package:abacus/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orderdetailscreen.dart';

class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String selectedStatus = "All"; // "All", "Delivered", "Cancelled"
  late final Stream<QuerySnapshot> _ordersStream;

  void log(String msg) {
    // ignore: avoid_print
    print("🟣 [REORDER] $msg");
  }

  @override
  void initState() {
    super.initState();

    // 🔹 Fetch all orders for this user, order by createdAt descending
    _ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    log("Orders stream initialized for uid=$uid");
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Color orderStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color paymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reorder")),
      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: "Search by Order ID",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 🎯 Status Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: "All", child: Text("All")),
                DropdownMenuItem(value: "Delivered", child: Text("Delivered")),
                DropdownMenuItem(value: "Cancelled", child: Text("Cancelled")),
              ],
              onChanged: (v) => setState(() => selectedStatus = v!),
            ),
          ),

          const SizedBox(height: 10),

          // 📦 Orders list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                log("Stream state: ${snapshot.connectionState}");

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No orders found"));
                }

                // 🔹 Filter orders locally
                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();

                  // Only delivered or cancelled
                  if (status != 'delivered' && status != 'cancelled') return false;

                  // Filter by dropdown
                  if (selectedStatus == "Delivered" && status != 'delivered') return false;
                  if (selectedStatus == "Cancelled" && status != 'cancelled') return false;

                  // Search by order_id
                  final orderId = (data['order_id'] ?? '').toString().toLowerCase();
                  if (!orderId.contains(searchCtrl.text.toLowerCase())) return false;

                  return true;
                }).toList();

                log("Filtered orders count: ${docs.length}");

                if (docs.isEmpty) {
                  return const Center(child: Text("No orders found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

                    final orderStatus = (data['status'] ?? '').toString().toLowerCase();
                    final paymentStatus = (data['payment_status'] ?? '').toString().toLowerCase();

                    return InkWell(
                      onTap: () {
                        log("Opening details for ${data['order_id']}");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: data),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Order ID: ${data['order_id']}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text("Total: Rs. ${data['grand_total'] ?? 0}"),
                              Text(
                                "Status: ${orderStatus.toUpperCase()}",
                                style: TextStyle(
                                  color: orderStatusColor(orderStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Payment: ${paymentStatus.toUpperCase()}",
                                style: TextStyle(
                                  color: paymentStatusColor(paymentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              ...items.map((i) => Text("${i['name']} x ${i['qty']}")),

                              const SizedBox(height: 10),

                              ElevatedButton(
                                onPressed: () {
                                  final cart = context.read<CartProvider>();

                                  cart.clearCart();
                                  for (final item in items) {
                                    cart.addToCart({
                                      "name": item['name'],
                                      "price": item['price'],
                                      "pack": item['pack'] ?? "",
                                      "qty": item['qty'],
                                      "image": item['image'] ?? "",
                                    });
                                  }

                                  Navigator.pop(context, true);
                                },
                                child: const Text("Reorder"),
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
