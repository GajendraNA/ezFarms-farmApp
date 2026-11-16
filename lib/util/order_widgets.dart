import 'dart:convert';
import 'package:farmer/util/server_wakeup.dart';

import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Shows only the date part of "2024-05-12T10:30:00" style values.
String formatDate(dynamic value) {
  if (value == null || value.toString().isEmpty) return 'N/A';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

DateTime _dateOf(dynamic v) =>
    DateTime.tryParse(v?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

/// Lays cards out in 1–3 columns depending on the available width.
class ResponsiveCardList extends StatelessWidget {
  final List<Widget> children;
  final double minCardWidth;

  const ResponsiveCardList({super.key, required this.children, this.minCardWidth = 380});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 12.0;
      final columns = columnsForWidth(constraints.maxWidth, minItemWidth: minCardWidth).clamp(1, 3);
      final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: cardWidth, child: c)],
      );
    });
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fetches a JSON list from [url] and shows it with loading / error / empty
/// states and pull-to-refresh. Used by the orders and payments pages.
class _RemoteList extends StatefulWidget {
  final String url;
  final String emptyMessage;
  final IconData emptyIcon;
  final DateTime Function(Map<String, dynamic>) dateOf;
  final Widget Function(List<Map<String, dynamic>> all) summaryBuilder;
  final String? Function(Map<String, dynamic>)? filterKeyOf;
  final Widget Function(Map<String, dynamic>) cardBuilder;

  const _RemoteList({
    required this.url,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.dateOf,
    required this.summaryBuilder,
    required this.cardBuilder,
    this.filterKeyOf,
  });

  @override
  State<_RemoteList> createState() => _RemoteListState();
}

class _RemoteListState extends State<_RemoteList> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String? _filter; // null = show all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final response =
          await http.get(Uri.parse(widget.url)).waitForServer();
      // Some endpoints answer 204 (no content) when the list is empty.
      final List<dynamic> data = response.statusCode == 204 || response.body.trim().isEmpty
          ? []
          : response.statusCode == 200
              ? json.decode(response.body) as List<dynamic>
              : throw Exception('Status ${response.statusCode}');

      final items = data.cast<Map<String, dynamic>>().toList()
        ..sort((a, b) => widget.dateOf(b).compareTo(widget.dateOf(a))); // newest first

      if (!mounted) return;
      setState(() {
        _items = items; // replace (not append) so refresh doesn't duplicate
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading ${widget.url}: $e');
      if (!mounted) return;
      setState(() {
        _error = kNetworkError;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyOf = widget.filterKeyOf;
    final filterOptions = keyOf == null
        ? <String>[]
        : (_items.map(keyOf).whereType<String>().where((s) => s.isNotEmpty).toSet().toList()
          ..sort());
    final visible = (_filter == null || keyOf == null)
        ? _items
        : _items.where((i) => keyOf(i) == _filter).toList();

    return AsyncStateView(
      isLoading: _loading,
      error: _error,
      isEmpty: _items.isEmpty,
      emptyMessage: widget.emptyMessage,
      emptyIcon: widget.emptyIcon,
      onRetry: _load,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          children: [
            ResponsiveCenter(
              maxWidth: 1200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.summaryBuilder(_items),
                  if (filterOptions.length > 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          for (final option in [null, ...filterOptions])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(option == null
                                    ? 'All (${_items.length})'
                                    : '$option (${_items.where((i) => keyOf!(i) == option).length})'),
                                selected: _filter == option,
                                selectedColor: Colors.green[200],
                                onSelected: (_) => setState(() => _filter = option),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  ResponsiveCardList(
                    children: [for (final item in visible) widget.cardBuilder(item)],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Orders

class OrdersListView extends StatelessWidget {
  final String url;
  final bool showFarmer;

  const OrdersListView({super.key, required this.url, this.showFarmer = false});

  bool _isPending(Map<String, dynamic> o) {
    final s = (o['status'] ?? '').toString().toLowerCase();
    return !(s.contains('deliver') || s.contains('complete') || s.contains('cancel'));
  }

  @override
  Widget build(BuildContext context) {
    return _RemoteList(
      url: url,
      emptyMessage: 'No orders yet',
      emptyIcon: Icons.shopping_bag_outlined,
      dateOf: (o) => _dateOf(o['ordered_date']),
      filterKeyOf: (o) => o['status']?.toString(),
      summaryBuilder: (orders) {
        final revenue = orders.fold<double>(0, (s, o) => s + toDouble(o['order_amount']));
        final kg = orders.fold<double>(0, (s, o) => s + toDouble(o['weight']));
        return Row(children: [
          _SummaryTile('Orders', '${orders.length}', Icons.receipt_long, Colors.green),
          _SummaryTile('Pending', '${orders.where(_isPending).length}',
              Icons.hourglass_top, Colors.orange),
          _SummaryTile('Sold', '${formatNum(kg)} kg', Icons.scale, Colors.blue),
          _SummaryTile('Revenue', '₹${formatNum(revenue.round())}',
              Icons.currency_rupee, Colors.purple),
        ]);
      },
      cardBuilder: (o) => _OrderCard(order: o, showFarmer: showFarmer),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool showFarmer;

  const _OrderCard({required this.order, required this.showFarmer});

  @override
  Widget build(BuildContext context) {
    final picture = order['picture'];
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkImageBox(url: picture == null ? null : getImageUrl(picture), height: 150),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order['item_name'] ?? 'N/A',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    StatusChip(status: order['status']?.toString()),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${formatNum(order['order_amount'])}',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
                Text(
                  '${formatNum(order['weight'])} kg × ₹${formatNum(order['item_rate'])}/kg',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const Divider(height: 20),
                InfoRow(icon: Icons.person, label: 'Customer', value: order['buyer_name'] ?? 'N/A'),
                if (showFarmer)
                  InfoRow(icon: Icons.agriculture, label: 'Farmer', value: order['farmer_name'] ?? 'N/A'),
                InfoRow(icon: Icons.calendar_today, label: 'Ordered', value: formatDate(order['ordered_date'])),
                InfoRow(icon: Icons.local_shipping, label: 'Delivery', value: formatDate(order['est_delivery_date'])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Payments

class PaymentsListView extends StatelessWidget {
  final String url;
  final bool showFarmer;

  const PaymentsListView({super.key, required this.url, this.showFarmer = false});

  @override
  Widget build(BuildContext context) {
    return _RemoteList(
      url: url,
      emptyMessage: 'No payments yet',
      emptyIcon: Icons.account_balance_wallet_outlined,
      dateOf: (p) => _dateOf(p['payment_date']),
      filterKeyOf: (p) => p['method']?.toString(),
      summaryBuilder: (payments) {
        final received = payments.fold<double>(0, (s, p) => s + toDouble(p['payment_amount']));
        final due = payments.fold<double>(
            0, (s, p) => s + (toDouble(p['final_amount']) - toDouble(p['payment_amount'])).clamp(0, double.infinity));
        return Row(children: [
          _SummaryTile('Payments', '${payments.length}', Icons.receipt, Colors.green),
          _SummaryTile('Received', '₹${formatNum(received.round())}',
              Icons.account_balance_wallet, Colors.blue),
          _SummaryTile('Balance due', '₹${formatNum(due.round())}', Icons.pending_actions,
              due > 0 ? Colors.orange : Colors.grey),
        ]);
      },
      cardBuilder: (p) => _PaymentCard(payment: p, showFarmer: showFarmer),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final bool showFarmer;

  const _PaymentCard({required this.payment, required this.showFarmer});

  @override
  Widget build(BuildContext context) {
    final finalAmount = toDouble(payment['final_amount']);
    final paid = toDouble(payment['payment_amount']);
    final due = finalAmount - paid;
    final orderAmount = toDouble(payment['order_amount']);
    final discount = orderAmount - finalAmount;

    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    payment['buyerName'] ?? 'N/A',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusChip(status: due > 0.01 ? 'Partly paid' : 'Paid'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '₹${formatNum(paid)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            const Divider(height: 20),
            if (showFarmer)
              InfoRow(icon: Icons.agriculture, label: 'Farmer', value: payment['farmerName'] ?? 'N/A'),
            InfoRow(icon: Icons.calendar_today, label: 'Date', value: formatDate(payment['payment_date'])),
            InfoRow(icon: Icons.payment, label: 'Method', value: payment['method'] ?? 'N/A'),
            InfoRow(icon: Icons.shopping_cart, label: 'Order amount', value: '₹${formatNum(orderAmount)}'),
            if (discount > 0.01)
              InfoRow(icon: Icons.local_offer, label: 'Discount', value: '₹${formatNum(discount)}'),
            InfoRow(icon: Icons.money, label: 'Final amount', value: '₹${formatNum(finalAmount)}'),
            if (due > 0.01)
              InfoRow(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange,
                labelColor: Colors.orange[800],
                label: 'Balance due',
                value: '₹${formatNum(due)}',
              ),
          ],
        ),
      ),
    );
  }
}
