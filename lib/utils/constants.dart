import 'dart:ui';

class Constants {
  static const String baseUrl = 'https://dummyjson.com';
  static const String usersEndpoint = '$baseUrl/users';
  static const String postsEndpoint = '$baseUrl/posts';
  static const String todosEndpoint = '$baseUrl/todos';

  static const int pageSize = 10;
  static const Duration apiTimeout = Duration(seconds: 30);

  // Colors
  static const primaryColor = Color(0xFF2196F3);
  static const errorColor = Color(0xFFD32F2F);
  static const successColor = Color(0xFF388E3C);
}