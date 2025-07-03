import 'dart:convert';
import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/bottom_navigation_bar_page.dart';
import 'package:farmer/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class AddInventoryPage extends StatefulWidget {
  final int userId;

  const AddInventoryPage({super.key, required this.userId});

  @override
  _AddInventoryPageState createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _remainingWeightController = TextEditingController();
  final _finalRatePerKgController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _categoryController = TextEditingController();

  final _descriptionController = TextEditingController();

  File? _selectedImage;

  @override
  void dispose() {
    _weightController.dispose();
    _remainingWeightController.dispose();
    _finalRatePerKgController.dispose();
    _itemNameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();

    super.dispose();
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

  Future<void> _createInv() async {
    var uri = Uri.parse(postInventory);
    print(uri);
    var request = http.MultipartRequest('POST', uri);

    try {
      Map<String, dynamic> requestData = {
        "farmerId": widget.userId,
        "itemName": _itemNameController.text,
        "weight": _weightController.text,
        "remaining_weight": _remainingWeightController.text,
        "final_rate_per_kg": _finalRatePerKgController.text,
        "description": _descriptionController.text,
        "category": _categoryController.text
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
        print('Inventory Uploaded Successfully');
        _showSnackBar(context, 'Inventory Uploaded Successfully');
      } else {
        print('Inventory code is ${response.statusCode}.');
        _showSnackBar(context, 'Failed to Upload Inventory');
      }
    } catch (err) {
      print(err);
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
        title: Text('INVENTORY FORM'),
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
                  ? Text('No image selected.')
                  : Image.file(File(_selectedImage!.path)),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _createInv().then((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              BottomNavigationBarPage(userId: widget.userId),
                        ),
                      );
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
