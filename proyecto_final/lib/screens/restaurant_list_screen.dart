import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../models/order_context.dart';
import '../widgets/order_type_sheet.dart';
import 'menu_screen.dart';

class RestaurantListScreen extends StatelessWidget {
  const RestaurantListScreen({super.key});

  Future<void> _seedDemoData(BuildContext context) async {
    final col = Restaurant.collection;

    final r1 = col.doc('demo_r1_fuego_brasa');
    final r2 = col.doc('demo_r2_napo');
    final r3 = col.doc('demo_r3_kumo');

    await r1.set(Restaurant(
      id: r1.id,
      name: 'Fuego y Brasa',
      type: 'Churrasquería',
      supportsDelivery: true,
      supportsDineIn: true,
      supportsTakeAway: false,
      isPremium: true,
      rating: 4.6,
      address: 'Rúa do Pracer, Vigo',
      lat: 42.237,
      lng: -8.720,
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947',
    ));

    await r2.set(Restaurant(
      id: r2.id,
      name: 'La Napo Clásica',
      type: 'Pizzería',
      supportsDelivery: true,
      supportsDineIn: true,
      supportsTakeAway: true,
      isPremium: false,
      rating: 4.3,
      address: 'Av. da Pizza, Vigo',
      lat: 42.239,
      lng: -8.712,
      imageUrl: 'https://images.unsplash.com/photo-1548365328-9f547fb09530',
    ));

    await r3.set(Restaurant(
      id: r3.id,
      name: 'Sushi Kumo',
      type: 'Sushi Bar',
      supportsDelivery: true,
      supportsDineIn: true,
      supportsTakeAway: true,
      isPremium: true,
      rating: 4.7,
      address: 'Rúa do Sushi, Vigo',
      lat: 42.233,
      lng: -8.715,
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
    ));

    Future<void> upsertMenu(
        DocumentReference<Restaurant> restRef, List<Map<String, dynamic>> items) async {
      for (final it in items) {
        final id = it['id'] as String;
        final data = Map<String, dynamic>.from(it)..remove('id');
        await restRef.collection('menu').doc(id).set(data, SetOptions(merge: true));
      }
    }

    await upsertMenu(r1, [
      {'id': 'r1m1', 'name': 'Churrasco Mixto', 'description': 'Tira de asado, criollo y pollo', 'price': 14.50},
      {'id': 'r1m2', 'name': 'Ensalada de la huerta', 'description': 'Lechuga, tomate, cebolla, zanahoria y maíz', 'price': 6.00},
      {'id': 'r1m3', 'name': 'Patatas asadas', 'description': 'Patata gallega con mantequilla y sal', 'price': 4.20},
    ]);

    await upsertMenu(r2, [
      {'id': 'r2m1', 'name': 'Pizza Margarita', 'description': 'Tomate, mozzarella, albahaca', 'price': 8.90},
      {'id': 'r2m2', 'name': 'Pizza Pepperoni', 'description': 'Tomate, mozzarella, pepperoni', 'price': 10.50},
      {'id': 'r2m3', 'name': 'Focaccia de romero', 'description': 'Aceite de oliva, sal, romero', 'price': 5.50},
    ]);

    await upsertMenu(r3, [
      {'id': 'r3m1', 'name': 'Surtido Nigiri (8p)', 'description': 'Salmón, atún, pez mantequilla y langostino', 'price': 12.90},
      {'id': 'r3m2', 'name': 'Uramaki California (8p)', 'description': 'Cangrejo, aguacate, pepino, sésamo', 'price': 9.90},
      {'id': 'r3m3', 'name': 'Gyozas de cerdo (6u)', 'description': 'A la plancha con salsa ponzu', 'price': 6.50},
    ]);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos demo actualizados (IDs fijos).')),
      );
    }
  }

  void _openOrderTypeSelector(BuildContext context, Restaurant restaurant) async {
    final orderType = await showModalBottomSheet<OrderType>(
      context: context,
      showDragHandle: true,
      builder: (_) => OrderTypeSheet(restaurant: restaurant),
    );
    if (orderType == null) return;

    if (orderType == OrderType.dineIn) {
      final tableNumber = await _askTableNumber(context);
      if (tableNumber == null || tableNumber.trim().isEmpty) return;
      _goToMenu(context, OrderContext(
        restaurant: restaurant,
        orderType: orderType,
        tableNumber: tableNumber.trim(),
      ));
    } else {
      _goToMenu(context, OrderContext(
        restaurant: restaurant,
        orderType: orderType,
      ));
    }
  }

  Future<String?> _askTableNumber(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Número de mesa'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Introduce tu mesa'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Continuar')),
        ],
      ),
    );
  }

  void _goToMenu(BuildContext context, OrderContext order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = Restaurant.collection
        .orderBy('isPremium', descending: true)
        .orderBy('rating', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        actions: [
          IconButton(
            tooltip: 'Sembrar demo',
            onPressed: () => _seedDemoData(context),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Salir',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Restaurant>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay restaurantes. Pulsa + para demo.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final restaurant = docs[i].data();
              return Card(
                child: ListTile(
                  leading: restaurant.imageUrl == null
                      ? const Icon(Icons.restaurant)
                      : CircleAvatar(backgroundImage: NetworkImage(restaurant.imageUrl!)),
                  title: Row(
                    children: [
                      if (restaurant.isPremium)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.workspace_premium, size: 18),
                        ),
                      Expanded(child: Text(restaurant.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  subtitle: Text('${restaurant.type} · ${restaurant.address} · ⭐${restaurant.rating.toStringAsFixed(1)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openOrderTypeSelector(context, restaurant),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
