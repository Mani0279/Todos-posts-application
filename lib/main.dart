import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todospostsapp/services/api_service.dart';
import 'package:todospostsapp/views/widgets/user_list_screen.dart';

import 'contollers/post_bloc.dart';
import 'contollers/todo_bloc.dart';
import 'contollers/user_bloc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(_apiService),
        ),
        BlocProvider<PostBloc>(
          create: (context) => PostBloc(_apiService),
        ),
        BlocProvider<TodoBloc>(
          create: (context) => TodoBloc(_apiService),
        ),
      ],
      child: MaterialApp(
        title: 'User Management App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: UserListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}