// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../models/food_item.dart';

enum PaymentMode { cash, mobileMoney }

String paymentModeLabel(PaymentMode mode) {
  switch (mode) {
    case PaymentMode.cash:
      return 'Cash on Delivery';
    case PaymentMode.mobileMoney:
      return 'MTN Momo';
  }
}

enum OrderStage { placed, preparing, inKitchen, delivered }

enum DeliveryDestinationType { doorstep, table }

class DeliveryDestination {
  final DeliveryDestinationType type;
  final String details;

  const DeliveryDestination({
    required this.type,
    required this.details,
  });

  String get summary {
    switch (type) {
      case DeliveryDestinationType.doorstep:
        return 'Doorstep: $details';
      case DeliveryDestinationType.table:
        return 'Table: $details';
    }
  }
}

class CartLine {
  final FoodItem item;
  int quantity;

  CartLine({required this.item, this.quantity = 1});

  double get total => item.price * quantity;
}

class Order {
  final String id;
  final List<CartLine> items;
  final PaymentMode paymentMode;
  final DateTime createdAt;
  OrderStage stage;

  Order({
    required this.id,
    required this.items,
    required this.paymentMode,
    required this.createdAt,
    this.stage = OrderStage.placed,
  });

  double get total =>
      items.fold(0, (sum, line) => sum + (line.item.price * line.quantity));
}

class AppState extends ChangeNotifier {
  final Map<String, CartLine> _cart = {};
  final List<Order> _orders = [];
  DeliveryDestination? _destination;
  String _displayName = '';
  String _email = '';
  String _phone = '';
  String _role = '';

  List<CartLine> get cartLines => _cart.values.toList();
  List<Order> get orders => List.unmodifiable(_orders);
  DeliveryDestination? get destination => _destination;
  String get displayName => _displayName;
  String get email => _email;
  String get phone => _phone;
  String get role => _role;
  bool get isAdmin =>
      _role.toLowerCase() == 'admin' || _role.toLowerCase() == 'chef';

  bool get hasCartItems => _cart.isNotEmpty;

  void addToCart(FoodItem item) {
    final existing = _cart[item.id];
    if (existing == null) {
      _cart[item.id] = CartLine(item: item, quantity: 1);
    } else {
      existing.quantity += 1;
    }
    notifyListeners();
  }

  void addToCartWithQuantity(FoodItem item, int quantity) {
    if (quantity <= 0) return;
    final existing = _cart[item.id];
    if (existing == null) {
      _cart[item.id] = CartLine(item: item, quantity: quantity);
    } else {
      existing.quantity += quantity;
    }
    notifyListeners();
  }

  void removeFromCart(FoodItem item) {
    final existing = _cart[item.id];
    if (existing == null) return;
    existing.quantity -= 1;
    if (existing.quantity <= 0) {
      _cart.remove(item.id);
    }
    notifyListeners();
  }

  void setQuantity(FoodItem item, int quantity) {
    if (quantity <= 0) {
      _cart.remove(item.id);
    } else {
      _cart[item.id] = CartLine(item: item, quantity: quantity);
    }
    notifyListeners();
  }

  void setDestination(DeliveryDestination? destination) {
    _destination = destination;
    notifyListeners();
  }

  void setProfile({
    required String displayName,
    required String email,
    required String phone,
  }) {
    _displayName = displayName;
    _email = email;
    _phone = phone;
    notifyListeners();
  }

  void setRole(String role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }

  double get subtotal => _cart.values.fold(0, (sum, line) => sum + line.total);

  double get deliveryFee => hasCartItems ? 1.75 : 0;

  double get total => subtotal + deliveryFee;

  Order placeOrder(PaymentMode paymentMode) {
    final items = _cart.values
        .map((line) => CartLine(item: line.item, quantity: line.quantity))
        .toList();
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: items,
      paymentMode: paymentMode,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    _cart.clear();
    notifyListeners();
    return order;
  }

  void advanceOrderStage(Order order) {
    switch (order.stage) {
      case OrderStage.placed:
        order.stage = OrderStage.preparing;
        break;
      case OrderStage.preparing:
        order.stage = OrderStage.inKitchen;
        break;
      case OrderStage.inKitchen:
        order.stage = OrderStage.delivered;
        break;
      case OrderStage.delivered:
        break;
    }
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
