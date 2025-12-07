import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String name;
  final String category;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String imageUrl;
  final int quantity;
  final int reminderConfig;
  final bool isExpired;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.purchaseDate,
    required this.expiryDate,
    required this.imageUrl,
    this.quantity = 1,
    required this.reminderConfig,
    required this.isExpired,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'imageUrl': imageUrl,
      'quantity': quantity,
      'reminderConfig': reminderConfig,
      'isExpired': isExpired,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ItemModel(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      reminderConfig: map['reminderConfig']?.toInt() ?? 0,
      isExpired: map['isExpired'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  ItemModel copyWith({
    String? id,
    String? name,
    String? category,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? imageUrl,
    int? quantity,
    int? reminderConfig,
    bool? isExpired,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      reminderConfig: reminderConfig ?? this.reminderConfig,
      isExpired: isExpired ?? this.isExpired,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
