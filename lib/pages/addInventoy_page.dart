import 'package:farmer/util/inventory_form.dart';
import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/ui_helpers.dart';
import 'package:flutter/material.dart';

class AddInventoryPage extends StatelessWidget {
  final int userId;

  /// Called after the item is saved (used to switch back to the Home tab).
  final VoidCallback? onSaved;

  const AddInventoryPage({super.key, required this.userId, this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD ITEM'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
      ),
      body: InventoryForm(
        submitLabel: 'Add to Inventory',
        imageRequired: true, // the backend needs a photo
        onSubmit: (data) async {
          final error = await sendInventory(
            method: 'POST',
            url: postInventory,
            data: data,
            farmerId: userId,
          );
          if (!context.mounted) return false;
          if (error != null) {
            showAppSnackBar(context, error, isError: true);
            return false;
          }
          showAppSnackBar(context, '${data.itemName} added to your inventory');
          onSaved?.call();
          return true;
        },
      ),
    );
  }
}
