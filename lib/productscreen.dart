import 'package:abacus/cart_provider.dart';
import 'package:abacus/cartpage.dart';
import 'package:abacus/categoryproductscreen.dart';
import 'package:abacus/offerscreen.dart';
import 'package:abacus/othercategoryscreen.dart';
import 'package:abacus/profilescreen.dart';
import 'package:abacus/search_provider.dart';
import 'package:abacus/voicescreen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    "assets/4.jpg", 
    "assets/5.jpg", 
    "assets/6.jpg", 
  ];

  // ---------------- BRAND LOGOS (NETWORK) ----------------
  final List<String> brandLogos= [
    "https://cdn-icons-png.flaticon.com/512/415/415733.png", // پھل
    "https://cdn-icons-png.flaticon.com/512/135/135626.png", // سبزیاں
    "https://cdn-icons-png.flaticon.com/512/3075/3075977.png", // گوشت
    "https://cdn-icons-png.flaticon.com/512/2910/2910763.png", // بیکری
    "https://cdn-icons-png.flaticon.com/512/1046/1046784.png", // مشروبات
    "https://cdn-icons-png.flaticon.com/512/1046/1046791.png", // اسنیکس
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

  @override
  Widget build(BuildContext context) {
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
          CarouselSlider(
            items: imageSliders,
            options: CarouselOptions(
              autoPlay: true,
              aspectRatio: 2,
              enlargeCenterPage: true,
            ),
          ),

          // ---------------- CATEGORY GRID ----------------
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
                onTap: () {
                  if (index == 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OfferScreen()),
                    );
                  } else {
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

          // ---------------- BRAND GRID ----------------
          Align(
            alignment: Alignment.centerLeft,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                'برانڈز',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemCount: brandLogos.length,
            itemBuilder: (_, index) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CategoryProductsScreen(
                            categoryKey: "grocery",
                    ),
                  )
                  );
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
                    child: Image.network(
                      brandLogos[index],
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
        ],
      ),
    );

    // ---------------- SCREENS ----------------
    final List<Widget> screens = [
      SafeArea(child: homeBody),
      const SafeArea(child: OfferScreen()),
      const SafeArea(child: VoiceScreen()),
      const SafeArea(child: CartPage()),
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
