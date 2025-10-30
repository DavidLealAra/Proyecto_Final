import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../models/order_context.dart';
import '../widgets/restaurant_map_view.dart'; // 👈 Widget multiplataforma

class MenuScreen extends StatefulWidget {
  final OrderContext order;

  const MenuScreen({super.key, required this.order});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<MenuItem, int> _cart = {};

  final LatLng _vigoLatLng = const LatLng(42.2406, -8.7207); // Coordenada fallback

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _add(MenuItem item) =>
      setState(() => _cart.update(item, (q) => q + 1, ifAbsent: () => 1));

  void _remove(MenuItem item) => setState(() {
        if (!_cart.containsKey(item)) return;
        final q = _cart[item]!;
        if (q <= 1) {
          _cart.remove(item);
        } else {
          _cart[item] = q - 1;
        }
      });

  double get _total =>
      _cart.entries.fold(0.0, (t, e) => t + e.key.price * e.value);

  String _orderTypeText(OrderType t) {
    switch (t) {
      case OrderType.delivery:
        return 'A domicilio';
      case OrderType.dineIn:
        return 'En restaurante';
      case OrderType.takeAway:
        return 'Para llevar';
    }
  }

  Future<void> _openExternalMap(Restaurant r) async {
    final lat = r.lat ?? _vigoLatLng.latitude;
    final lng = r.lng ?? _vigoLatLng.longitude;
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.order.restaurant;
    final head = <String>[
      r.name,
      _orderTypeText(widget.order.orderType),
      if (widget.order.orderType == OrderType.dineIn &&
          widget.order.tableNumber != null)
        'Mesa: ${widget.order.tableNumber}',
    ].join(' · ');

    final menuQuery = MenuItem.menuCollection(r.id).orderBy('name');

    return Scaffold(
      appBar: AppBar(
        title: Text(head),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Carta', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'Carrito', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Ubicación', icon: Icon(Icons.location_on)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // CARTA
          StreamBuilder<QuerySnapshot<MenuItem>>(
            stream: menuQuery.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('Carta vacía.'));
              }
              final items = docs.map((d) => d.data()).toList();
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final it = items[i];
                  return Card(
                    child: ListTile(
                      title: Text(it.name),
                      subtitle: Text(it.description),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${it.price.toStringAsFixed(2)} €',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          FilledButton.tonal(
                            onPressed: () => _add(it),
                            child: const Text('Añadir'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // CARRITO
          _cart.isEmpty
              ? Center(
                  child: Text(
                    'Tu carrito está vacío',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cart.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final e = _cart.entries.elementAt(i);
                          final it = e.key;
                          final qty = e.value;
                          return Card(
                            child: ListTile(
                              title: Text(it.name),
                              subtitle: Text(
                                  '${it.price.toStringAsFixed(2)} € x $qty'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _remove(it),
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text(
                                    '$qty',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: () => _add(it),
                                    icon:
                                        const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        border: Border(
                          top: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total: ${_total.toStringAsFixed(2)} €',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Pedido confirmado'),
                                  content: Text(
                                    'Gracias por tu pedido en ${r.name}.\n'
                                    'Tipo: ${_orderTypeText(widget.order.orderType)}'
                                    '${widget.order.orderType ==
                                                OrderType.dineIn &&
                                            widget.order.tableNumber != null
                                        ? '\nMesa: ${widget.order.tableNumber}'
                                        : ''}\n'
                                    'Total: ${_total.toStringAsFixed(2)} €',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        setState(() => _cart.clear());
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Confirmar pedido'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

          // UBICACIÓN (multiplataforma)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dirección',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(r.address.isNotEmpty ? r.address : 'Sin dirección'),
                const SizedBox(height: 16),
                // 👇 Aquí usamos el nuevo widget multiplataforma
                RestaurantMapView(restaurant: r),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openExternalMap(r),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir en Google Maps'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
