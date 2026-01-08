import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/sale_model.dart';
import '../models/cart_item_model.dart';
import 'database_service.dart';
import 'product_service.dart';
import 'customer_service.dart';
import 'firestore_sync_service.dart';

/// Service for managing sales transactions
class SalesService {
  final DatabaseService _databaseService = DatabaseService();
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final FirestoreSyncService _syncService = FirestoreSyncService();

  /// Create a new sale
  Future<String> createSale(SaleModel sale) async {
    try {
      final db = await _databaseService.database;

      // Convert sale to JSON with properly formatted items
      final saleData = sale.toJson();
      saleData['items'] = jsonEncode(sale.items.map((item) => item.toJson()).toList());

      // Insert sale
      await db.insert(
        'sales',
        saleData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update product quantities
      for (final item in sale.items) {
        await _productService.updateProductQuantity(
          item.productId,
          -item.quantity, // Negative to reduce stock
        );
      }

      // Update customer balance if payment is on credit
      if (sale.paymentMethod == 'credit' && sale.customerId != null) {
        await _customerService.updateCustomerBalance(
          sale.customerId!,
          -sale.total, // Negative because customer owes us
        );
      }

      // Update customer's last purchase date
      if (sale.customerId != null) {
        await _customerService.updateLastPurchase(sale.customerId!);
      }

      // Sync to Firestore (if online)
      await _syncService.syncSale(sale);

      return sale.id;
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }
  }

  /// Get all sales
  Future<List<SaleModel>> getAllSales() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sales',
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => _saleFromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load sales: $e');
    }
  }

  /// Get all sales (alias for compatibility)
  Future<List<SaleModel>> getSales() async {
    return getAllSales();
  }

  /// Get sale by ID
  Future<SaleModel?> getSaleById(String id) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return _saleFromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to load sale: $e');
    }
  }

  /// Get sales by customer
  Future<List<SaleModel>> getSalesByCustomer(String customerId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sales',
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => _saleFromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load customer sales: $e');
    }
  }

  /// Get today's sales
  Future<List<SaleModel>> getTodaysSales() async {
    try {
      final db = await _databaseService.database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'sales',
        where: 'createdAt >= ?',
        whereArgs: [startOfDay.toIso8601String()],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => _saleFromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load today\'s sales: $e');
    }
  }

  /// Get today's sales total
  Future<double> getTodaysSalesTotal() async {
    try {
      final sales = await getTodaysSales();
      double total = 0.0;
      for (var sale in sales) {
        total += sale.total;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to calculate today\'s sales: $e');
    }
  }

  /// Get sales count
  Future<int> getSalesCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM sales');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get sales count: $e');
    }
  }

  /// Calculate totals with tax and discount
  Map<String, double> calculateTotals({
    required double subtotal,
    double discount = 0.0,
    String? discountType,
    double taxRate = 8.0,
  }) {
    double discountAmount = discount;
    
    // Calculate discount amount
    if (discountType == 'percentage') {
      discountAmount = subtotal * (discount / 100);
    }
    
    // Calculate subtotal after discount
    final subtotalAfterDiscount = subtotal - discountAmount;
    
    // Calculate tax on discounted amount
    final taxAmount = subtotalAfterDiscount * (taxRate / 100);
    
    // Calculate total
    final total = subtotalAfterDiscount + taxAmount;
    
    return {
      'subtotal': subtotal,
      'discount': discountAmount,
      'tax': taxAmount,
      'total': total,
    };
  }

  /// Parse sale from database map
  SaleModel _saleFromMap(Map<String, dynamic> map) {
    // Parse items from JSON string
    List<CartItemModel> items = [];
    try {
      final itemsJson = jsonDecode(map['items'] as String) as List;
      items = itemsJson
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      items = [];
    }

    return SaleModel(
      id: map['id'] as String,
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String,
      items: items,
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      discountType: map['discountType'] as String?,
      tax: (map['tax'] as num).toDouble(),
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 8.0,
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
      paymentStatus: map['paymentStatus'] as String? ?? 'paid',
      cashierId: map['cashierId'] as String,
      cashierName: map['cashierName'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      syncStatus: map['syncStatus'] as int? ?? 0,
    );
  }

  /// Get sales within a date range
  Future<List<SaleModel>> getSalesInRange(DateTime startDate, DateTime endDate) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sales',
        where: 'createdAt >= ? AND createdAt <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'createdAt DESC',
      );
      
      // Safely parse with null checks - filter out any null results
      return maps.map((map) {
        try {
          return _saleFromMap(map);
        } catch (e) {
          debugPrint('Error parsing sale: $e');
          return null;
        }
      }).whereType<SaleModel>().toList(); // Filter out nulls
    } catch (e) {
      debugPrint('Error getting sales in range: $e');
      return [];
    }
  }

  /// Get sales total for a date range
  Future<double> getSalesTotal(DateTime startDate, DateTime endDate) async {
    try {
      final sales = await getSalesInRange(startDate, endDate);
      return sales.fold<double>(0.0, (sum, sale) => sum + sale.total);
    } catch (e) {
      throw Exception('Failed to calculate sales total: $e');
    }
  }

  /// Get gross profit for a date range (Sales - Cost)
  Future<double> getGrossProfit(DateTime startDate, DateTime endDate) async {
    try {
      final sales = await getSalesInRange(startDate, endDate);
      double totalRevenue = 0.0;
      double totalCost = 0.0;
      
      for (var sale in sales) {
        totalRevenue += sale.total;
        // Calculate cost from items (assuming customPrice is selling price)
        // For simplicity, estimate 70% of revenue as profit (30% cost)
        totalCost += sale.total * 0.3;
      }
      
      return totalRevenue - totalCost;
    } catch (e) {
      throw Exception('Failed to calculate gross profit: $e');
    }
  }

  /// Get order count for a date range
  Future<int> getOrderCount(DateTime startDate, DateTime endDate) async {
    try {
      final sales = await getSalesInRange(startDate, endDate);
      return sales.length;
    } catch (e) {
      throw Exception('Failed to get order count: $e');
    }
  }

  /// Get recent sales with limit (with offline support)
  Future<List<SaleModel>> getRecentSales({int limit = 10}) async {
    try {
      // First get from local SQLite
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sales',
        orderBy: 'createdAt DESC',
        limit: limit,
      );
      final localSales = maps.map((map) => _saleFromMap(map)).toList();
      
      // If online, also fetch from Firestore and merge
      if (await _syncService.isOnline()) {
        try {
          final cloudSales = await _syncService.fetchSalesFromCloud();
          
          // Convert cloud sales to SaleModel
          final cloudSaleModels = <SaleModel>[];
          for (final sale in cloudSales) {
            try {
              // Parse items from cloud format
              final items = (sale['items'] as List?)?.map((item) {
                return {
                  'productId': item['productId'],
                  'productName': item['productName'],
                  'quantity': item['quantity'],
                  'price': item['unitPrice'],
                  'total': item['lineTotal'],
                };
              }).toList() ?? [];
              
              final saleMap = {
                'id': sale['id'],
                'customerId': sale['customerId'],
                'customerName': sale['customerName'],
                'items': items.toString(),
                'subtotal': sale['subtotal'],
                'discount': sale['discount'] ?? 0.0,
                'tax': sale['tax'] ?? 0.0,
                'taxRate': sale['taxRate'] ?? 8.0,
                'total': sale['total'],
                'paymentMethod': sale['paymentMethod'],
                'paymentStatus': sale['paymentStatus'],
                'createdAt': sale['createdAt'],
              };
              cloudSaleModels.add(_saleFromMap(saleMap));
            } catch (e) {
              debugPrint('Error parsing cloud sale: $e');
            }
          }
          
          // Merge and deduplicate by sale ID
          final mergedMap = <String, SaleModel>{};
          for (final sale in [...localSales, ...cloudSaleModels]) {
            mergedMap[sale.id] = sale;
          }
          
          // Sort by date and limit
          final merged = mergedMap.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return merged.take(limit).toList();
        } catch (e) {
          debugPrint('Error fetching from cloud: $e');
        }
      }
      
      return localSales;
    } catch (e) {
      throw Exception('Failed to load recent sales: $e');
    }
  }

  /// Get all sales (alias for compatibility)
  Future<List<SaleModel>> getAllSales() async {
    return getSales();
  }
}
