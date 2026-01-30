import 'package:abacus/cart_provider.dart';
import 'package:abacus/imagecachemanager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Set<String> favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    setState(() {
      favorites = favList.toSet();
    });
  }

  String toUrduNumber(dynamic number) {
    const english = ['0','1','2','3','4','5','6','7','8','9'];
    const urdu = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    String str = number.toString();
    for (int i = 0; i < english.length; i++) {
      str = str.replaceAll(english[i], urdu[i]);
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("پسندیدہ مصنوعات")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('testproducts')
            .orderBy('product_name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("کوئی پروڈکٹ موجود نہیں"));
          }

          // Filter only favorites
          final favProducts = snapshot.data!.docs.where((doc) {
            return favorites.contains(doc.id);
          }).toList();

          if (favProducts.isEmpty) {
            return const Center(child: Text("آپ نے ابھی کوئی پسندیدہ مصنوعات منتخب نہیں کیں"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
            ),
            itemCount: favProducts.length,
            itemBuilder: (context, index) {
              final product = favProducts[index];
              final String name = product['product_name'];
              final int retailPrice = (product['retail_price'] as num).toInt();
              final int perPiecePrice = (product['per_piece_price'] as num).toInt();
              final int pack = (product['packaging'] as num).toInt();
              final int stockQty = (product['stock_quantity'] ?? 0);
              final bool outOfStock = stockQty <= 0;
              int qty = 1;
              final String productId = product.id;

              return StatefulBuilder(
                builder: (context, setStateItem) {
                  return Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: (product['product_image']?.toString().trim() ?? ""),
                                    cacheManager: AppImageCacheManager(),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) =>
                                        const Center(child: CircularProgressIndicator()),
                                    errorWidget: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, size: 40, color: Colors.green),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    favorites.contains(productId)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    if (favorites.contains(productId)) {
                                      favorites.remove(productId);
                                    } else {
                                      favorites.add(productId);
                                    }
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setStringList('favorites', favorites.toList());
                                    setStateItem(() {});
                                    setState(() {}); // update screen if needed
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        Text(
                          "${toUrduNumber(pack)} فی پیک",
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),

                        Text(
                          "فی پیس: ₨${toUrduNumber(perPiecePrice)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        if (outOfStock)
                          const Text(
                            "خارج از اسٹاک",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: outOfStock ? null : () {
                                if (qty > 1) setStateItem(() => qty--);
                              },
                            ),
                            Text(toUrduNumber(qty)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: outOfStock ? null : () => setStateItem(() => qty++),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: ElevatedButton(
                            onPressed: outOfStock ? null : () {
                              Provider.of<CartProvider>(context, listen: false).addToCart({
                                "name": name,
                                "price": retailPrice,
                                "per_piece_price": perPiecePrice,
                                "pack": pack,
                                "qty": qty,
                                "image": product['product_image']?.toString().trim() ?? "",
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: outOfStock ? Colors.grey : null,
                              minimumSize: const Size(double.infinity, 36),
                            ),
                            child: Text(outOfStock ? "اسٹاک ختم" : "کارٹ میں شامل کریں"),
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
      ),
    );
  }
}
