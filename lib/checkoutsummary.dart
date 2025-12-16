import 'package:abacus/cart_provider.dart';
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

class CheckoutSummaryPage extends StatelessWidget {
  const CheckoutSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final items = cart.cart;

        return Scaffold(
          appBar: AppBar(
            title: const Text("خلاصہ چیک آؤٹ"),
            automaticallyImplyLeading: true,
          ),
          body: items.isEmpty
              ? const Center(
                  child: Text(
                    "آپ کا کارٹ خالی ہے",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          int totalPrice = item["price"] * item["qty"];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Image.network(
                                item["image"] ?? "https://via.placeholder.com/150",
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              title: Text(item["name"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "فی آئٹم: ₨${toUrduNumber(item["price"])}"),
                                  Text("تعداد: ${toUrduNumber(item["qty"])}"),
                                  Text(
                                      "کل قیمت: ₨${toUrduNumber(totalPrice)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Total amount at bottom
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "کل رقم:",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₨${toUrduNumber(cart.totalPrice)}",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          // Here you can handle the final payment or order confirmation
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          "ادائیگی کریں",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
        );
      },
    );
  }
}
