import 'package:flutter/material.dart';

class CarouselDetailsScreen extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const CarouselDetailsScreen({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- AppBar ----------------
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D7A1F), // Green bar
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              "آفرز  >  قرعہ اندازی - ویلو",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontFamily: "JameelNoori",
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 14,
                child: Icon(Icons.close, color: Colors.black, size: 18),
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ---------------- Big Banner Image ----------------
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Image.asset(
              image,
              width: double.infinity,
              fit: BoxFit.cover,
              height: 230,
            ),
          ),

          // ---------------- Yellow Coupon Bar ----------------
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            padding: const EdgeInsets.symmetric(vertical: 14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                "!ہر Rs 3,500 کی خریداری پر کوپن حاصل کریں",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "JameelNoori",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ---------------- Leaderboard Title ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    "رینک",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: "JameelNoori",
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "کسٹمر",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "JameelNoori",
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "کوپن",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: "JameelNoori",
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ---------------- Leaderboard List ----------------
          Expanded(
            child: ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final item = leaderboard[index];

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${item['rank']}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['name']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_number_rounded,
                                size: 18, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              "${item['coins']}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Dummy leaderboard
final List<Map<String, dynamic>> leaderboard = [
  {"rank": 1, "name": "Munna G Paan Shop", "coins": 48},
  {"rank": 2, "name": "Qadir Pan Shop", "coins": 19},
  {"rank": 3, "name": "M.H TOBACCO", "coins": 19},
  {"rank": 4, "name": "Ahmad General Store", "coins": 14},
  {"rank": 5, "name": "Ibex-2 Cateen", "coins": 13},
  {"rank": 6, "name": "NEW BOMBAY PAN SHOP", "coins": 11},
  {"rank": 7, "name": "Imran G/S", "coins": 10},
  {"rank": 8, "name": "Star Mart Opf", "coins": 10},
];
