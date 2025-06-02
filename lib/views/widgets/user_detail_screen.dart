import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../contollers/post_bloc.dart';
import '../../contollers/todo_bloc.dart';
import '../../models/user.dart';
import '../../models/post.dart';
import '../../models/todo.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widget.dart';
import 'create_post_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load posts and todos
    _loadUserData();
  }

  void _loadUserData() {
    context.read<PostBloc>().add(LoadUserPosts(widget.user.id));
    context.read<TodoBloc>().add(LoadUserTodos(widget.user.id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.fullName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePostScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.user.image.isNotEmpty
                      ? CachedNetworkImageProvider(widget.user.image)
                      : null,
                  child: widget.user.image.isEmpty
                      ? Text(
                    widget.user.fullName.isNotEmpty
                        ? widget.user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                // Company Info
                if (widget.user.company.name.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.user.company.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        if (widget.user.company.title.isNotEmpty)
                          Text(
                            widget.user.company.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[600],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Posts', icon: Icon(Icons.article)),
              Tab(text: 'Todos', icon: Icon(Icons.checklist)),
            ],
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildTodosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    context.read<PostBloc>().add(RefreshUserPosts(widget.user.id));
    context.read<TodoBloc>().add(RefreshUserTodos(widget.user.id));
  }

  Widget _buildPostsTab() {
    return BlocBuilder<PostBloc, PostState>(
      builder: (context, state) {
        if (state is PostLoading) {
          return const LoadingIndicator(message: 'Loading posts...');
        } else if (state is PostLoaded) {
          if (state.posts.isEmpty) {
            return _buildEmptyState(
              icon: Icons.article_outlined,
              title: 'No posts found',
              subtitle: 'This user hasn\'t posted anything yet',
              onRetry: () => context.read<PostBloc>().add(LoadUserPosts(widget.user.id)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PostBloc>().add(RefreshUserPosts(widget.user.id));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                final post = state.posts[index];
                return _buildPostCard(post);
              },
            ),
          );
        } else if (state is PostError) {
          return CustomErrorWidget(
            message: state.message,
            onRetry: () {
              context.read<PostBloc>().add(LoadUserPosts(widget.user.id));
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTodosTab() {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodoLoading) {
          return const LoadingIndicator(message: 'Loading todos...');
        } else if (state is TodoLoaded) {
          if (state.todos.isEmpty) {
            return _buildEmptyState(
              icon: Icons.checklist_outlined,
              title: 'No todos found',
              subtitle: 'This user doesn\'t have any tasks',
              onRetry: () => context.read<TodoBloc>().add(LoadUserTodos(widget.user.id)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TodoBloc>().add(RefreshUserTodos(widget.user.id));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Column(
              children: [
                // Todo Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTodoSummary(
                        'Total',
                        state.todos.length,
                        Colors.blue,
                      ),
                      _buildTodoSummary(
                        'Completed',
                        state.todos.where((todo) => todo.completed).length,
                        Colors.green,
                      ),
                      _buildTodoSummary(
                        'Pending',
                        state.todos.where((todo) => !todo.completed).length,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Todo List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.todos.length,
                    itemBuilder: (context, index) {
                      final todo = state.todos[index];
                      return _buildTodoCard(todo);
                    },
                  ),
                ),
              ],
            ),
          );
        } else if (state is TodoError) {
          return CustomErrorWidget(
            message: state.message,
            onRetry: () {
              context.read<TodoBloc>().add(LoadUserTodos(widget.user.id));
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoSummary(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: post.tags.map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue[100],
                    labelStyle: TextStyle(color: Colors.blue[800]),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                const SizedBox(width: 4),
                Text(
                  '${post.reactions}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard(Todo todo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            context.read<TodoBloc>().add(ToggleTodo(todo.id));
          },
          child: Icon(
            todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: todo.completed ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          todo.todo,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Colors.grey : null,
          ),
        ),
        trailing: todo.completed
            ? Icon(Icons.done, color: Colors.green[400], size: 20)
            : null,
      ),
    );
  }
}