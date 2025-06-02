import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class FetchUsers extends UserEvent {
  const FetchUsers();
}

class RefreshUsers extends UserEvent {
  const RefreshUsers();
}

class LoadMoreUsers extends UserEvent {
  const LoadMoreUsers();
}

class SearchUsers extends UserEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends UserEvent {
  const ClearSearch();
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<User> users;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? searchQuery;
  final int totalUsers;
  final int currentPage;

  const UserLoaded({
    required this.users,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.searchQuery,
    this.totalUsers = 0,
    this.currentPage = 0,
  });

  UserLoaded copyWith({
    List<User>? users,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? searchQuery,
    int? totalUsers,
    int? currentPage,
  }) {
    return UserLoaded(
      users: users ?? this.users,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      totalUsers: totalUsers ?? this.totalUsers,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    users,
    hasReachedMax,
    isLoadingMore,
    searchQuery,
    totalUsers,
    currentPage
  ];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final ApiService _apiService;
  int _currentSkip = 0;
  String? _currentSearchQuery;
  List<User> _allUsers = [];
  int _totalUsers = 0;

  UserBloc(this._apiService) : super(UserInitial()) {
    on<FetchUsers>(_onFetchUsers);
    on<RefreshUsers>(_onRefreshUsers);
    on<LoadMoreUsers>(_onLoadMoreUsers);
    on<SearchUsers>(_onSearchUsers);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onFetchUsers(FetchUsers event, Emitter<UserState> emit) async {
    emit(UserLoading());
    _resetPagination();

    try {
      final result = await _apiService.getUsers(
        skip: _currentSkip,
        limit: Constants.pageSize,
      );

      final users = result['users'] as List<User>;
      _totalUsers = result['total'] as int;
      _allUsers = List.from(users);
      _currentSkip += users.length;

      emit(UserLoaded(
        users: _allUsers,
        hasReachedMax: _allUsers.length >= _totalUsers,
        isLoadingMore: false,
        searchQuery: _currentSearchQuery,
        totalUsers: _totalUsers,
        currentPage: 1,
      ));
    } catch (e) {
      emit(UserError('Failed to load users: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshUsers(RefreshUsers event, Emitter<UserState> emit) async {
    _resetPagination();

    try {
      final result = await _apiService.getUsers(
        skip: _currentSkip,
        limit: Constants.pageSize,
        search: _currentSearchQuery,
      );

      final users = result['users'] as List<User>;
      _totalUsers = result['total'] as int;
      _allUsers = List.from(users);
      _currentSkip += users.length;

      emit(UserLoaded(
        users: _allUsers,
        hasReachedMax: _allUsers.length >= _totalUsers,
        isLoadingMore: false,
        searchQuery: _currentSearchQuery,
        totalUsers: _totalUsers,
        currentPage: 1,
      ));
    } catch (e) {
      emit(UserError('Failed to refresh users: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreUsers(LoadMoreUsers event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserLoaded &&
        !currentState.hasReachedMax &&
        !currentState.isLoadingMore) {

      // Show loading indicator for pagination
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final result = await _apiService.getUsers(
          skip: _currentSkip,
          limit: Constants.pageSize,
          search: _currentSearchQuery,
        );

        final newUsers = result['users'] as List<User>;

        // Only proceed if we got new users
        if (newUsers.isNotEmpty) {
          _allUsers.addAll(newUsers);
          _currentSkip += newUsers.length;

          emit(UserLoaded(
            users: List.from(_allUsers),
            hasReachedMax: _allUsers.length >= _totalUsers || newUsers.length < Constants.pageSize,
            isLoadingMore: false,
            searchQuery: _currentSearchQuery,
            totalUsers: _totalUsers,
            currentPage: currentState.currentPage + 1,
          ));
        } else {
          // No more users available
          emit(currentState.copyWith(
            isLoadingMore: false,
            hasReachedMax: true,
          ));
        }
      } catch (e) {
        // On error, just stop loading more but don't emit error state
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onSearchUsers(SearchUsers event, Emitter<UserState> emit) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      add(const ClearSearch());
      return;
    }

    _currentSearchQuery = query;
    _resetPagination();

    emit(UserLoading());

    try {
      final result = await _apiService.getUsers(
        skip: _currentSkip,
        limit: Constants.pageSize,
        search: _currentSearchQuery,
      );

      final users = result['users'] as List<User>;
      _totalUsers = result['total'] as int;
      _allUsers = List.from(users);
      _currentSkip += users.length;

      emit(UserLoaded(
        users: _allUsers,
        hasReachedMax: _allUsers.length >= _totalUsers,
        isLoadingMore: false,
        searchQuery: _currentSearchQuery,
        totalUsers: _totalUsers,
        currentPage: 1,
      ));
    } catch (e) {
      emit(UserError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> _onClearSearch(ClearSearch event, Emitter<UserState> emit) async {
    _currentSearchQuery = null;
    add(const FetchUsers());
  }

  void _resetPagination() {
    _currentSkip = 0;
    _allUsers.clear();
    _totalUsers = 0;
  }

  // Helper method to get current pagination info
  Map<String, dynamic> get paginationInfo => {
    'currentPage': (_currentSkip / Constants.pageSize).floor() + 1,
    'totalPages': (_totalUsers / Constants.pageSize).ceil(),
    'currentSkip': _currentSkip,
    'totalUsers': _totalUsers,
    'hasMore': _allUsers.length < _totalUsers,
  };
}