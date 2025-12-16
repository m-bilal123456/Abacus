import 'package:abacus/cache.dart';
import 'package:flutter/material.dart';
import 'otpscreen.dart';

class NumberScreen extends StatefulWidget {
  const NumberScreen({super.key});

  @override
  State<NumberScreen> createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen> {
  final _numberTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),

                // Top buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ہیلپ لائن',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),

                const Text(
                  'موبائل نمبر درج کریں',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 50),

                // PERFECTLY CENTERED PHONE INPUT
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,   // Ensures perfect centering
                    children: [
                      const Text(
                        '+92',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: screenSize.width * 0.45,  // Slightly slimmer for visual balance
                        child: TextField(
                          controller: _numberTextController,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: '3012345678',
                            hintStyle: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Next button
            Positioned(
              bottom: 30,
              right: 30,
              child: GestureDetector(
                onTap: () {
                  saveData('phoneno', _numberTextController.text);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OTPScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 30,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
