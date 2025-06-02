import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/post.dart';
import '../models/todo.dart';
import '../utils/constants.dart';

class ApiService {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> getUsers({
    int limit = 10,
    int skip = 0,
    String? search,
  }) async {
    try {
      String url = '${Constants.usersEndpoint}?limit=$limit&skip=$skip';
      if (search != null && search.isNotEmpty) {
        url = '${Constants.usersEndpoint}/search?q=$search&limit=$limit&skip=$skip';
      }

      final response = await _client
          .get(Uri.parse(url))
          .timeout(Constants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'users': (data['users'] as List)
              .map((json) => User.fromJson(json))
              .toList(),
          'total': data['total'] ?? 0,
          'skip': data['skip'] ?? skip,
          'limit': data['limit'] ?? limit,
        };
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Post>> getUserPosts(int userId) async {
    try {
      final response = await _client
          .get(Uri.parse('${Constants.postsEndpoint}/user/$userId'))
          .timeout(Constants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response structures
        if (data is List) {
          // If response is directly a list of posts
          return data.map((json) => Post.fromJson(json)).toList();
        } else if (data is Map<String, dynamic>) {
          // If response is wrapped in an object with 'posts' key
          final posts = data['posts'];
          if (posts is List) {
            return posts.map((json) => Post.fromJson(json)).toList();
          } else {
            throw Exception('Invalid posts data structure');
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Todo>> getUserTodos(int userId) async {
    try {
      final response = await _client
          .get(Uri.parse('${Constants.todosEndpoint}/user/$userId'))
          .timeout(Constants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response structures
        if (data is List) {
          // If response is directly a list of todos
          return data.map((json) => Todo.fromJson(json)).toList();
        } else if (data is Map<String, dynamic>) {
          // If response is wrapped in an object with 'todos' key
          final todos = data['todos'];
          if (todos is List) {
            return todos.map((json) => Todo.fromJson(json)).toList();
          } else {
            throw Exception('Invalid todos data structure');
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load todos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Post> createPost(Post post) async {
    try {
      final response = await _client
          .post(
        Uri.parse('${Constants.postsEndpoint}/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(post.toJson()),
      )
          .timeout(Constants.apiTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Post.fromJson(data);
      } else {
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}