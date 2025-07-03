import 'package:farmer/util/ipfile.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class UpdateInventoryPage extends StatefulWidget {
  final int inventory_id;

  const UpdateInventoryPage({super.key, required this.inventory_id});

  @override
  State<UpdateInventoryPage> createState() => _UpdateInventoryPageState();
}

class _UpdateInventoryPageState extends State<UpdateInventoryPage> {
  Map<String, dynamic>? inventory;

  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _remainingWeightController = TextEditingController();
  final _finalRatePerKgController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;



  @override
  void initState() {
    super.initState();
    getInventory();
  }

  Future<void> getInventory() async {
    try {
      final url = Uri.parse('${apiUrl('inventory')}/${widget.inventory_id}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          inventory = data;
          setValues(); // Set values after inventory is fetched
        });
      } else {
        throw Exception('Failed to load item');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void setValues() {
    if (inventory != null) {
      _weightController.text = inventory!['weight'].toString();
      _remainingWeightController.text =
          inventory!['remaining_weight'].toString();
      _finalRatePerKgController.text =
          inventory!['final_rate_per_kg'].toString();
      _itemNameController.text = inventory!['item_name'];
      _categoryController.text = inventory!['item_category'];
      _descriptionController.text = inventory!['item_description'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    var pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
      }
    });
  }

  Future<void> _updateInv() async {
    var url = Uri.parse('${apiUrl('fInventory')}/${widget.inventory_id}');
    var request = http.MultipartRequest('PUT', url);

    try {
      Map<String, dynamic> requestData = {
        "itemName": _itemNameController.text,
        "weight": _weightController.text,
        "remaining_weight": _remainingWeightController.text,
        "final_rate_per_kg": _finalRatePerKgController.text,
        "description": _descriptionController.text,
        "category": _categoryController.text,
      };

      request.fields["data"] = jsonEncode(requestData);
      if (_selectedImage != null && _selectedImage!.path.isNotEmpty) {
        request.files.add(http.MultipartFile(
          'file',
          _selectedImage!.readAsBytes().asStream(),
          _selectedImage!.lengthSync(),
          filename: p.basename(_selectedImage!.path),
        ));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        _showSnackBar(context, 'Inventory Updated Successfully');
      } else {
        _showSnackBar(context, 'Failed to Update Inventory');
      }
    } catch (err) {
      _showSnackBar(context, 'Error: $err');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UPDATING...'),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item Name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Item Category'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the category';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _finalRatePerKgController,
                decoration: InputDecoration(labelText: 'Final Rate per KG'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the final rate per KG';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the weight';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _remainingWeightController,
                decoration: InputDecoration(labelText: 'Remaining Weight'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the remaining weight';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Item Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Write some description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _selectedImage == null
                  ? ClipRRect(
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
                                color:
                                    Colors.white, // or use a placeholder image
                                child: Center(
                                  child: Text(
                                    'Loading the image',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                      )
                  : Image.file(_selectedImage!),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _updateInv().then((_) {
                      Navigator.pop(context,
                          true); // Pass true to indicate update success
                    });
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}