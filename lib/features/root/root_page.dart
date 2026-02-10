import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/dine_bottom_nav.dart';
import '../home/home_page.dart';
import '../cart/cart_page.dart';
import '../orders/orders_page.dart';
import '../profile/profile_page.dart';
import '../admin/admin_foods_page.dart';
import '../admin/admin_orders_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = AppScope.of(context).isAdmin;
    final pages = [
      const HomePage(),
      isAdmin ? const AdminOrdersPage() : const OrdersPage(),
      isAdmin ? const AdminFoodsPage() : const CartPage(),
      const ProfilePage(),
    ];
    final labels = isAdmin
        ? const ['Home', 'Orders', 'Foods', 'Profile']
        : const ['Home', 'Orders', ' Cart ', 'Profile'];
    final icons = isAdmin
        ? const [
            Icons.home_outlined,
            Icons.receipt_long_outlined,
            Icons.restaurant_menu_outlined,
            Icons.person_outline,
          ]
        : const [
            Icons.home_outlined,
            Icons.receipt_long_outlined,
            Icons.shopping_cart_outlined,
            Icons.person_outline,
          ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: pages,
              ),
            ),
            SafeArea(
              top: false,
              child: DineBottomNav(
                currentIndex: _index,
                onTap: (value) => setState(() => _index = value),
                labels: labels,
                icons: icons,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
