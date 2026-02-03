import 'package:abacus/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:abacus/cache.dart';

class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  String userName = "";
  String userPhone = "";
  final TextEditingController searchCtrl = TextEditingController();

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

  /// 🔥 Only Completed, Delivered & Cancelled orders
  Stream<QuerySnapshot> _userOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('customer.name', isEqualTo: userName)
        .where('customer.phone', isEqualTo: userPhone)
        .where('status', whereIn: ['completed', 'delivered', 'cancelled'])
        .snapshots();
  }

  // ---------------- HELPERS ----------------

  String toUrduNumber(dynamic number) {
    const english = ['0','1','2','3','4','5','6','7','8','9'];
    // ignore: unused_local_variable
    const urdu = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    String str = number.toString();
    for (int i = 0; i < english.length; i++) {
      str = str.replaceAll(english[i], english[i]);
    }
    return str;
  }

  /// 🟢🔴 Order status color
  Color orderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 💰 Payment color
  Color paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'partial':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  /// 💬 Payment text (English)
  String paymentText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return "Paid";
      case 'unpaid':
        return "Unpaid";
      case 'pending':
        return "Pending";
      case 'partial':
        return "Partial";
      default:
        return status;
    }
  }

  /// 📦 Order status text (English)
  String orderStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return "Completed";
      case 'cancelled':
        return "Cancelled";
      default:
        return status;
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userName.isEmpty || userPhone.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Reorder")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No completed, delivered, or cancelled orders found"),
            );
          }

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

          /// 🔍 Search
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['order_id']
                .toString()
                .toLowerCase()
                .contains(searchCtrl.text.toLowerCase());
          }).toList();

          /// 🔃 Sort: completed/delivered first → cancelled later → newest first
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            int priority(String status) {
              if (status == 'completed' || status == 'delivered') return 0;
              if (status == 'cancelled') return 1;
              return 2;
            }

            final p = priority(aData['status'])
                .compareTo(priority(bData['status']));
            if (p != 0) return p;

            final aTime = aData['created_at'] as Timestamp?;
            final bTime = bData['created_at'] as Timestamp?;
            return (bTime?.millisecondsSinceEpoch ?? 0)
                .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
          });

          return Column(
            children: [
              /// 🔍 SEARCH
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: "Search by Order ID",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              /// 📦 LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final items = data['items'] as List<dynamic>? ?? [];
                    final grandTotal = data['grand_total'] ?? 0;
                    final paymentStatus =
                        (data['payment_status'] ?? 'unpaid').toString();
                    final orderStatus =
                        (data['status'] ?? '').toString();

                    return Card(
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
                              "Order ID: ${data['order_id'] ?? "N/A"}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),

                            Text("Total: ₨${toUrduNumber(grandTotal)}"),

                            /// 📦 ORDER STATUS
                            Text(
                              "Status: ${orderStatusText(orderStatus)}",
                              style: TextStyle(
                                color: orderStatusColor(orderStatus),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            /// 💰 PAYMENT STATUS
                            Text(
                              "Payment: ${paymentText(paymentStatus)}",
                              style: TextStyle(
                                color: paymentStatusColor(paymentStatus),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),
                            const Text("Items:",
                                style: TextStyle(fontWeight: FontWeight.bold)),

                            ...items.map((item) {
                              final name = item['name'] ?? "N/A";
                              final qty = item['qty']?.toString() ?? "0";
                              final available = item['available'] ?? true;

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("$name x $qty"),
                                  if (!available)
                                    const Text(
                                      "Out of Stock",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                ],
                              );
                            }),

                            const SizedBox(height: 12),

                            /// 🔁 REORDER
                            ElevatedButton(
                              onPressed: () {
                                final cart = Provider.of<CartProvider>(
                                  context,
                                  listen: false,
                                );

                                for (var item in items) {
                                  if (item['available'] == false) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text("Some items are out of stock"),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                cart.clearCart();
                                for (var item in items) {
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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
