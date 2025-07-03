import 'dart:convert';
import 'package:farmer/util/ipfile.dart'; // Ensure this file exists and getAllFarmersUrl is defined
import 'package:farmer/pages/addInventoy_page.dart';
import 'package:farmer/pages/all_item_info_page.dart';
import 'package:farmer/util/model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer/pages/login_page.dart';

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
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getAllInventories();
  }

  Future<void> getAllInventories() async {
    try {
      final response = await http.get(Uri.parse(getAllInventory));

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
      setState(() {
        isLoading = false;
      });
      // You can also show a SnackBar or other UI indication here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'INVENTORIES',
          ),
          backgroundColor: Colors.green,
          shadowColor: Colors.black,
          elevation: 10,
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                    context: context,
                    delegate: InventorySearch(filteredInventories));
              },
            ),
          ]),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: PaginatedDataTable(
                    columns: [
                      DataColumn(
                        label: Text('Item Name',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, ascending) =>
                            onSortColumn(columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Inventory Name',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, ascending) =>
                            onSortColumn(columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Weight',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, ascending) =>
                            onSortColumn(columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Remaining Weight',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, ascending) =>
                            onSortColumn(columnIndex, ascending),
                      ),
                      DataColumn(
                        label: Text('Final Rate per Kg',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, ascending) =>
                            onSortColumn(columnIndex, ascending),
                      ),
                    ],
                    source: InventoryDataSource(filteredInventories),
                    rowsPerPage: 10,
                  ),
                ),
              ),
            ),
    );
  }

  void onSortColumn(int columnIndex, bool ascending) {
    setState(() {
      switch (columnIndex) {
        case 0:
          filteredInventories.sort(
              (a, b) => compareString(ascending, a['itemName'], b['itemName']));
          break;
        case 1:
          filteredInventories
              .sort((a, b) => compareString(ascending, a['name'], b['name']));
          break;
        case 2:
          filteredInventories.sort(
              (a, b) => compareDouble(ascending, a['weight'], b['weight']));
          break;
        case 3:
          filteredInventories.sort((a, b) => compareDouble(
              ascending, a['remainingWeight'], b['remainingWeight']));
          break;
        case 4:
          filteredInventories.sort((a, b) => compareDouble(
              ascending, a['finalRatePerKg'], b['finalRatePerKg']));
          break;
      }
    });
  }

  int compareString(bool ascending, String? a, String? b) {
    return ascending ? a!.compareTo(b!) : b!.compareTo(a!);
  }

  int compareDouble(bool ascending, double? a, double? b) {
    return ascending ? a!.compareTo(b!) : b!.compareTo(a!);
  }
}

class InventoryDataSource extends DataTableSource {
  final List<Map<String, dynamic>> inventories;

  InventoryDataSource(this.inventories);

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);
    if (index >= inventories.length) return null;
    final inventory = inventories[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(inventory['itemName'] ?? 'N/A')),
        DataCell(Text(inventory['name'] ?? 'N/A')),
        DataCell(Text(inventory['weight']?.toString() ?? 'N/A')),
        DataCell(Text(inventory['remainingWeight']?.toString() ?? 'N/A')),
        DataCell(Text(inventory['finalRatePerKg']?.toString() ?? 'N/A')),
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
