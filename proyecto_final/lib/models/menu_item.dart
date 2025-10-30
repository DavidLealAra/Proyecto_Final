import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  factory MenuItem.fromMap(String id, Map<String, dynamic> d) {
    double _toDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return 0.0;
    }

    return MenuItem(
      id: id,
      name: (d['name'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      price: _toDouble(d['price']),
    );
  }

  static CollectionReference<MenuItem> menuCollection(String restaurantId) =>
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .withConverter<MenuItem>(
            fromFirestore: (snap, _) =>
                MenuItem.fromMap(snap.id, snap.data()!),
            toFirestore: (item, _) => {
              'name': item.name,
              'description': item.description,
              'price': item.price,
            },
          );
}
