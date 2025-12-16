import 'package:flutter/material.dart';

class OtherCategoryScreen extends StatelessWidget {
  final String categoryName;

  const OtherCategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: const Center(
        child: Text(
          "This is the other category screen!",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
