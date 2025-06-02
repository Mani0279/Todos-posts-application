import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../contollers/user_bloc.dart';
import '../../models/user.dart';
import '../widgets/user_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widget.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ScrollController _scrollController = ScrollController();

  // Debounce timer for scroll events
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Only fetch users if we're in initial state
    final userBloc = context.read<UserBloc>();
    if (userBloc.state is UserInitial) {
      userBloc.add(const FetchUsers());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !_isLoadingMore) {
      _isLoadingMore = true;
      context.read<UserBloc>().add(LoadMoreUsers());

      // Reset the flag after a brief delay to prevent rapid fire requests
      Future.delayed(const Duration(milliseconds: 1000), () {
        _isLoadingMore = false;
      });
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UserLoaded) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      '${state.users.length}/${state.totalUsers}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) {
              if (query.isEmpty) {
                context.read<UserBloc>().add(const ClearSearch());
              } else {
                context.read<UserBloc>().add(SearchUsers(query));
              }
            },
          ),
          Expanded(
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is UserLoading) {
                  return const LoadingIndicator(message: 'Loading users...');
                } else if (state is UserLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<UserBloc>().add(const RefreshUsers());
                      // Wait for the refresh to complete
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              if (index >= state.users.length) {
                                return const SizedBox.shrink();
                              }

                              final user = state.users[index];
                              return UserCard(
                                user: user,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserDetailScreen(user: user),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: state.users.length,
                          ),
                        ),
                        // Loading indicator for pagination
                        if (state.isLoadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: LoadingIndicator(size: 30),
                            ),
                          ),
                        // End of list indicator
                        if (state.hasReachedMax && state.users.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Divider(),
                                  Text(
                                    'You\'ve reached the end of the list',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total: ${state.totalUsers} users',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Empty state for search
                        if (state.users.isEmpty && state.searchQuery != null)
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No users found',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try a different search term',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                } else if (state is UserError) {
                  return CustomErrorWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<UserBloc>().add(const FetchUsers());
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}