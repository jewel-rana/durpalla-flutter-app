class CartItem {
  final String cartItemId;
  final String lockId;
  final DateTime expiresAt;
  final int price;
  final String itemType; // seat|cabin
  final int itemId;
  final String vehicleName;
  final String? cabinNo;
  final String? routeName;

  CartItem({
    required this.cartItemId,
    required this.lockId,
    required this.expiresAt,
    required this.price,
    required this.itemType,
    required this.itemId,
    required this.vehicleName,
    this.cabinNo,
    this.routeName,
  });

  Duration get remaining => expiresAt.difference(DateTime.now().toUtc());
}
