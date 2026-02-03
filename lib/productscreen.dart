import 'package:abacus/activeordersscreen.dart';
import 'package:abacus/cart_provider.dart';
import 'package:abacus/cartpage.dart';
import 'package:abacus/categoryproductscreen.dart';
import 'package:abacus/favoritescreen.dart';
import 'package:abacus/imagecachemanager.dart';
import 'package:abacus/inventoryscreen.dart';
import 'package:abacus/offerscreen.dart';
import 'package:abacus/othercategoryscreen.dart';
import 'package:abacus/profilescreen.dart';
import 'package:abacus/reorderscreen.dart';
import 'package:abacus/search_provider.dart';
import 'package:abacus/voicescreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carouseldetails.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // ---------------- CATEGORY IMAGES (LOCAL ASSETS) ----------------
  final List<String> categoryImages = [
    "assets/1.jpg",
    "assets/2.jpg",
    "assets/3.jpg",
    "assets/4.png",
    "assets/5.jpg",
    "assets/6.jpg",
  ];

  final List<Map<String, String>> carouselData = [
    {
      "title": "بڑی سرمائی فروخت",
      "desc": "تمام گروسری اشیاء پر 50% تک رعایت!",
      "image": "assets/photo.jpeg",
    },
    {
      "title": "تازہ پھلوں کی ڈیل",
      "desc": "منتخب پھلوں پر 1 خریدیں 1 مفت حاصل کریں۔",
      "image": "assets/photo.jpeg",
    },
    {
      "title": "میگا رعایتیں",
      "desc": "گھریلو ضروریات کی اشیاء پر خاص قیمتیں۔",
      "image": "assets/photo.jpeg",
    },
    {
      "title": "نئی آمد",
      "desc": "دکان میں نیا اسٹاک شامل کیا گیا۔",
      "image": "assets/photo.jpeg",
    },
    {
      "title": "سب سے زیادہ فروخت ہونے والی اشیاء",
      "desc": "ہمارے سب سے مقبول آئٹمز دیکھیں!",
      "image": "assets/photo.jpeg",
    },
    {
      "title": "محدود وقت کی پیشکش",
      "desc": "جلدی کریں! پیشکش جلد ختم ہو رہی ہے۔",
      "image": "assets/photo.jpeg",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- FETCH UNIQUE BRANDS WITH IMAGE ----------------
Stream<List<Map<String, String>>> fetchBrands(String query) {
  return FirebaseFirestore.instance
      .collection('testproducts')
      .snapshots()
      .map((snapshot) {
    final Map<String, String> brands = {};
    final q = query.toLowerCase().trim();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final brand =
          data['brand']?.toString().trim() ?? '';
      final brandImage =
          data['brand_image']?.toString().trim() ??
              "https://via.placeholder.com/150";

      final productName =
          data['name']?.toString().toLowerCase() ?? '';

      if (brand.isEmpty) continue;

      // ✅ SHOW BRAND IF:
      // 1. Brand name matches query
      // 2. OR product name under that brand matches query
      final matchesSearch = q.isEmpty ||
          brand.toLowerCase().contains(q) ||
          productName.contains(q);

      if (matchesSearch && !brands.containsKey(brand)) {
        brands[brand] = brandImage;
      }
    }

    return brands.entries
        .map((e) => {'brand': e.key, 'image': e.value})
        .toList();
  });
}




  @override
void initState() {
  super.initState();
  _preloadBrandImages();
}

void _preloadBrandImages() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('testproducts')
      .get();

  for (var doc in snapshot.docs) {
    final imageUrl = doc.data()['brand_image'];
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      AppImageCacheManager().downloadFile(imageUrl);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final searchQuery = context.watch<SearchProvider>().query.trim();
    final bool isSearching = searchQuery.isNotEmpty;

    final List<Widget> imageSliders = carouselData.map((item) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CarouselDetailsScreen(
                title: item["title"]!,
                description: item["desc"]!,
                image: item["image"]!,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            item["image"]!,
            fit: BoxFit.cover,
            width: 1000,
          ),
        ),
      );
    }).toList();

    // ---------------- HOME BODY ----------------
    Widget homeBody = SingleChildScrollView(
      child: Column(
        children: [
          // ---------------- SEARCH BAR ----------------
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axis: Axis.vertical,
                child: child,
              );
            },
            child: currentIndex == 0
                ? Padding(
                    key: const ValueKey("searchBar"),
                    padding: const EdgeInsets.all(10.0),
                    child: Consumer<SearchProvider>(
                      builder: (context, searchProv, _) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final safeQuery = searchProv.query;
                          if (_searchController.text != safeQuery) {
                            _searchController.text = safeQuery;
                            _searchController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: safeQuery.length),
                            );
                          }
                        });

                        return TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            searchProv.updateQuery(value);
                          },
                          decoration: InputDecoration(
                            hintText: "کچھ بھی تلاش کریں...",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchProv.query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      searchProv.updateQuery("");
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey("emptySearchBar")),
          ),

          // ---------------- CAROUSEL ----------------
          if (!isSearching)
            CarouselSlider(
              items: imageSliders,
              options: CarouselOptions(
                autoPlay: true,
                aspectRatio: 2,
                enlargeCenterPage: true,
              ),
            ),

          // ---------------- CATEGORY GRID ----------------
          if (!isSearching)
            Align(
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  'زمرہ جات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          if (!isSearching)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: categoryImages.length,
              itemBuilder: (_, index) {
              return InkWell(
                onTap: () async {
                  if (index == 0) {
                    // Offers
                    setState(() {
                        currentIndex = 1; // Switch to Offers tab
                      });
                  } 
                  else if (index == 1) {
                    // ✅ 2nd HOME GRID → Favorites
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    );
                  } 
                  else if (index == 2) {
                    // ✅ 3rd GRID → Reorder Screen
                    final goToCart = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReorderScreen()),
                    );

                    if (goToCart == true) {
                      setState(() {
                        currentIndex = 3; // Switch to Cart tab
                      });
                    }
                  }
                  else if (index == 3) {
                    // ✅ 4th HOME GRID → Active Orders
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveOrdersScreen()),
                    );
                  } 

                  else if (index == 4) {
                    // ✅ 5th HOME GRID → Inventory
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllProductsScreen()),
                    );
                  } 

                  else if (index == 5) {
                    // ✅ 6th HOME GRID → Inventory
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllProductsScreen()),
                    );
                  } 
                  
                  else {
                    // Other categories
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtherCategoryScreen(
                          categoryName: "زمرہ $index",
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.grey, spreadRadius: 2, blurRadius: 5),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      categoryImages[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image));
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // ---------------- DYNAMIC BRAND GRID ----------------
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                isSearching ? 'تلاش کے نتائج' : 'برانڈز',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          StreamBuilder<List<Map<String, String>>>(
            stream: fetchBrands(context.watch<SearchProvider>().query,),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("کوئی برانڈ موجود نہیں"));
              }

              final brands = snapshot.data!;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: brands.length,
                itemBuilder: (_, index) {
                  final brand = brands[index]['brand']!;
                  final imageUrl = brands[index]['image']!;

                  // String originalLink = imageUrl;
                  // String fileId =
                  // originalLink.substring(originalLink.indexOf('/d/') + 3, originalLink.indexOf('/view'));
                  // String newLink = 'https://drive.google.com/uc?export=view&id=$fileId';
                  // debugPrint("🔥 DRIVE QUERY => $newLink");

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryProductsScreen(
                            categoryKey: brand, // exact match
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.grey,
                              spreadRadius: 2,
                              blurRadius: 5),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          cacheManager: AppImageCacheManager(),
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              Center(child: Text(brand)),
                        )
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );

    // ---------------- SCREENS ----------------
    final List<Widget> screens = [
      SafeArea(child: homeBody),
      const SafeArea(child: OfferScreen()),
      const SafeArea(child: VoiceScreen()),
      SafeArea(child: CartPage()),
      const SafeArea(child: ProfileScreen()),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return BottomNavigationBar(
            currentIndex: currentIndex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "ہوم",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.category),
                label: "آفرز",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.mic),
                label: "وائس",
              ),
              BottomNavigationBarItem(
                label: "کارٹ",
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cart.totalItems > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            cart.totalItems.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "پروفائل",
              ),
            ],
          );
        },
      ),
    );
  }
}
