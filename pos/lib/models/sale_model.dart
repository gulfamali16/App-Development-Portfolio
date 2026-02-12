// lib/models/sale_model.dart
class SaleModel {
  final int? id;
  final int? customerId;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentType; // CASH or CREDIT
  final String createdAt;

  SaleModel({
    this.id,
    required this.customerId,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentType,
    required this.createdAt,
  });
}

// lib/models/sale_item_model.dart
class SaleItemModel {
  final int? id;
  final int saleId;
  final int? productId;
  final String name;
  final double price;
  final int qty;
  final double lineTotal;

  SaleItemModel({
    this.id,
    required this.saleId,
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
    required this.lineTotal,
  });
}
