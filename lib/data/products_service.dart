import 'package:supabase_flutter/supabase_flutter.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String appId;

  Product(
      {required this.id,
      required this.name,
      required this.price,
      required this.appId});

  static Product fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        appId: m['app_id'] as String,
      );
}

class ProductsService {
  final SupabaseClient sb;
  final String appId;
  ProductsService(this.sb, this.appId);

  Future<List<Product>> list() async {
    final rows = await sb
        .from('products')
        .select('id,name,price,app_id')
        .eq('app_id', appId)
        .order('name');
    return (rows as List)
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add({required String name, required double price}) async {
    await sb.from('products').insert({
      'name': name,
      'price': price,
      'app_id': appId,
      'created_by': sb.auth.currentUser!.id,
      'updated_at': DateTime.now().toIso8601String(),
      'active': true,
      'stock': 0,
    });
  }

  Future<void> update(String id,
      {required String name, required double price}) async {
    await sb.from('products').update({
      'name': name,
      'price': price,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> remove(String id) async {
    await sb.from('products').delete().eq('id', id);
  }
}
