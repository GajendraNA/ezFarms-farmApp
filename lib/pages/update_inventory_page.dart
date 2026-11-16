import 'dart:convert';
import 'package:farmer/util/server_wakeup.dart';

import 'package:farmer/util/inventory_form.dart';
import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdateInventoryPage extends StatefulWidget {
  final int inventory_id;

  const UpdateInventoryPage({super.key, required this.inventory_id});

  @override
  State<UpdateInventoryPage> createState() => _UpdateInventoryPageState();
}

class _UpdateInventoryPageState extends State<UpdateInventoryPage> {
  Map<String, dynamic>? inventory;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    getInventory();
  }

  Future<void> getInventory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = Uri.parse('${apiUrl('inventory')}/${widget.inventory_id}');
      final response = await http.get(url).waitForServer();
      if (response.statusCode != 200) throw Exception('Status ${response.statusCode}');
      inventory = json.decode(response.body);
    } catch (error) {
      debugPrint('Error: $error');
      _error = kNetworkError;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save(InventoryFormData data) async {
    final error = await sendInventory(
      method: 'PUT',
      url: '${apiUrl('fInventory')}/${widget.inventory_id}',
      data: data,
      existingImageName: inventory?['name'],
    );
    if (!mounted) return false;
    if (error != null) {
      showAppSnackBar(context, error, isError: true);
      return false;
    }
    showAppSnackBar(context, 'Item updated');
    Navigator.pop(context, true); // tell the previous page to refresh
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final name = inventory?['name'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPDATE ITEM'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
      ),
      body: AsyncStateView(
        isLoading: _loading,
        error: _error,
        isEmpty: inventory == null,
        emptyMessage: 'Item not found',
        onRetry: getInventory,
        child: InventoryForm(
          initial: inventory,
          existingImageUrl: name == null ? null : getImageUrl(name),
          submitLabel: 'Save Changes',
          onSubmit: _save,
        ),
      ),
    );
  }
}
