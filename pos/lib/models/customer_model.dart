class CustomerModel {
  final int? id;
  final String name;
  final String? phone;
  final double balance;      // initial always 0 (green if >=0, red if <0)
  final String? imagePath;
  final String? createdAt;
  final String? updatedAt;

  CustomerModel({
    this.id,
    required this.name,
    this.phone,
    this.balance = 0,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    double? balance,
    String? imagePath,
    String? createdAt,
    String? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'balance': balance,
    'imagePath': imagePath,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory CustomerModel.fromMap(Map<String, dynamic> m) => CustomerModel(
    id: m['id'] as int?,
    name: m['name'] as String,
    phone: m['phone'] as String?,
    balance: (m['balance'] as num?)?.toDouble() ?? 0,
    imagePath: m['imagePath'] as String?,
    createdAt: m['createdAt'] as String?,
    updatedAt: m['updatedAt'] as String?,
  );
}
