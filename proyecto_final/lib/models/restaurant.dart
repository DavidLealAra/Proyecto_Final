import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String type;
  final bool supportsDelivery;
  final bool supportsDineIn;
  final bool supportsTakeAway;
  final bool isPremium;
  final double rating;
  final String address;
  final String? imageUrl;
  final double? lat;
  final double? lng;

  Restaurant({
    required this.id,
    required this.name,
    required this.type,
    required this.supportsDelivery,
    required this.supportsDineIn,
    required this.supportsTakeAway,
    required this.isPremium,
    required this.rating,
    required this.address,
    this.imageUrl,
    this.lat,
    this.lng,
  });

  factory Restaurant.fromMap(String id, Map<String, dynamic> d) {
    double? _toDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return null;
    }

    return Restaurant(
      id: id,
      name: (d['name'] ?? '') as String,
      type: (d['type'] ?? d['category'] ?? 'General') as String,
      supportsDelivery: (d['supportsDelivery'] ?? true) as bool,
      supportsDineIn: (d['supportsDineIn'] ?? true) as bool,
      supportsTakeAway: (d['supportsTakeAway'] ?? false) as bool,
      isPremium: (d['isPremium'] ?? false) as bool,
      rating: _toDouble(d['rating']) ?? 0.0,
      address: (d['address'] ?? '') as String,
      imageUrl: d['imageUrl'] as String?,
      lat: _toDouble(d['lat']),
      lng: _toDouble(d['lng']),
    );
  }

  static CollectionReference<Restaurant> get collection =>
      FirebaseFirestore.instance
          .collection('restaurants')
          .withConverter<Restaurant>(
            fromFirestore: (snap, _) =>
                Restaurant.fromMap(snap.id, snap.data()!),
            toFirestore: (rest, _) => {
              'name': rest.name,
              'type': rest.type,
              'supportsDelivery': rest.supportsDelivery,
              'supportsDineIn': rest.supportsDineIn,
              'supportsTakeAway': rest.supportsTakeAway,
              'isPremium': rest.isPremium,
              'rating': rest.rating,
              'address': rest.address,
              'imageUrl': rest.imageUrl,
              'lat': rest.lat,
              'lng': rest.lng,
            },
          );
}
