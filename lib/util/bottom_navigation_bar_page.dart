import 'package:farmer/pages/addInventoy_page.dart';
import 'package:farmer/pages/home_page.dart';
import 'package:farmer/pages/orders_page.dart';
import 'package:farmer/pages/payment_page.dart';
import 'package:farmer/util/ui_helpers.dart';
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

  static const _labels = ['Home', 'Add Item', 'Orders', 'Payments'];
  static final _icons = <Widget>[
    const FaIcon(FontAwesomeIcons.house, size: 20),
    const Icon(Icons.add_box_rounded),
    const FaIcon(FontAwesomeIcons.boxOpen, size: 20),
    const Icon(Icons.payment_rounded),
  ];

  void _select(int index) => setState(() => _selectedIndex = index);

  // Pages are rebuilt when you switch tabs, so each tab shows fresh data.
  Widget _page() {
    switch (_selectedIndex) {
      case 1:
        return AddInventoryPage(
          userId: widget.userId,
          onSaved: () => _select(0), // go back to Home to see the new item
        );
      case 2:
        return OrdersPage(userId: widget.userId);
      case 3:
        return PaymentPage(userId: widget.userId);
      default:
        return HomePage(userId: widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tablets, desktop and web: navigation rail on the side.
    if (isWideScreen(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.green[50],
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: Colors.green[800]),
              unselectedIconTheme: IconThemeData(color: Colors.green[400]),
              selectedLabelTextStyle: TextStyle(
                  color: Colors.green[800], fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: TextStyle(color: Colors.green[400]),
              destinations: [
                for (var i = 0; i < _labels.length; i++)
                  NavigationRailDestination(
                    icon: _icons[i],
                    label: Text(_labels[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _page()),
          ],
        ),
      );
    }

    // Phones: bottom navigation bar.
    return Scaffold(
      body: _page(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green[50],
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.green[400],
        currentIndex: _selectedIndex,
        onTap: _select,
        elevation: 12,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: [
          for (var i = 0; i < _labels.length; i++)
            BottomNavigationBarItem(icon: _icons[i], label: _labels[i]),
        ],
      ),
    );
  }
}
