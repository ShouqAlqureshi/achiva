import 'package:internet_connection_checker/internet_connection_checker.dart';

class CheckInternetConnection {
  static Future<bool> getStatus() async => await InternetConnectionChecker().hasConnection;
}