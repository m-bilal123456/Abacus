import 'package:abacus/cart_provider.dart';
import 'package:abacus/imagecachemanager.dart';
import 'package:abacus/search_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Helper to convert numbers to Urdu numerals
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



class CategoryProductsScreen extends StatelessWidget {
  final String categoryKey; // Brand (First letter capital)

  const CategoryProductsScreen({
    super.key,
    required this.categoryKey,
  });

void _preloadImages() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('testproducts')
      .where('brand', isEqualTo: categoryKey)
      .get();

  for (var doc in snapshot.docs) {
    final imageUrl = doc.data()['product_image']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      AppImageCacheManager().downloadFile(imageUrl);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    debugPrint("🔥 BRAND QUERY => $categoryKey");
    // Preload images when the screen is built
  _preloadImages();

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
                  hintText: "$categoryKey میں تلاش کریں...",
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
                .collection('testproducts')
                .where('brand', isEqualTo: categoryKey)
                .snapshots(),

            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("کوئی پروڈکٹ موجود نہیں"));
              }

              final products = snapshot.data!.docs.where((doc) {
                final name =
                    doc['product_name'].toString().toLowerCase();
                final query = searchProv.query.toLowerCase();
                return name.contains(query);
              }).toList();

              if (products.isEmpty) {
                return const Center(child: Text("کوئی پروڈکٹ موجود نہیں"));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length,
                itemBuilder: (_, index) {
                  final product = products[index];

                  final String name = product['product_name'];
                  final int packItem =
                      (product['packaging'] as num).toInt();

                  final int retailPrice =
                      (product['retail_price'] as num).toInt();

                  final int perPiecePrice =
                      (product['per_piece_price'] as num).toInt();

                  int qty = 1;

                  // String originalLink = product['product_image'];
                  // String fileId =
                  // originalLink.substring(originalLink.indexOf('/d/') + 3, originalLink.indexOf('/view'));
                  // String newLink = 'https://drive.google.com/uc?export=view&id=$fileId';

                  

                  return StatefulBuilder(
                    builder: (context, setState) {
                      final int totalPrice = retailPrice;

                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000), // soft shadow
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: _ProductImage(
                                  imageUrl: product['product_image']?.toString() ?? "",
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

                            const SizedBox(height: 4),

                            // ✅ PACK ITEMS
                            Text(
                              "${toUrduNumber(packItem)} فی آئٹم",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),

                            // ✅ PER PIECE PRICE
                            Text(
                              "فی پیس: ₨${toUrduNumber(perPiecePrice)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.green,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /*// ✅ SALE PRICE
                            Text(
                              "₨${toUrduNumber(salesPrice)} فی آئٹم",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),*/

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (qty > 1) setState(() => qty--);
                                  },
                                ),
                                Text(toUrduNumber(qty)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(() => qty++)
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
                                    "price": retailPrice,
                                    "per_piece_price": perPiecePrice,
                                    "pack": packItem,
                                    "qty": qty,
                                    "image": product["product_image"] ?? "https://via.placeholder.com/150",
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

class _ProductImage extends StatelessWidget {
  final String imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: const Icon(
          Icons.image,
          size: 40,
          color: Colors.green,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheManager: AppImageCacheManager(), // ✅ use custom cache manager
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, __, ___) => const Center(
          child: Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}