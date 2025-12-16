import 'package:flutter/material.dart';

class OfferDetailScreen extends StatelessWidget {
  final String offerTitle;
  final String offerDescription;

  const OfferDetailScreen({
    super.key,
    required this.offerTitle,
    required this.offerDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          offerTitle, // Already passed in Urdu from OfferScreen
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "تفصیل:",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              offerDescription, // Already in Urdu from OfferScreen
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/photo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      "تصویر لوڈ نہیں ہو سکی",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
