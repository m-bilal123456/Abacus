import 'package:abacus/offerdetailscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final CollectionReference offersRef =
      FirebaseFirestore.instance.collection('offers');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offers")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: offersRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("کوئی پیشکش موجود نہیں"));
            }

            final offers = snapshot.data!.docs;

            return ListView.builder(
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final data = offers[index].data() as Map<String, dynamic>;

                final title = data['title'] ?? 'No Title';
                final description = data['description'] ?? '';
                final imageUrl = data['image'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfferDetailScreen(
                            offerTitle: title,
                            offerDescription: description, 
                            imageUrl: imageUrl,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),

                          /// 🔥 Firestore Image
                          Image.network(
                            imageUrl,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text(
                                  "تصویر لوڈ نہیں ہو سکی",
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            },
                          ),
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
    );
  }
}