import 'dart:convert';

import 'package:farmer/util/ipfile.dart';
import 'package:farmer/pages/update_inventory_page.dart';
import 'package:farmer/util/dialog_box.dart';
import 'package:farmer/util/my_button.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AllItemInfoPage extends StatefulWidget {
  final int inventory_id;

  AllItemInfoPage({
    Key? key,
    required this.inventory_id,
  }) : super(key: key);

  @override
  State<AllItemInfoPage> createState() => _AllItemInfoPageState();
}

class _AllItemInfoPageState extends State<AllItemInfoPage> {
  Map<String, dynamic>? inventory;

  Future<void> getInventory() async {
    try {
      final url = Uri.parse('${apiUrl('inventory')}/${widget.inventory_id}');

      // Perform the GET request
      final response = await http.get(url);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          inventory = {
            "inven_id": data['id'],
            "farmer_id": data['farmer_id'],
            "item_id": data['item_id'],
            'item_name': data['item_name'],
            'item_description': data['item_description'],
            'farmer_name': data['farmer_name'],
            'name': data['name'],
            'final_rate_per_kg': data['final_rate_per_kg'],
            'remaining_weight': data['remaining_weight'],
            'weight': data['weight'],
            'category': data['item_category'],
          };
        });
      } else {
        throw Exception('Failed to load item');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    getInventory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ITEM INFO'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: inventory != null && inventory?['name'] != null
                            ? Image.network(
                                getImageUrl(inventory!['name']),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              )
                            : Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors
                                    .white, // or use a placeholder image
                                child: Center(
                                  child: Text(
                                    'Loading the image',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.label, color: Colors.amber),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              inventory?['item_name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(Icons.label, color: Colors.amber),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '₹ ${inventory?['final_rate_per_kg']}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Icon(Icons.description, color: Colors.amber),
                          SizedBox(width: 10),
                          Text(
                            inventory?['category'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.description, color: Colors.amber),
                          SizedBox(width: 10),
                          Text(
                            inventory?['item_description'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Total Uploaded: ${inventory?['weight']}kg',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'In inventory Left: ${inventory?['remaining_weight']}kg',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
