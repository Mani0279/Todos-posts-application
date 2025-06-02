import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/todo.dart';
import '../services/api_service.dart';

// Events
abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserTodos extends TodoEvent {
  final int userId;

  const LoadUserTodos(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RefreshUserTodos extends TodoEvent {
  final int userId;

  const RefreshUserTodos(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ToggleTodo extends TodoEvent {
  final int todoId;

  const ToggleTodo(this.todoId);

  @override
  List<Object?> get props => [todoId];
}

// States
abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;
  final int? currentUserId;

  const TodoLoaded(this.todos, {this.currentUserId});

  TodoLoaded copyWith({
    List<Todo>? todos,
    int? currentUserId,
  }) {
    return TodoLoaded(
      todos ?? this.todos,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [todos, currentUserId];
}

class TodoError extends TodoState {
  final String message;

  const TodoError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final ApiService _apiService;
  List<Todo> _currentTodos = [];
  int? _currentUserId;

  TodoBloc(this._apiService) : super(TodoInitial()) {
    on<LoadUserTodos>(_onLoadUserTodos);
    on<RefreshUserTodos>(_onRefreshUserTodos);
    on<ToggleTodo>(_onToggleTodo);
  }

  Future<void> _onLoadUserTodos(LoadUserTodos event, Emitter<TodoState> emit) async {
    emit(TodoLoading());

    try {
      final todos = await _apiService.getUserTodos(event.userId);
      _currentTodos = List.from(todos);
      _currentUserId = event.userId;

      emit(TodoLoaded(_currentTodos, currentUserId: _currentUserId));
    } catch (e) {
      emit(TodoError('Failed to load todos: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshUserTodos(RefreshUserTodos event, Emitter<TodoState> emit) async {
    try {
      final todos = await _apiService.getUserTodos(event.userId);
      _currentTodos = List.from(todos);
      _currentUserId = event.userId;

      emit(TodoLoaded(_currentTodos, currentUserId: _currentUserId));
    } catch (e) {
      emit(TodoError('Failed to refresh todos: ${e.toString()}'));
    }
  }

  Future<void> _onToggleTodo(ToggleTodo event, Emitter<TodoState> emit) async {
    final currentState = state;
    if (currentState is TodoLoaded) {
      // Find and toggle the todo locally
      final updatedTodos = _currentTodos.map((todo) {
        if (todo.id == event.todoId) {
          return todo.copyWith(completed: !todo.completed);
        }
        return todo;
      }).toList();

      _currentTodos = updatedTodos;
      emit(TodoLoaded(_currentTodos, currentUserId: _currentUserId));
    }
  }

  // Helper methods
  List<Todo> get currentTodos => List.from(_currentTodos);
  int? get currentUserId => _currentUserId;

  List<Todo> get completedTodos =>
      _currentTodos.where((todo) => todo.completed).toList();

  List<Todo> get pendingTodos =>
      _currentTodos.where((todo) => !todo.completed).toList();
}