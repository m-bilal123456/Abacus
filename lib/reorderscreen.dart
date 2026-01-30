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
  String selectedStatus = "سب";

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

  Stream<QuerySnapshot> _userOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('customer.name', isEqualTo: userName)
        .where('customer.phone', isEqualTo: userPhone)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  String toUrduNumber(dynamic number) {
    const english = ['0','1','2','3','4','5','6','7','8','9'];
    const urdu = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    String str = number.toString();
    for(int i=0;i<english.length;i++){
      str = str.replaceAll(english[i], urdu[i]);
    }
    return str;
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
      appBar: AppBar(title: const Text("میرے پچھلے آرڈر")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("کوئی آرڈر نہیں ملا", style: TextStyle(fontSize: 18)),
            );
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final matchesSearch = data['order_id']
                .toString()
                .toLowerCase()
                .contains(searchCtrl.text.toLowerCase());

            final matchesStatus =
                selectedStatus == "سب" || data['status'] == selectedStatus;

            return matchesSearch && matchesStatus;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("کوئی آرڈر نہیں ملا"));
          }

          return Column(
            children: [
              // SEARCH & STATUS FILTER
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
                        DropdownMenuItem(value: "pending", child: Text("زیرِ التواء")),
                        DropdownMenuItem(value: "completed", child: Text("مکمل")),
                        DropdownMenuItem(value: "cancelled", child: Text("منسوخ")),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final items = data['items'] as List<dynamic>? ?? [];
                    final grandTotal = data['grand_total'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("آرڈر نمبر: ${data['order_id'] ?? "نامعلوم"}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("تاریخ: ${data['created_at'] is Timestamp ? (data['created_at'] as Timestamp).toDate() : "نامعلوم"}"),
                            Text("کل رقم: ₨${toUrduNumber(grandTotal)}"),
                            const SizedBox(height: 6),
                            Text("اسٹیٹس: ${data['status'] ?? "نامعلوم"}",
                                style: TextStyle(
                                  color: (data['status'] ?? "").toLowerCase() == "completed"
                                      ? Colors.green
                                      : (data['status'] ?? "").toLowerCase() == "pending"
                                          ? Colors.orange
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 10),
                            const Text("آئٹمز:", style: TextStyle(fontWeight: FontWeight.bold)),
                            ...items.map((item) {
                              final name = item['name'] ?? "نامعلوم";
                              final qty = item['qty']?.toString() ?? "0";
                              final available = item['available'] ?? true;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("$name x $qty"),
                                  if (!available)
                                    const Text("خارج از اسٹاک",
                                        style: TextStyle(color: Colors.red)),
                                ],
                              );
                            }).toList(),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                final cart = Provider.of<CartProvider>(context, listen: false);
                                bool canReorder = true;

                                for (var item in items) {
                                  if (item['available'] == false) {
                                    canReorder = false;
                                    break;
                                  }
                                }

                                if (!canReorder) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("کچھ آئٹمز اسٹاک میں نہیں ہیں")),
                                  );
                                  return;
                                }

                                // Clear cart and add items
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

                                // POP AND SIGNAL ProductScreen TO GO TO CART
                                Navigator.pop(context, true);
                              },
                              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                              child: const Text("دوبارہ آرڈر کریں"),
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
