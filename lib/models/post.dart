import 'comment.dart';

class Post {
  final String id;
  final String author;
  final String content;
  final DateTime createdAt;
  int likes;
  bool isLiked;
  List<Comment> comments;

  Post({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
    List<Comment>? comments,
  }) : comments = comments ?? [];
}