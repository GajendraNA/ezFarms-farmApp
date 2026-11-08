import 'dart:convert';
import 'package:farmer/util/ipfile.dart'; // Ensure this file exists and getAllFarmersUrl is defined
import 'package:farmer/util/ui_helpers.dart';
import 'package:farmer/pages/all_item_info_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AllInventoriesPage extends StatefulWidget {
  const AllInventoriesPage({
    super.key,
  });

  @override
  State<AllInventoriesPage> createState() => _AllInventoriesPageState();
}

class _AllInventoriesPageState extends State<AllInventoriesPage> {
  List<Map<String, dynamic>> inventories = [];
  List<Map<String, dynamic>> filteredInventories = [];
  bool isLoading = true;
  String? _error;
  int? _sortColumn;
  bool _sortAscending = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getAllInventories();
  }

  Future<void> getAllInventories() async {
    setState(() {
      isLoading = inventories.isEmpty;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(getAllInventory))
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        dynamic data = json.decode(response.body);

        List<dynamic> dataList = data as List<dynamic>;

        List<Map<String, dynamic>> inventoryList = [];

        for (var element in dataList) {
          Map<String, dynamic> resultMap = {
            'inven_id': element['id'], // Ensure this field is present
            'name': element['name'],
            'itemName': element['item_name'],
            'farmerName': element['farmer_name'],
            'weight': element['weight'],
            'remainingWeight': element['remaining_weight'],
            'finalRatePerKg': element['final_rate_per_kg'],
            'itemDescription': element['item_description'],
            'itemCategory': element['item_category'],
          };
          inventoryList.add(resultMap);
        }

        setState(() {
          inventories = inventoryList;
          filteredInventories =
              inventories; // Initialize filtered list with all inventories
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load inventories');
      }
    } catch (error) {
      print('Error: $error');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _error = kNetworkError;
      });
    }
  }


  void _openItem(Map<String, dynamic> inventory) {
    if (inventory['inven_id'] == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllItemInfoPage(inventory_id: inventory['inven_id']),
      ),
    ).then((changed) {
      if (changed == true) getAllInventories();
    });
  }

  DataColumn _column(String label, {bool numeric = false}) {
    return DataColumn(
      numeric: numeric,
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onSort: onSortColumn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Show more rows on tall/wide screens.
    final rowsPerPage = width >= kWideLayoutBreakpoint ? 15 : 10;

    return Scaffold(
      appBar: AppBar(
          title: const Text('ALL INVENTORIES'),
          backgroundColor: Colors.green,
          shadowColor: Colors.black,
          elevation: 10,
          actions: [
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                    context: context,
                    delegate: InventorySearch(inventories));
              },
            ),
          ]),
      body: AsyncStateView(
        isLoading: isLoading,
        error: _error,
        isEmpty: inventories.isEmpty,
        emptyMessage: 'No inventories yet',
        onRetry: getAllInventories,
        child: RefreshIndicator(
          onRefresh: getAllInventories,
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              ResponsiveCenter(
                maxWidth: 1100,
                // The table scrolls sideways on its own on narrow phones.
                child: PaginatedDataTable(
                  header: Text('${inventories.length} items  •  tap a row for details',
                      style: const TextStyle(fontSize: 14)),
                  sortColumnIndex: _sortColumn,
                  sortAscending: _sortAscending,
                  showCheckboxColumn: false,
                  columnSpacing: 24,
                  columns: [
                    _column('Item'),
                    _column('Farmer'),
                    _column('Weight (kg)', numeric: true),
                    _column('Left (kg)', numeric: true),
                    _column('Rate (₹/kg)', numeric: true),
                  ],
                  source: InventoryDataSource(filteredInventories, _openItem),
                  rowsPerPage: rowsPerPage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onSortColumn(int columnIndex, bool ascending) {
    const keys = ['itemName', 'farmerName', 'weight', 'remainingWeight', 'finalRatePerKg'];
    final key = keys[columnIndex];
    final numeric = columnIndex >= 2;

    setState(() {
      _sortColumn = columnIndex;
      _sortAscending = ascending;
      filteredInventories.sort((a, b) {
        final result = numeric
            ? toDouble(a[key]).compareTo(toDouble(b[key]))
            : (a[key] ?? '').toString().toLowerCase().compareTo(
                (b[key] ?? '').toString().toLowerCase());
        return ascending ? result : -result;
      });
    });
  }
}

class InventoryDataSource extends DataTableSource {
  final List<Map<String, dynamic>> inventories;
  final void Function(Map<String, dynamic>) onTap;

  InventoryDataSource(this.inventories, this.onTap);

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);
    if (index >= inventories.length) return null;
    final inventory = inventories[index];
    final left = toDouble(inventory['remainingWeight']);
    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) => onTap(inventory),
      cells: [
        DataCell(Text(inventory['itemName'] ?? 'N/A')),
        DataCell(Text(inventory['farmerName'] ?? 'N/A')),
        DataCell(Text(formatNum(inventory['weight']))),
        DataCell(Text(
          formatNum(left),
          style: TextStyle(
            color: left <= 0 ? Colors.red : null,
            fontWeight: left <= 0 ? FontWeight.bold : null,
          ),
        )),
        DataCell(Text(formatNum(inventory['finalRatePerKg']))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => inventories.length;

  @override
  int get selectedRowCount => 0;
}

class InventorySearch extends SearchDelegate<String> {
  final List<Map<String, dynamic>> inventories;

  InventorySearch(this.inventories);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Map<String, dynamic>> results = inventories.where((inventory) {
      return (inventory['name']?.toLowerCase() ?? '')
              .contains(query.toLowerCase()) ||
          (inventory['itemName']?.toLowerCase() ?? '')
              .contains(query.toLowerCase()) ||
          (inventory['farmerName']?.toLowerCase() ?? '')
              .contains(query.toLowerCase()) ||
          (inventory['itemDescription']?.toLowerCase() ?? '')
              .contains(query.toLowerCase()) ||
          (inventory['itemCategory']?.toLowerCase() ?? '')
              .contains(query.toLowerCase());
    }).toList();

    return InventoryList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Map<String, dynamic>> suggestions = inventories.where((inventory) {
      return (inventory['itemName']?.toLowerCase() ?? '')
              .contains(query.toLowerCase()) ||
          (inventory['name']?.toLowerCase() ?? '')
              .contains(query.toLowerCase()) ||
          (inventory['farmerName']?.toLowerCase() ?? '')
              .contains(query.toLowerCase()) ||
          (inventory['itemDescription']?.toLowerCase() ?? '')
              .contains(query.toLowerCase()) ||
          (inventory['itemCategory']?.toLowerCase() ?? '')
              .contains(query.toLowerCase());
    }).toList();

    return InventoryList(suggestions);
  }
}

class InventoryList extends StatelessWidget {
  final List<Map<String, dynamic>> inventories;

  InventoryList(this.inventories);

  void _itemInfo(BuildContext context, Map<String, dynamic> inventory) async {
    if (inventory['inven_id'] != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AllItemInfoPage(
                  inventory_id: inventory['inven_id'],
                )),
      );
    } else {
      // Handle the null case here, for example, show a dialog or a message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Invalid inventory data.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: inventories.length,
      itemBuilder: (context, index) {
        final inventory = inventories[index];
        return ListTile(
          title: Text(inventory['itemName'] ?? 'N/A'),
          subtitle: Text(inventory['farmerName'] ?? 'N/A'),
          onTap: () {
            _itemInfo(context,inventory);
          },
        );
      },
    );
  }
}
