import 'package:abacus/productscreen.dart';
import 'package:abacus/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'number_screen.dart';
import 'cart_provider.dart';

// Urdu font
const String urduFont = "NotoNastaliqUrdu";

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  prefs = await SharedPreferences.getInstance();

  final String? userToken = prefs.getString('login');
  final String initialRoute = userToken != null ? '/home' : '/login';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Directionality(        // <-- RTL applied globally
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Abacus',

        theme: ThemeData(
          fontFamily: urduFont,   // <-- Urdu font applied globally
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),

        initialRoute: initialRoute,
        routes: {
          '/login': (context) => const StartScreen(),
          '/home': (context) => ProductScreen(),
        },
      ),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var screenSizes = MediaQuery.of(context).size;

    return SafeArea(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NumberScreen()),
          );
        },
        child: Image.asset(
          "assets/start.jpg",
          width: screenSizes.width,
          height: screenSizes.height,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
