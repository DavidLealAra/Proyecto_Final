import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String? name;
  final String email;
  final String role;
  final bool isActive;
  final String? restaurantId;

  static const roleCustomer = 'customer';
  static const roleRestaurant = 'restaurant';

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.name,
    this.restaurantId,
  });

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return AppUser(
      id: snapshot.id,
      name: data['name'] as String?,
      email: (data['email'] ?? '') as String,
      role: (data['role'] ?? roleCustomer) as String,
      isActive: (data['isActive'] ?? true) as bool,
      restaurantId: data['restaurantId'] as String?,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'restaurantId': restaurantId,
    };
  }

  static DocumentReference<AppUser> doc(String uid) => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .withConverter<AppUser>(
        fromFirestore: AppUser.fromFirestore,
        toFirestore: (user, _) => user.toFirestore(),
      );
}