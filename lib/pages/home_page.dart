import 'dart:convert';
import 'package:farmer/pages/all_payment_page.dart';
import 'package:farmer/util/dialog_box.dart';
import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/ui_helpers.dart';
import 'package:farmer/pages/all_inventories_page.dart';
import 'package:farmer/pages/all_orders_page.dart';
import 'package:farmer/pages/customer_list_page.dart';
import 'package:farmer/pages/farmer_list_page.dart';
import 'package:farmer/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'item_info_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({
    super.key,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> inventories = [];
  Map<String, dynamic>? userInfo;
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    getAllInventory();
    getUserInfo();
  }

  Future<void> getAllInventory() async {
    if (inventories.isEmpty) setState(() => _loading = true);
    try {
      final url = Uri.parse('${apiUrl('fInventory')}/${widget.userId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Status ${response.statusCode}');
      }

      final dataList = json.decode(response.body) as List<dynamic>;
      final inventoryList = dataList.map<Map<String, dynamic>>((element) => {
            'inven_id': element['id'],
            'item_name': element['item_name'],
            'item_category': element['item_category'],
            'name': element['name'],
            'final_rate_per_kg': element['final_rate_per_kg'],
            'remaining_weight': element['remaining_weight'],
            'weight': element['weight'],
          }).toList();

      // Newest items first.
      inventoryList.sort((a, b) =>
          ((b['inven_id'] ?? 0) as num).compareTo((a['inven_id'] ?? 0) as num));

      if (!mounted) return;
      setState(() {
        inventories = inventoryList;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Error: $error');
      if (!mounted) return;
      setState(() {
        _error = kNetworkError;
        _loading = false;
      });
    }
  }

  Future<void> getUserInfo() async {
    try {
      final url = Uri.parse('${apiUrl('farmer')}/${widget.userId}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() => userInfo = data);
      }
    } catch (error) {
      debugPrint('Error: $error');
    }
  }

  Future<void> _refresh() => Future.wait([getAllInventory(), getUserInfo()]);

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedUserID');
    if (!mounted) return;
    // Clear every screen so the back button can't return to the app.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogBox(
        text: "Are you sure you want to log out?",
        onSave: _logout,
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _itemInfo(Map<String, dynamic> inventory) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemInfoPage(inventory_id: inventory['inven_id']),
      ),
    );
    if (result == true) getAllInventory();
  }

  List<Map<String, dynamic>> get _visibleItems {
    if (_search.isEmpty) return inventories;
    final q = _search.toLowerCase();
    return inventories.where((i) {
      return '${i['item_name']} ${i['item_category']}'.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userInfo?['name'] != null
            ? 'Hi, ${userInfo!['name'].toString().split(' ').first}'
            : 'HOME'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
        actions: [
          IconButton(
            tooltip: 'All inventories',
            icon: const Icon(Icons.inventory),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AllInventoriesPage())),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: AsyncStateView(
        isLoading: _loading,
        error: _error,
        isEmpty: inventories.isEmpty,
        emptyIcon: Icons.agriculture_outlined,
        emptyMessage:
            'You have no items yet.\nTap "Add Item" below to add your first one.',
        onRetry: _refresh,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildSummary()),
              SliverToBoxAdapter(child: _buildSearchBox()),
              _buildGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final totalStock =
        inventories.fold<double>(0, (sum, i) => sum + toDouble(i['remaining_weight']));
    final stockValue = inventories.fold<double>(
        0,
        (sum, i) =>
            sum + toDouble(i['remaining_weight']) * toDouble(i['final_rate_per_kg']));
    final lowStock = inventories.where(_isLowStock).length;

    Widget tile(String label, String value, IconData icon, Color color) {
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          tile('Items', '${inventories.length}', Icons.eco, Colors.green),
          tile('In stock', '${formatNum(totalStock)} kg', Icons.scale, Colors.blue),
          tile('Stock value', '₹${formatNum(stockValue.round())}',
              Icons.currency_rupee, Colors.purple),
          tile('Low stock', '$lowStock', Icons.warning_amber_rounded,
              lowStock > 0 ? Colors.orange : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        onChanged: (v) => setState(() => _search = v.trim()),
        decoration: InputDecoration(
          hintText: 'Search your items',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  bool _isLowStock(Map<String, dynamic> i) {
    final total = toDouble(i['weight']);
    final left = toDouble(i['remaining_weight']);
    return total > 0 && left / total < 0.2;
  }

  Widget _buildGrid() {
    final items = _visibleItems;
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No items match your search')),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        // Card count per row grows with the screen width.
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildItemCard(items[index]),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> inventory) {
    final left = toDouble(inventory['remaining_weight']);
    final soldOut = left <= 0;
    final low = !soldOut && _isLowStock(inventory);
    final imageName = inventory['name'];

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _itemInfo(inventory),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkImageBox(
                      url: imageName == null ? null : getImageUrl(imageName)),
                  if (soldOut || low)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: soldOut ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          soldOut ? 'Sold out' : 'Low stock',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inventory['item_name'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${formatNum(inventory['final_rate_per_kg'])}/kg',
                    style: TextStyle(
                        color: Colors.green[800], fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${formatNum(left)} kg left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.green[50],
      width: 280,
      // A ListView so the drawer scrolls on short screens instead of overflowing.
      child: Builder(builder: (drawerContext) {
        void open(Widget page) {
          Navigator.pop(drawerContext); // close drawer
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildProfileHeader(),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text("All Inventories"),
              onTap: () => open(const AllInventoriesPage()),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_rounded),
              title: const Text("All Orders"),
              onTap: () => open(const AllOrdersPage()),
            ),
            ListTile(
              leading: const Icon(Icons.agriculture),
              title: const Text("Farmers"),
              onTap: () => open(const FarmerListPage()),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Customers"),
              onTap: () => open(const CustomerListPage()),
            ),
            ListTile(
              leading: const Icon(Icons.payment_outlined),
              title: const Text("All Payments"),
              onTap: () => open(const AllPaymentPage()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              textColor: Colors.red,
              iconColor: Colors.redAccent,
              title: const Text("Log Out",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(drawerContext);
                _confirmLogout();
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProfileHeader() {
    if (userInfo == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      color: Colors.green[200],
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.paddingOf(context).top + 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundImage: AssetImage('assets/images/ajinBro.jpg'),
          ),
          const SizedBox(height: 12),
          Text(
            userInfo!['name'] ?? 'N/A',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          InfoRow(icon: Icons.phone, label: 'Phone', value: userInfo!['phone'] ?? 'N/A'),
          InfoRow(icon: Icons.email, label: 'Email', value: userInfo!['email'] ?? 'N/A'),
          if ((userInfo!['address'] ?? '').toString().isNotEmpty)
            InfoRow(
                icon: Icons.location_on,
                label: 'Address',
                value: userInfo!['address']),
        ],
      ),
    );
  }
}
