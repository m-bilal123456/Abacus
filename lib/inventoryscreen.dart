import 'package:abacus/cart_provider.dart';
import 'package:abacus/imagecachemanager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final Set<String> favorites = {}; // store product IDs

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    setState(() {
      favorites.addAll(favList);
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
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تمام مصنوعات"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "پروڈکٹ تلاش کریں...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
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

          final products = snapshot.data!.docs.where((doc) {
            final name = doc['product_name'].toString().toLowerCase();
            return name.contains(searchCtrl.text.toLowerCase());
          }).toList();

          if (products.isEmpty) {
            return const Center(child: Text("کوئی پروڈکٹ نہیں ملی"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
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
                        // Image + Favorite
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
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.green,
                                      ),
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
                                    // Toggle favorite for this specific product
                                    if (favorites.contains(productId)) {
                                      favorites.remove(productId);
                                    } else {
                                      favorites.add(productId);
                                    }

                                    // Save to SharedPreferences
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setStringList('favorites', favorites.toList());

                                    // Only rebuild this item
                                    setStateItem(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Name
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

                        // Pack
                        Text(
                          "${toUrduNumber(pack)} فی پیک",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Per piece price
                        Text(
                          "فی پیس: ₨${toUrduNumber(perPiecePrice)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (outOfStock)
                          const Text(
                            "خارج از اسٹاک",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        // Quantity selector
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

                        // Add to Cart
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
