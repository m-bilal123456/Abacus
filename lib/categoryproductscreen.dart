import 'package:abacus/cart_provider.dart';
import 'package:abacus/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Helper to convert numbers to Urdu numerals
String toUrduNumber(dynamic number) {
  const english = ['0','1','2','3','4','5','6','7','8','9'];
  const urdu = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
  String str = number.toString();
  for(int i=0;i<english.length;i++){
    str = str.replaceAll(english[i], urdu[i]);
  }
  return str;
}

class CategoryProductsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryProductsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
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
                onChanged: (value) {
                  searchProv.updateQuery(value);
                },
                decoration: InputDecoration(
                  hintText: "$categoryName میں تلاش کریں...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchProv.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchProv.updateQuery("");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: EdgeInsets.zero,
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
          List<int> filteredItems = List.generate(7, (i) => i).where((i) {
            return "Item $i".toLowerCase().contains(searchProv.query.toLowerCase());
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (_, index) {
              int i = filteredItems[index];
              int price = 500; // Price per item
              int qty = 1; // Default quantity

              return StatefulBuilder(
                builder: (context, setState) {
                  int totalPrice = price * qty;

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
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Image.network(
                              "https://cdn-icons-png.flaticon.com/512/415/415733.png",
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "آئٹم $i",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "₨${toUrduNumber(price)} فی آئٹم",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(height: 5),

                        // Quantity selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (qty > 1) {
                                  setState(() {
                                    qty--;
                                  });
                                }
                              },
                            ),
                            Text(
                              toUrduNumber(qty),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  qty++;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Show total price for selected quantity
                        Text(
                          "کل قیمت: ₨${toUrduNumber(totalPrice)}",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),

                        const SizedBox(height: 5),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              Provider.of<CartProvider>(context, listen: false)
                                  .addToCart({
                                "name": "آئٹم $i",
                                "price": price,
                                "qty": qty,
                                "image": "https://via.placeholder.com/150"
                              });
                            },
                            child: const Text("کارٹ میں شامل کریں"),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
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
