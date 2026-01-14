import 'package:abacus/checkoutsummary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

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

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final items = cart.cart;

        return Scaffold(
          appBar: AppBar(
            title: const Text("میرا کارٹ"),
            automaticallyImplyLeading: false,
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

                          return Dismissible(
                            key: Key(item["name"]),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete,
                                  color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => cart.removeItem(index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 5,
                                      offset: Offset(0, 3))
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product image
                                  Image.network(
                                    item["image"] ?? "https://cdn-icons-png.flaticon.com/512/415/415733.png",
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                  ),

                                  // Flexible name & price + controls
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Name
                                        Text(
                                          item["name"],
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold),
                                          softWrap: true,
                                        ),
                                        const SizedBox(height: 3),
                                        // Price per item
                                        Text(
                                          "فی آئٹم: ₨${toUrduNumber(item["price"])}",
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 3),
                                        // Total price
                                        Text(
                                          "کل قیمت: ₨${toUrduNumber(totalPrice)}",
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 5),
                                        // Quantity controls
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.remove_circle_outline),
                                              onPressed: () =>
                                                  cart.decreaseQty(index),
                                            ),
                                            Text(
                                              toUrduNumber(item["qty"]),
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.add_circle_outline),
                                              onPressed: () =>
                                                  cart.increaseQty(index),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  cart.removeItem(index),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom total & checkout
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("کل:",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  "₨${toUrduNumber(cart.totalPrice)}",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: items.isEmpty ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CheckoutSummaryPage(),
                                    ),
                                  );
                                },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: items.isEmpty
                                  ? Colors.grey
                                  : Colors.blue,
                            ),
                            child: const Text("چیک آؤٹ",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
