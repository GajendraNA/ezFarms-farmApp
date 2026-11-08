import 'package:farmer/pages/farmer_list_page.dart';
import 'package:farmer/util/ipfile.dart';
import 'package:flutter/material.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) => PeopleListPage(
        title: 'CUSTOMERS',
        url: getAllCustomersUrl,
        icon: Icons.person,
      );
}
