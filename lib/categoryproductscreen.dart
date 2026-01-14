import 'package:abacus/cart_provider.dart';
import 'package:abacus/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Helper to convert numbers to Urdu numerals
String toUrduNumber(dynamic number) {
  const english = ['0','1','2','3','4','5','6','7','8','9'];
  const urdu = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
  String str = number.toString();
  for (int i = 0; i < english.length; i++) {
    str = str.replaceAll(english[i], urdu[i]);
  }
  return str;
}

class CategoryProductsScreen extends StatelessWidget {

  /// MUST match Firestore exactly (example: "grocery")
  final String categoryKey;

  const CategoryProductsScreen({
    super.key,
    required this.categoryKey,
  });

  @override
  Widget build(BuildContext context) {

    // 🔍 Debug log (keep this until everything is stable)
    debugPrint("🔥 CATEGORY QUERY => $categoryKey");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: SizedBox(
          height: 40,
          child: Consumer<SearchProvider>(
            builder: (context, searchProv, _) {
              return TextField(
                controller: TextEditingController(text: searchProv.query)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: searchProv.query.length),
                  ),
                onChanged: searchProv.updateQuery,
                decoration: InputDecoration(
                  hintText: "گروسری میں تلاش کریں...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchProv.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => searchProv.updateQuery(""),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            },
          ),
        ),
      ),

      body: Consumer<SearchProvider>(
        builder: (context, searchProv, _) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('category', isEqualTo: categoryKey)
                .snapshots(),

            builder: (context, snapshot) {

              // ❌ Error
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              // ⏳ Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 📭 No products
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "کوئی پروڈکٹ موجود نہیں",
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              // 🔍 Search filter
              final products = snapshot.data!.docs.where((doc) {
                final name = doc['name'].toString().toLowerCase();
                return name.contains(searchProv.query.toLowerCase());
              }).toList();

              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length,

                itemBuilder: (_, index) {
                  final product = products[index];

                  final int price = product['price'];
                  final String name = product['name'];
                  int qty = 1;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      final int totalPrice = price * qty;

                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.grey,
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),

                        child: Column(
                          children: [

                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.network(
                                  "https://cdn-icons-png.flaticon.com/512/415/415733.png",
                                ),
                              ),
                            ),

                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            Text(
                              "₨${toUrduNumber(price)} فی آئٹم",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (qty > 1) setState(() => qty--);
                                  },
                                ),
                                Text(
                                  toUrduNumber(qty),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    setState(() => qty++);
                                  },
                                ),
                              ],
                            ),

                            Text(
                              "کل قیمت: ₨${toUrduNumber(totalPrice)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: ElevatedButton(
                                onPressed: () {
                                  Provider.of<CartProvider>(
                                    context,
                                    listen: false,
                                  ).addToCart({
                                    "name": name,
                                    "price": price,
                                    "qty": qty,
                                    "image": "https://via.placeholder.com/150",
                                  });
                                },
                                child: const Text("کارٹ میں شامل کریں"),
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
