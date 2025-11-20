import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../models/restaurant.dart';

class RestaurantOwnerScreen extends StatelessWidget {
  final String restaurantId;
  final String ownerName;

  const RestaurantOwnerScreen({
    super.key,
    required this.restaurantId,
    required this.ownerName,
  });

  DocumentReference<MenuItem> _menuItemRef(MenuItem item) {
    return MenuItem.menuCollection(restaurantId).doc(item.id);
  }

  Future<void> _showMenuItemDialog(BuildContext context,
      {MenuItem? item}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final descriptionCtrl =
        TextEditingController(text: item?.description ?? '');
    final priceCtrl =
        TextEditingController(text: item != null ? item.price.toString() : '');

    Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(item == null ? 'Nuevo plato' : 'Editar plato'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Introduce un nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Introduce una descripción'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '€ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Introduce un precio';
                      }
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) {
                        return 'Introduce un número válido (> 0)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final parsed =
                    double.parse(priceCtrl.text.replaceAll(',', '.'));
                Navigator.of(ctx).pop({
                  'name': nameCtrl.text.trim(),
                  'description': descriptionCtrl.text.trim(),
                  'price': parsed,
                });
              },
              child: Text(item == null ? 'Crear' : 'Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      final col = MenuItem.menuCollection(restaurantId);
      final name = result['name'] as String;
      final description = result['description'] as String;
      final price = result['price'] as double;

      if (item == null) {
        final doc = col.doc();
        final newItem = MenuItem(
          id: doc.id,
          name: name,
          description: description,
          price: price,
        );
        await doc.set(newItem);
      } else {
        final updated = MenuItem(
          id: item.id,
          name: name,
          description: description,
          price: price,
        );
        await _menuItemRef(item).set(updated);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item == null
              ? 'Plato creado correctamente.'
              : 'Plato actualizado correctamente.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Future<void> _deleteMenuItem(BuildContext context, MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plato'),
        content:
            Text('¿Seguro que quieres eliminar "${item.name}" de la carta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _menuItemRef(item).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plato eliminado.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantRef = Restaurant.collection.doc(restaurantId);

    return StreamBuilder<DocumentSnapshot<Restaurant>>(
      stream: restaurantRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }

        final restaurant = snap.data?.data();
        if (restaurant == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi restaurante'),
              actions: [
                IconButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: const Center(
              child: Text(
                'El restaurante asignado ya no existe. Contacta con el administrador.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(restaurant.name),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showMenuItemDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Añadir plato'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $ownerName',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(restaurant.type),
                          avatar: const Icon(Icons.category, size: 18),
                        ),
                        if (restaurant.supportsDineIn)
                          const Chip(
                            label: Text('Mesa'),
                            avatar: Icon(Icons.restaurant, size: 18),
                          ),
                        if (restaurant.supportsDelivery)
                          const Chip(
                            label: Text('Delivery'),
                            avatar: Icon(Icons.delivery_dining, size: 18),
                          ),
                        if (restaurant.supportsTakeAway)
                          const Chip(
                            label: Text('Para llevar'),
                            avatar: Icon(Icons.shopping_bag, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(restaurant.address),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: StreamBuilder<QuerySnapshot<MenuItem>>(
                  stream: MenuItem.menuCollection(restaurant.id)
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, menuSnap) {
                    if (menuSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (menuSnap.hasError) {
                      return Center(child: Text('Error: ${menuSnap.error}'));
                    }

                    final docs = menuSnap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Tu carta está vacía.',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => _showMenuItemDialog(context),
                              child: const Text('Añadir el primer plato'),
                            ),
                          ],
                        ),
                      );
                    }

                    final items = docs.map((d) => d.data()).toList();

                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(item.description),
                            leading: CircleAvatar(
                              child: Text(item.price.toStringAsFixed(2)),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () =>
                                      _showMenuItemDialog(context, item: item),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () =>
                                      _deleteMenuItem(context, item),
                                  icon: const Icon(Icons.delete_forever),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}