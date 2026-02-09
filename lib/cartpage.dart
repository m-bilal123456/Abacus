import 'package:abacus/cache.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_provider.dart';

/// Convert English numbers to Urdu numerals
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

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  /// Get customer info from cache
  /// Get customer info from cache with detailed debug logs
Future<Map<String, dynamic>> _getCustomer() async {
  try {
    final name = await readData("name");
    final phone = await readData("phoneno");
    final shopName = await readData("shopname");
    final latitude = await readData("latitude");
    final longitude = await readData("longitude");


    final customer = {
      "name": name ?? "نام موجود نہیں",
      "phone": phone ?? "",
      "shop_name": shopName ?? "",
      "location": {
        "latitude": latitude ?? "",
        "longitude": longitude ?? "",
      }
    };

    return customer;
  } catch (e) {
    return {
      "name": "نام موجود نہیں",
      "phone": "",
      "shop_name": "",
      "location": {"latitude": "", "longitude": ""}
    };
  }
}

/// Checkout confirmation dialog with detailed debug logs
void _checkoutDialog(CartProvider cart) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _getCustomer(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const AlertDialog(
              content: SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final c = snap.data!;

          return AlertDialog(
            title: const Text("آرڈر کی تصدیق"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("نام: ${c["name"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("فون: ${c["phone"]}"),
                  Text("دکان: ${c["shop_name"]}"),
                  const Divider(),
                  ...cart.cart.map((item) {
                    final itemTotal = (item["price"] ?? 0) * (item["qty"] ?? 0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text("${item["name"]} (${item["pack"] ?? ""})")),
                          Text("₨${toUrduNumber(itemTotal)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("کل:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("₨${toUrduNumber(cart.totalPrice)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("نہیں")),
              ElevatedButton(
                child: const Text("آرڈر کریں"),
                onPressed: () async {
                  Navigator.pop(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await _placeOrder(cart);
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text("آرڈر کامیابی سے موصول ہو گیا")));
                },
              ),
            ],
          );
        },
      );
    },
  );
}


  Future<void> _placeOrder(CartProvider cart) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return;
  }

  try {
    final userDocRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

    // 🔹 Fetch user document
    final userSnapshot = await userDocRef.get();
    if (!userSnapshot.exists) {
      return;
    }

    final userData = userSnapshot.data()!;

    // 🔹 Generate order ID
    final orderId = "ORD-${DateTime.now().millisecondsSinceEpoch}";

    // 🔹 Build customer map
    final customer = {
      "name": userData["name"] ?? "نام موجود نہیں",
      "phone": userData["phone"] ?? "",
      "shop_name": userData["shopName"] ?? "",
      "location": {
        "latitude": userData["location"]?["latitude"] ?? "",
        "longitude": userData["location"]?["longitude"] ?? "",
      }
    };

    // 🔹 Build items list
    final items = cart.cart.map((item) {
      final total = (item["price"] ?? 0) * (item["qty"] ?? 0);
      final map = {
        "name": item["name"],
        "pack": item["pack"],
        "price": item["price"],
        "qty": item["qty"],
        "total": total,
        "image": item["image"] ?? "",
      };
      return map;
    }).toList();

    // 🔹 Build final order map
    final order = {
      "order_id": orderId,
      "customerId": user.uid,
      "customer": customer,
      "items": items,
      "grand_total": cart.totalPrice,
      "status": "pending",
      "payment_status": "unpaid",
      "createdAt": FieldValue.serverTimestamp(), // Safe with new rules
    };

    // 🔹 DEBUG: Log Firestore object
    order.forEach((key, value) {
    });

    // 🔹 Write to Firestore
    await FirebaseFirestore.instance.collection("orders").doc(orderId).set(order);

    // 🔹 Clear cart
    cart.clearCart();
  } catch (e){}
}


  /// Checkout confirmation dialog
 /* void _checkoutDialog(CartProvider cart) {
    print("DEBUG: Opening checkout dialog...");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getCustomer(),
          builder: (_, snap) {
            if (!snap.hasData) {
              print("DEBUG: Waiting for customer info...");
              return const AlertDialog(
                content: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final c = snap.data!;
            print("DEBUG: Showing checkout dialog with customer: $c");

            return AlertDialog(
              title: const Text("آرڈر کی تصدیق"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("نام: ${c["name"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("فون: ${c["phone"]}"),
                    Text("دکان: ${c["shop_name"]}"),
                    const Divider(),
                    ...cart.cart.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text("${item["name"]} (${item["pack"] ?? ""})")),
                          Text("₨${toUrduNumber(item["price"] * item["qty"])}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("کل:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("₨${toUrduNumber(cart.totalPrice)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("نہیں")),
                ElevatedButton(
                  child: const Text("آرڈر کریں"),
                  onPressed: () async {
                    Navigator.pop(context);
                    final messenger = ScaffoldMessenger.of(context);
                    print("DEBUG: Checkout confirmed. Placing order...");

                    await _placeOrder(cart);

                    if (!mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text("آرڈر کامیابی سے موصول ہو گیا")));
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }*/

  /// Quantity button
  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  /// Cart item card
  Widget _cartItem(CartProvider cart, Map item, int index) {
    final total = item["price"] * item["qty"];
    return Dismissible(
      key: ValueKey(index),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.removeItem(index),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,3))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item["image"] ?? "https://cdn-icons-png.flaticon.com/512/415/415733.png",
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(item["pack"]?.toString() ?? "", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text("کل قیمت: ₨${toUrduNumber(total)}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _qtyBtn(Icons.remove, () => cart.decreaseQty(index)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(toUrduNumber(item["qty"]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _qtyBtn(Icons.add, () => cart.increaseQty(index)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => cart.removeItem(index)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (_, cart, __) {
        return Scaffold(
          appBar: AppBar(title: const Text("میرا کارٹ"), automaticallyImplyLeading: false),
          body: cart.cart.isEmpty
              ? const Center(child: Text("آپ کا کارٹ خالی ہے", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cart.cart.length,
                        itemBuilder: (_, i) => _cartItem(cart, cart.cart[i], i),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("کل:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text("₨${toUrduNumber(cart.totalPrice)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _checkoutDialog(cart),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("چیک آؤٹ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
