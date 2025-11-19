import 'product_model.dart';

class CartLine {
  final ProductModel product;
  int qty;

  CartLine({required this.product, this.qty = 1});

  double get lineTotal => product.price * qty;
}
