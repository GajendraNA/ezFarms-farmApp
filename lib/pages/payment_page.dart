import 'package:farmer/pages/all_payment_page.dart';
import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/order_widgets.dart';
import 'package:flutter/material.dart';

/// Payments received by the logged-in farmer.
class PaymentPage extends StatelessWidget {
  final int userId;
  const PaymentPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY PAYMENTS'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
        actions: [
          IconButton(
            tooltip: 'All payments',
            icon: const Icon(Icons.all_inbox),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AllPaymentPage())),
          ),
        ],
      ),
      body: PaymentsListView(url: '${apiUrl('fPayment')}/$userId'),
    );
  }
}
