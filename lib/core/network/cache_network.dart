import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPref;

  static Future cacheInitialization() async {
    sharedPref = await SharedPreferences.getInstance();
  }

  static Future<bool> insertString({required String key,required String value}) async {
    try{
      return await sharedPref.setString(key, value);
    }
    catch(e){
      return false;
    }
  }

  static Future<bool> insertBool({required String key,required bool value}) async {
    try{
      return await sharedPref.setBool(key, value);
    }
    catch(e){
      return false;
    }
  }

  static bool? getBool({required String key}) {
    try{
      return sharedPref.getBool(key);
    }
    catch(e){
      return null;
    }
  }

  static String? getString({required String key}) {
    try{
      return sharedPref.getString(key);
    }
    catch(e){
      return null;
    }
  }

  static Future<bool> removeItem({required String key}) async {
    try{
      return await sharedPref.remove(key);
    }
    catch(e){
      return false;
    }
  }

  static Future<bool> clearCache() async {
    try{
      return await sharedPref.clear();
    }
    catch(e){
      return false;
    }
  }
}