import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/order_widgets.dart';
import 'package:flutter/material.dart';

/// Every payment in the system, from all farmers.
class AllPaymentPage extends StatelessWidget {
  const AllPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALL PAYMENTS'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
      ),
      body: PaymentsListView(url: getAllPayments, showFarmer: true),
    );
  }
}
