import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final barcodeServiceProvider = Provider<BarcodeService>((ref) {
  return BarcodeService();
});

class BarcodeService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  Future<ProductDetails?> fetchProductDetails(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ExpiryGuard - Android - Version 1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          
          // Try to find the best name, prioritizing Indonesian
          String name = product['product_name_id'] ?? 
                       product['product_name'] ?? 
                       product['product_name_en'] ?? 
                       '';
          
          // If name is still empty, try brands + generic name
          if (name.isEmpty) {
            final brand = product['brands'] ?? '';
            final generic = product['generic_name'] ?? '';
            if (brand.isNotEmpty || generic.isNotEmpty) {
              name = '$brand $generic'.trim();
            }
          }

          return ProductDetails(
            name: name,
            category: _mapCategory(product['categories_tags'] ?? []),
            imageUrl: product['image_url'] ?? '',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching product details: $e');
      return null;
    }
  }

  String _mapCategory(List<dynamic> tags) {
    // Simple mapping logic to match our AppConstants.categories
    // This can be expanded
    final categories = tags.map((e) => e.toString().toLowerCase()).toList();
    
    if (categories.any((c) => c.contains('dairy') || c.contains('milk') || c.contains('cheese'))) {
      return 'Dairy';
    }
    if (categories.any((c) => c.contains('meat') || c.contains('chicken') || c.contains('beef'))) {
      return 'Meat';
    }
    if (categories.any((c) => c.contains('fruit') || c.contains('vegetable') || c.contains('plant'))) {
      return 'Fruit & Veg';
    }
    if (categories.any((c) => c.contains('medicine') || c.contains('drug') || c.contains('pharmacy'))) {
      return 'Medicine';
    }
    
    return 'Pantry'; // Default
  }
}

class ProductDetails {
  final String name;
  final String category;
  final String imageUrl;

  ProductDetails({
    required this.name,
    required this.category,
    required this.imageUrl,
  });
}
