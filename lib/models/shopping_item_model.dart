class ShoppingItemModel {
  final String id;
  final String name;
  final bool isChecked;

  ShoppingItemModel({
    required this.id,
    required this.name,
    this.isChecked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isChecked': isChecked,
    };
  }

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isChecked: map['isChecked'] ?? false,
    );
  }

  ShoppingItemModel copyWith({
    String? id,
    String? name,
    bool? isChecked,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
