import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/order_widgets.dart';
import 'package:flutter/material.dart';

/// Every order in the system, from all farmers.
class AllOrdersPage extends StatelessWidget {
  const AllOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALL ORDERS'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
      ),
      body: OrdersListView(url: getAllOrdersUrl, showFarmer: true),
    );
  }
}
