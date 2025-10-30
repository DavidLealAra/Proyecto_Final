import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/order_context.dart';

class OrderTypeSheet extends StatelessWidget {
  final Restaurant restaurant;

  const OrderTypeSheet({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final items = <_OrderOption>[
      if (restaurant.supportsDelivery)
        _OrderOption(
          label: 'A domicilio',
          icon: Icons.delivery_dining,
          type: OrderType.delivery,
          help: 'Introduce dirección en el siguiente paso (versión real)',
        ),
      if (restaurant.supportsDineIn)
        _OrderOption(
          label: 'En el restaurante',
          icon: Icons.restaurant,
          type: OrderType.dineIn,
          help: 'Te pediremos el nº de mesa',
        ),
      if (restaurant.supportsTakeAway)
        _OrderOption(
          label: 'Para llevar',
          icon: Icons.shopping_bag,
          type: OrderType.takeAway,
          help: 'Recoge en local',
        ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              restaurant.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...items.map(
              (o) => ListTile(
                leading: Icon(o.icon),
                title: Text(o.label),
                subtitle: Text(o.help),
                onTap: () => Navigator.pop(context, o.type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderOption {
  final String label;
  final IconData icon;
  final OrderType type;
  final String help;

  _OrderOption({
    required this.label,
    required this.icon,
    required this.type,
    required this.help,
  });
}
