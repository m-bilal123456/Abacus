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
  String selectedStatus = "سب";

  String userName = "";
  String userPhone = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final name = await readData("name");
    final phone = await readData("phoneno");

    setState(() {
      userName = name?.trim() ?? "";
      userPhone = phone?.trim() ?? "";
    });
  }

  Stream<QuerySnapshot> userOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('customer.name', isEqualTo: userName)
        .where('customer.phone', isEqualTo: userPhone)
        .orderBy('created_at', descending: true)
        .snapshots();
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

                // 🎯 STATUS FILTER
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

                // 📦 ORDERS LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: userOrdersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "کوئی آرڈر نہیں ملا",
                            style: TextStyle(fontSize: 18),
                          ),
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

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final items = data['items'] as List<dynamic>? ?? [];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailScreen(order: data),
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
                                      "آرڈر نمبر: ${data['order_id'] ?? "نامعلوم"}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "تاریخ: ${data['created_at'] is Timestamp ? (data['created_at'] as Timestamp).toDate() : "نامعلوم"}",
                                    ),
                                    Text(
                                      "رقم: Rs. ${data['grand_total'] ?? "0"}",
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "اسٹیٹس: ${data['status'] ?? "نامعلوم"}",
                                      style: TextStyle(
                                        color: (data['status'] ?? "").toLowerCase() == "completed"
                                            ? Colors.green
                                            : (data['status'] ?? "").toLowerCase() == "pending"
                                                ? Colors.orange
                                                : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "آئٹمز:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
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
