import 'package:farmer/pages/all_orders_page.dart';
import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/order_widgets.dart';
import 'package:flutter/material.dart';

/// Orders placed for the logged-in farmer's items.
class OrdersPage extends StatelessWidget {
  final int userId;
  const OrdersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY ORDERS'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
        actions: [
          IconButton(
            tooltip: 'All orders',
            icon: const Icon(Icons.all_inbox),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AllOrdersPage())),
          ),
        ],
      ),
      body: OrdersListView(url: '${apiUrl('fOrders')}/$userId'),
    );
  }
}
