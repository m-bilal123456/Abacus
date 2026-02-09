//---------------CACHE STORE FUNCTIONS-------------------------

import 'package:shared_preferences/shared_preferences.dart';

// To save data
Future<void> saveData(String key, String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value); // Or setInt, setBool, setDouble, setStringList
}

// To read data
Future<String?> readData(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key); // Or getInt, getBool, getDouble, getStringList
}

// To remove data
Future<void> removeData(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}



