class ProductItem {
  final String id;
  final String name;
  final double price;
  final String? category;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    this.category,
  });

  ProductItem copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }
}
