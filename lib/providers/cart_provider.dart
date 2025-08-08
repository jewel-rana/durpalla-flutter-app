import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/cart_model.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService api;
  final Map<String, CartItem> _itemsByLock = {}; // key = lockId
  final Map<String, Timer> _expiryTimers = {};

  CartProvider(this.api);

  List<CartItem> get items => _itemsByLock.values.toList()
    ..sort((a,b) => a.expiresAt.compareTo(b.expiresAt));

  bool get isEmpty => _itemsByLock.isEmpty;

  Future<void> syncFromServer() async {
    final list = await api.fetchCart();
    // Rebuild from server; clear local timers and set again
    for (final t in _expiryTimers.values) { t.cancel(); }
    _expiryTimers.clear();
    _itemsByLock.clear();

    for (final m in list) {
      final item = CartItem(
        cartItemId: m['cart_item_id'],
        lockId: m['lock_id'],
        expiresAt: DateTime.parse(m['expires_at']).toUtc(),
        price: m['price'],
        itemType: m['item_type'],
        itemId: m['item_id'],
        vehicleName: m['meta']?['vehicle_name'] ?? '',
        cabinNo: m['meta']?['cabin_no'],
        routeName: m['meta']?['route_name'],
      );
      _itemsByLock[item.lockId] = item;
      _startExpiryTimer(item);
    }
    notifyListeners();
  }

  Future<CartItem> addLockedItem(Map<String, dynamic> payload) async {
    final item = CartItem(
      cartItemId: payload['cart_item_id'],
      lockId: payload['lock_id'],
      expiresAt: DateTime.parse(payload['expires_at']).toUtc(),
      price: payload['price'],
      itemType: payload['item_type'] ?? 'cabin',
      itemId: payload['item_id'],
      vehicleName: payload['meta']?['vehicle_name'] ?? '',
      cabinNo: payload['meta']?['cabin_no'],
      routeName: payload['meta']?['route_name'],
    );
    _itemsByLock[item.lockId] = item;
    _startExpiryTimer(item);
    notifyListeners();
    return item;
  }

  void _startExpiryTimer(CartItem item) {
    final ms = item.remaining.inMilliseconds;
    if (ms <= 0) {
      _expire(item.lockId);
      return;
    }
    _expiryTimers[item.lockId]?.cancel();
    _expiryTimers[item.lockId] = Timer(Duration(milliseconds: ms), () {
      _expire(item.lockId);
    });
  }

  void _expire(String lockId) {
    _expiryTimers.remove(lockId)?.cancel();
    _itemsByLock.remove(lockId);
    notifyListeners();
    // No server call here—server already expired it. (Optional: best-effort DELETE)
  }

  Future<void> removeItem(String lockId) async {
    final item = _itemsByLock[lockId];
    if (item == null) return;
    try {
      await api.releaseLock(lockId);
    } catch (_) {
      // ignore; server might have expired it
    } finally {
      _expiryTimers.remove(lockId)?.cancel();
      _itemsByLock.remove(lockId);
      notifyListeners();
    }
  }

  void clearAllLocal() {
    for (final t in _expiryTimers.values) { t.cancel(); }
    _expiryTimers.clear();
    _itemsByLock.clear();
    notifyListeners();
  }
}