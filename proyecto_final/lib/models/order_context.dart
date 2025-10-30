import '../models/restaurant.dart';

enum OrderType { delivery, dineIn, takeAway }

class OrderContext {
  final Restaurant restaurant;
  final OrderType orderType;
  final String? tableNumber;

  const OrderContext({
    required this.restaurant,
    required this.orderType,
    this.tableNumber,
  });
}
