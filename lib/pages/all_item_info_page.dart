import 'package:farmer/pages/item_info_page.dart';
import 'package:flutter/material.dart';

/// Item details opened from "All Inventories". It uses the same page as
/// your own items; Update/Delete only show for items you own.
class AllItemInfoPage extends StatelessWidget {
  final int inventory_id;

  const AllItemInfoPage({super.key, required this.inventory_id});

  @override
  Widget build(BuildContext context) => ItemInfoPage(inventory_id: inventory_id);
}
