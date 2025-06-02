import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/post.dart';
import '../services/api_service.dart';

// Events
abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserPosts extends PostEvent {
  final int userId;

  const LoadUserPosts(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RefreshUserPosts extends PostEvent {
  final int userId;

  const RefreshUserPosts(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreatePost extends PostEvent {
  final Post post;

  const CreatePost(this.post);

  @override
  List<Object?> get props => [post];
}

class AddLocalPost extends PostEvent {
  final Post post;

  const AddLocalPost(this.post);

  @override
  List<Object?> get props => [post];
}

// States
abstract class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostLoaded extends PostState {
  final List<Post> posts;
  final int? currentUserId;

  const PostLoaded(this.posts, {this.currentUserId});

  PostLoaded copyWith({
    List<Post>? posts,
    int? currentUserId,
  }) {
    return PostLoaded(
      posts ?? this.posts,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [posts, currentUserId];
}

class PostError extends PostState {
  final String message;

  const PostError(this.message);

  @override
  List<Object?> get props => [message];
}

class PostCreating extends PostState {}

class PostCreated extends PostState {
  final Post post;

  const PostCreated(this.post);

  @override
  List<Object?> get props => [post];
}

// BLoC
class PostBloc extends Bloc<PostEvent, PostState> {
  final ApiService _apiService;
  List<Post> _currentPosts = [];
  int? _currentUserId;

  PostBloc(this._apiService) : super(PostInitial()) {
    on<LoadUserPosts>(_onLoadUserPosts);
    on<RefreshUserPosts>(_onRefreshUserPosts);
    on<CreatePost>(_onCreatePost);
    on<AddLocalPost>(_onAddLocalPost);
  }

  Future<void> _onLoadUserPosts(LoadUserPosts event, Emitter<PostState> emit) async {
    emit(PostLoading());

    try {
      final posts = await _apiService.getUserPosts(event.userId);
      _currentPosts = List.from(posts);
      _currentUserId = event.userId;

      emit(PostLoaded(_currentPosts, currentUserId: _currentUserId));
    } catch (e) {
      emit(PostError('Failed to load posts: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshUserPosts(RefreshUserPosts event, Emitter<PostState> emit) async {
    try {
      final posts = await _apiService.getUserPosts(event.userId);
      _currentPosts = List.from(posts);
      _currentUserId = event.userId;

      emit(PostLoaded(_currentPosts, currentUserId: _currentUserId));
    } catch (e) {
      emit(PostError('Failed to refresh posts: ${e.toString()}'));
    }
  }

  Future<void> _onCreatePost(CreatePost event, Emitter<PostState> emit) async {
    emit(PostCreating());

    try {
      final createdPost = await _apiService.createPost(event.post);
      emit(PostCreated(createdPost));

      // Add to current posts list at the beginning
      _currentPosts = [createdPost, ..._currentPosts];
      emit(PostLoaded(_currentPosts, currentUserId: _currentUserId));
    } catch (e) {
      emit(PostError('Failed to create post: ${e.toString()}'));
    }
  }

  Future<void> _onAddLocalPost(AddLocalPost event, Emitter<PostState> emit) async {
    // Add to current posts list at the beginning
    _currentPosts = [event.post, ..._currentPosts];
    emit(PostLoaded(_currentPosts, currentUserId: _currentUserId));
  }

  // Helper method to get current posts
  List<Post> get currentPosts => List.from(_currentPosts);

  // Helper method to get current user ID
  int? get currentUserId => _currentUserId;
}