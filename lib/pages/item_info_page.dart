import 'dart:convert';

import 'package:farmer/util/ipfile.dart';
import 'package:farmer/pages/update_inventory_page.dart';
import 'package:farmer/util/dialog_box.dart';
import 'package:farmer/util/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Shows one inventory item. Update and Delete appear only when the item
/// belongs to the logged-in farmer.
class ItemInfoPage extends StatefulWidget {
  final int inventory_id;

  const ItemInfoPage({super.key, required this.inventory_id});

  @override
  State<ItemInfoPage> createState() => _ItemInfoPageState();
}

class _ItemInfoPageState extends State<ItemInfoPage> {
  Map<String, dynamic>? inventory;
  int? _loggedUserId;
  bool _loading = true;
  bool _deleting = false;
  bool _changed = false; // tells the previous page to refresh
  String? _error;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _loggedUserId = prefs.getInt('loggedUserID'));
    });
    getInventory();
  }

  bool get _isMine =>
      inventory != null &&
      _loggedUserId != null &&
      inventory!['farmer_id'] == _loggedUserId;

  Future<void> getInventory() async {
    setState(() {
      _loading = inventory == null;
      _error = null;
    });
    try {
      final url = Uri.parse('${apiUrl('inventory')}/${widget.inventory_id}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw Exception('Status ${response.statusCode}');
      inventory = json.decode(response.body) as Map<String, dynamic>;
    } catch (error) {
      debugPrint('Error: $error');
      _error = kNetworkError;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openUpdatePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => UpdateInventoryPage(inventory_id: widget.inventory_id)),
    );
    if (result == true) {
      _changed = true;
      getInventory();
    }
  }

  Future<void> _delete() async {
    Navigator.of(context).pop(); // close the confirm dialog
    setState(() => _deleting = true);
    try {
      final url = Uri.parse('${apiUrl('inventory')}/${widget.inventory_id}');
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        showAppSnackBar(context, '${inventory?['item_name'] ?? 'Item'} deleted');
        Navigator.of(context).pop(true);
        return;
      }
      // Usually fails when the item already has orders linked to it.
      showAppSnackBar(
          context, 'Could not delete. This item may have orders linked to it.',
          isError: true);
    } catch (error) {
      debugPrint('Error: $error');
      if (mounted) showAppSnackBar(context, kNetworkError, isError: true);
    }
    if (mounted) setState(() => _deleting = false);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogBox(
        text: "Delete ${inventory?['item_name'] ?? 'this item'}? This can't be undone.",
        onSave: _delete,
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(inventory?['item_name']?.toString().toUpperCase() ?? 'ITEM INFO'),
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
          child: RefreshIndicator(
            onRefresh: getInventory,
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= kWideLayoutBreakpoint;
              final image = NetworkImageBox(
                url: inventory?['name'] == null ? null : getImageUrl(inventory!['name']),
                height: wide ? 340 : 240,
                borderRadius: BorderRadius.circular(15),
              );
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ResponsiveCenter(
                    maxWidth: 950,
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: image),
                              const SizedBox(width: 20),
                              Expanded(child: _details()),
                            ],
                          )
                        : Column(
                            children: [image, const SizedBox(height: 16), _details()],
                          ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _details() {
    final inv = inventory!;
    final total = toDouble(inv['weight']);
    final left = toDouble(inv['remaining_weight']);
    final sold = (total - left).clamp(0, double.infinity);
    final ratio = total > 0 ? (left / total).clamp(0.0, 1.0) : 0.0;
    final rate = toDouble(inv['final_rate_per_kg']);
    final barColor = ratio <= 0
        ? Colors.red
        : ratio < 0.2
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    inv['item_name'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '₹${formatNum(rate)}/kg',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if ((inv['item_category'] ?? '').toString().isNotEmpty)
              Chip(
                label: Text(inv['item_category']),
                avatar: const Icon(Icons.category, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(height: 8),
            InfoRow(
                icon: Icons.notes,
                label: 'Description',
                value: inv['item_description'] ?? 'N/A'),
            if (!_isMine)
              InfoRow(
                  icon: Icons.agriculture,
                  label: 'Farmer',
                  value: inv['farmer_name'] ?? 'N/A'),
            const Divider(height: 24),
            Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                color: barColor,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('Left: ${formatNum(left)} kg',
                    style: TextStyle(color: barColor, fontWeight: FontWeight.bold)),
                Text('Sold: ${formatNum(sold)} kg'),
                Text('Total: ${formatNum(total)} kg'),
              ],
            ),
            const SizedBox(height: 8),
            InfoRow(
                icon: Icons.currency_rupee,
                label: 'Value of stock left',
                value: '₹${formatNum((left * rate).round())}'),
            if (_isMine) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleting ? null : _openUpdatePage,
                      icon: const Icon(Icons.edit),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleting ? null : _confirmDelete,
                      icon: _deleting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
