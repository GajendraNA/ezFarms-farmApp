import 'package:farmer/pages/addInventoy_page.dart';
import 'package:farmer/pages/home_page.dart';
import 'package:farmer/pages/orders_page.dart';
import 'package:farmer/pages/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavigationBarPage extends StatefulWidget {
  final int userId;

  const BottomNavigationBarPage({super.key, required this.userId});

  @override
  State<BottomNavigationBarPage> createState() =>
      _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(userId: widget.userId),
      AddInventoryPage(
        userId: widget.userId,
      ),
      OrdersPage(
        userId: widget.userId,
      ),
      PaymentPage(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
         backgroundColor: Colors.green[50], // Lighter shade of green
          selectedItemColor: Colors.green[800], // Darker, vibrant green
          unselectedItemColor: Colors.green[400], // Lighter green or gray
          currentIndex: _selectedIndex,
          onTap: _navigateBottomBar,
          elevation: 12, 
          selectedFontSize: 14, 
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels:
              true,
          items: [
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_box_rounded), label: 'Add Item'),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.hammer), label: 'Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.payment_rounded), label: 'Payments'),
          ],
        ));
  }
}
