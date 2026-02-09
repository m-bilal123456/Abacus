import 'package:abacus/cart_provider.dart';
import 'package:abacus/main.dart';
import 'package:abacus/myorderscreens.dart';
import 'package:abacus/search_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cache.dart';
import 'mapscreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String phone = "";
  String shopName = "";
  String coins = "0.00";

  String? latitude;
  String? longitude;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadLocationData();
  }

  // Fetch user profile from Firestore, fallback to cache
  void loadUserData() async {
    final uid = _auth.currentUser?.uid;
    Map<String, dynamic>? firestoreData;

    if (uid != null) {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        firestoreData = doc.data();
        // Update cache
        if (firestoreData != null) {
          await saveData("name", firestoreData['name'] ?? "");
          await saveData("phone", firestoreData['phone'] ?? "");
          await saveData("shopName", firestoreData['shopName'] ?? "");
        }
      }
    }

    // Fallback to cache
    String? n = firestoreData?['name'] ?? await readData("name");
    String? p = firestoreData?['phone'] ?? await readData("phone");
    String? s = firestoreData?['shopName'] ?? await readData("shopName");

    setState(() {
      name = n?.isNotEmpty == true ? n! : "صارف کا نام";
      phone = p ?? "";
      shopName = s?.isNotEmpty == true ? s! : "دکان کا نام";
    });
  }

  void loadLocationData() async {
    String? lat = await readData("latitude");
    String? long = await readData("longitude");

    setState(() {
      latitude = lat;
      longitude = long;
    });
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("لاگ آؤٹ"),
          content: const Text("کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("منسوخ کریں"),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!mounted) return;

                context.read<CartProvider>().clearCart();
                context.read<SearchProvider>().clearSearch();

                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const StartScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text("لاگ آؤٹ کریں"),
            ),
          ],
        );
      },
    );
  }

  Future<void> openWhatsApp() async {
    const String phoneNumber = "923234491419"; // full international number WITHOUT +
    const String message = "السلام علیکم، مجھے مدد چاہیے";

    final Uri appUri = Uri.parse(
      "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}",
    );
    final Uri webUri = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("واٹس ایپ نہیں کھل سکی")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("واٹس ایپ نہیں کھل سکی")),
      );
    }
  }

  Future<void> callHelpline() async {
    const String phoneNumber = "03001234567"; // Local format is fine
    final Uri callUri = Uri.parse("tel:$phoneNumber");

    if (await canLaunchUrl(callUri)) {
      await launchUrl(
        callUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("کال کرنے کی سہولت دستیاب نہیں ہے"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Container(
            height: kToolbarHeight,
            width: double.infinity,
            color: Colors.green,
            alignment: Alignment.center,
            child: const Text(
              "اکاؤنٹ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // OPENING TIME
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const DummyScreen(title: "دکان کے اوقات"),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      color: Colors.blue.shade50,
                      child: const Text(
                        "آسان ڈیلیوری کے لیے اپنی دکان کے کھلنے کا وقت بتائیں",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // CNIC BUTTON
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const DummyScreen(title: "شناختی کارڈ درج کریں"),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.yellow.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 12),
                    ),
                    child: const Text(
                      "شناختی کارڈ درج کریں",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // LOCATION BUTTON
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      );
                      loadLocationData();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 12),
                    ),
                    child: const Text(
                      "مقام دیکھیں / اپڈیٹ کریں",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // SHOW SAVED LOCATION
                  if (latitude != null && longitude != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "آپ کا محفوظ کردہ مقام:\n"
                        "عرض البلد: $latitude\n"
                        "طول البلد: $longitude",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // PROFILE CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "پروفائل کی معلومات",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 18),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  phone.isEmpty
                                      ? "کوئی فون نمبر محفوظ نہیں ہے"
                                      : phone,
                                  style: const TextStyle(fontSize: 18),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.storefront, color: Colors.orange),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  shopName,
                                  style: const TextStyle(fontSize: 18),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // EDIT PROFILE
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            currentName: name,
                            currentPhone: phone,
                            currentShop: shopName,
                          ),
                        ),
                      );
                      loadUserData();
                    },
                    child: const Text(
                      "پروفائل تبدیل کریں",
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // COINS
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DummyScreen(title: "مرچنٹ سکہ بیلنس"),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 34),
                          const SizedBox(width: 10),
                          Text(
                            coins,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            "مرچنٹ سکہ بیلنس",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // MENU ITEMS
                  menuItem(Icons.receipt_long, "میرے آرڈر",
                      navigateTo: const MyOrdersScreen()),
                  menuItem(FontAwesomeIcons.whatsapp, "واٹس ایپ ہیلپ لائن",
                      onTap: openWhatsApp),
                  menuItem(Icons.call, "کال ہیلپ لائن", onTap: callHelpline),
                  menuItem(Icons.power_settings_new, "لاگ آؤٹ",
                      onTap: showLogoutDialog),

                  const SizedBox(height: 40),
                  const Text(
                    "1.0.0 بیٹا",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget menuItem(IconData icon, String title,
      {Widget? navigateTo, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (navigateTo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => navigateTo),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DummyScreen(title: title)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }
}

// ===================== EDIT PROFILE SCREEN ===================== //
class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentShop;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentShop,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController shopCtrl;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.currentName);
    phoneCtrl = TextEditingController(text: widget.currentPhone);
    shopCtrl = TextEditingController(text: widget.currentShop);
  }

  Future<void> saveProfile() async {
    final uid = _auth.currentUser?.uid;
    final String n = nameCtrl.text.trim();
    final String p = phoneCtrl.text.trim();
    final String s = shopCtrl.text.trim();

    // Update cache
    await saveData("name", n);
    await saveData("phoneno", p);
    await saveData("shopname", s);

    // Save to Firestore only if UID exists
    if (uid != null) {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      // Prevent overwrite if document exists
      if (!doc.exists) {
        await docRef.set({
          'uid': uid,
          'name': n,
          'phoneno': p,
          'shopname': s,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing fields
        await docRef.update({
          'name': n,
          'phoneno': p,
          'shopname': s,
        });
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("پروفائل تبدیل کریں")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "نام",
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "فون نمبر",
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: shopCtrl,
              decoration: const InputDecoration(
                labelText: "دکان کا نام",
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("محفوظ کریں"),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- Dummy Screen ------------------- //
class DummyScreen extends StatelessWidget {
  final String title;

  const DummyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          "یہ $title اسکرین ہے",
          style: const TextStyle(fontSize: 26),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
