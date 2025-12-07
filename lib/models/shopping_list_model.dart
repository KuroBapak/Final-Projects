import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final int itemCount;

  ShoppingListModel({
    required this.id,
    required this.title,
    required this.createdAt,
    this.itemCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'itemCount': itemCount,
    };
  }

  factory ShoppingListModel.fromMap(Map<String, dynamic> map) {
    return ShoppingListModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      itemCount: map['itemCount'] ?? 0,
    );
  }
}
