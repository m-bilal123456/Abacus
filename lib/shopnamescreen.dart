import 'package:abacus/cache.dart';
import 'package:flutter/material.dart';
import 'package:abacus/mapscreen.dart';

class ShopNameScreen extends StatefulWidget {
  const ShopNameScreen({super.key});

  @override
  State<ShopNameScreen> createState() => _ShopNameScreenState();
}

class _ShopNameScreenState extends State<ShopNameScreen> {
  final _shoptextEditing = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var screenSizes = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Centered Column
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Text
                  const Text(
                    "دکان کا نام",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TextField
                  SizedBox(
                    width: screenSizes.width * 0.85,
                    child: TextField(
                      controller: _shoptextEditing,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Dukaan ka naam",
                        hintStyle: TextStyle(
                          fontSize: 22,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                        border: InputBorder.none,
                        counterText: "",
                      ),
                      maxLength: 50,
                    ),
                  ),
                ],
              ),
            ),

            // Back Button (Top Left)
            Positioned(
              top: 15,
              left: 15,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Help Line Button (Top Right)
            Positioned(
              top: 15,
              right: 15,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  "ہیلپ لائن",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),

            // Next Button (Bottom Right)
            Positioned(
              bottom: 35,
              right: 35,
              child: FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () {
                  saveData('shopname', _shoptextEditing.text);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.arrow_forward, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
