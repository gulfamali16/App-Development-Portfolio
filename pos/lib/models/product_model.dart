class ProductModel {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final String? category;
  final String? imagePath; // local file path

  ProductModel({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.category,
    this.imagePath,
  });

  ProductModel copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
    String? category,
    String? imagePath,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'stock': stock,
    'category': category,
    'imagePath': imagePath,
  };

  factory ProductModel.fromMap(Map<String, dynamic> m) => ProductModel(
    id: m['id'] as int?,
    name: m['name'] as String,
    price: (m['price'] as num).toDouble(),
    stock: (m['stock'] as num).toInt(),
    category: m['category'] as String?,
    imagePath: m['imagePath'] as String?,
  );
}
