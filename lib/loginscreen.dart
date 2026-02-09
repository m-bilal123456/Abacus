// ignore_for_file: use_build_context_synchronously

import 'package:abacus/productscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'cache.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController shopCtrl = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final name = await readData('name') ?? '';
    final phone = await readData('phoneno') ?? '';
    final shop = await readData('shopname') ?? '';

    nameCtrl.text = name;
    phoneCtrl.text = phone;
    shopCtrl.text = shop;

    setState(() {}); // refresh UI
  }

  Future<void> _continue() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final shop = shopCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || shop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تمام فیلڈز پر کریں")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Use the previous UID if exists, otherwise sign in anonymously
      String? uid = await readData('customerId');

      if (uid == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        uid = userCredential.user!.uid;
        await saveData('customerId', uid);
      }

      // Save locally again to make sure it's updated
      await saveData('name', name);
      await saveData('phoneno', phone);
      await saveData('shopname', shop);

      // Save to Firestore if not exists
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': uid,
          'name': name,
          'phone': phone,
          'shopName': shop,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Navigate to ProductScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Info")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
              readOnly: true, // make it readonly for confirmation
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Phone"),
              readOnly: true,
            ),
            TextField(
              controller: shopCtrl,
              decoration: const InputDecoration(labelText: "Shop Name"),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _continue,
                    child: const Text("Continue"),
                  ),
          ],
        ),
      ),
    );
  }
}
