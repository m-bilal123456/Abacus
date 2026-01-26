import 'package:abacus/cache.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Helper to convert numbers to Urdu numerals
String toUrduNumber(dynamic number) {
  const english = ['0','1','2','3','4','5','6','7','8','9'];
  // ignore: unused_local_variable
  const urdu = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
  String str = number.toString();
  for(int i=0;i<english.length;i++){
    str = str.replaceAll(english[i], english[i]);
  }
  return str;
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

String generateOrderId() {
  return "ORD-${DateTime.now().millisecondsSinceEpoch}";
}

Future<Map<String, dynamic>> _getCustomerFromCache() async {
  final name = await readData("name");
  final phone = await readData("phoneno");
  final shop = await readData("shopname");
  final lat = await readData("latitude");
  final lng = await readData("longitude");

  return {
    "name": name ?? "نام موجود نہیں",
    "phone": phone ?? "",
    "shop_name": shop ?? "",
    "location": {
      "latitude": lat,
      "longitude": lng,
    }
  };
}



Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
  final customer = await _getCustomerFromCache();

  final orderId = "ORD-${DateTime.now().millisecondsSinceEpoch}";

  final order = {
    "order_id": orderId,

    // 👤 Customer (from ProfileScreen)
    "customer": {
      "name": customer["name"],
      "phone": customer["phone"],
      "shop_name": customer["shop_name"],
      "location": customer["location"],
    },

    // 🛒 Items
    "items": cart.cart.map((item) {
      return {
        "name": item["name"],
        "price": item["price"],
        "qty": item["qty"],
        "total": item["price"] * item["qty"],
        "image": item["image"] ?? "",
      };
    }).toList(),

    // 💰 Meta
    "grand_total": cart.totalPrice,
    "status": "unpaid", // pending → confirmed → delivered
    "created_at": FieldValue.serverTimestamp(),
  };

  await FirebaseFirestore.instance
      .collection("orders")
      .doc(orderId) // order ID = document ID
      .set(order);

  cart.clearCart();
}




void _showCheckoutDialog(BuildContext context, CartProvider cart) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _getCustomerFromCache(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final customer = snapshot.data!;

          return AlertDialog(
            title: const Text("آرڈر کی تصدیق"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 👤 Customer Info
                  Text("نام: ${customer["name"]}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("فون: ${customer["phone"]}"),
                  Text("دکان: ${customer["shop_name"]}"),

                  const SizedBox(height: 10),
                  const Divider(),

                  // 🛒 Items
                  ...cart.cart.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item["name"])),
                          Text(
                            "₨${toUrduNumber(item["price"] * item["qty"])}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(),

                  // 💰 Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("کل رقم:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "₨${toUrduNumber(cart.totalPrice)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("نہیں"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("آرڈر کریں"),
                onPressed: () async {
                  Navigator.pop(context);

                  await _placeOrder(context, cart);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("آرڈر کامیابی سے موصول ہو گیا")),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}




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
                                          "فی آئٹم: ${toUrduNumber(item["pack"])}",
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
                            onPressed: items.isEmpty
                              ? null
                              : () {
                                  _showCheckoutDialog(context, cart);
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
