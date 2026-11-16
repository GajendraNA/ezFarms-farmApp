import 'dart:async';
import 'package:farmer/util/server_wakeup.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Sends inventory data + photo to the backend. Returns null on success,
/// or an error message.
///
/// The backend always needs a photo file, even on update. If no new photo
/// was picked, the current photo is downloaded and sent again.
Future<String?> sendInventory({
  required String method,
  required String url,
  required InventoryFormData data,
  int? farmerId,
  String? existingImageName,
}) async {
  try {
    Uint8List? bytes = data.imageBytes;
    String? fileName = data.imageName;

    if (bytes == null && existingImageName != null) {
      final res = await http
          .get(Uri.parse(getImageUrl(existingImageName)))
          .waitForServer();
      if (res.statusCode == 200) {
        bytes = res.bodyBytes;
        fileName = existingImageName;
      }
    }
    if (bytes == null) return 'Please pick a photo of the item';

    final request = http.MultipartRequest(method, Uri.parse(url))
      ..fields['data'] = jsonEncode(data.toJson(farmerId: farmerId))
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: fileName ?? 'item.jpg'));

    final response = await request.send().waitForServer();
    if (response.statusCode == 200) return null;

    final body = await response.stream.bytesToString();
    debugPrint('Inventory ${response.statusCode}: $body');
    return 'Saving failed (${response.statusCode}). Please try again.';
  } on TimeoutException {
    return 'Server is taking too long. Please try again.';
  } catch (e) {
    debugPrint('Inventory error: $e');
    return 'Could not reach the server. Check your connection.';
  }
}

/// Values entered in the inventory form.
class InventoryFormData {
  final String itemName;
  final String category;
  final double ratePerKg;
  final double weight;
  final double remainingWeight;
  final String description;

  /// New photo picked by the user (null = keep the current photo).
  final Uint8List? imageBytes;
  final String? imageName;

  InventoryFormData({
    required this.itemName,
    required this.category,
    required this.ratePerKg,
    required this.weight,
    required this.remainingWeight,
    required this.description,
    this.imageBytes,
    this.imageName,
  });

  Map<String, dynamic> toJson({int? farmerId}) => {
        if (farmerId != null) "farmerId": farmerId,
        "itemName": itemName,
        "category": category,
        "final_rate_per_kg": ratePerKg,
        "weight": weight,
        "remaining_weight": remainingWeight,
        "description": description,
      };
}

/// Form shared by the Add and Update inventory pages.
class InventoryForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final String? existingImageUrl;
  final bool imageRequired;
  final String submitLabel;

  /// Returns true when saving worked, so the form can reset itself.
  final Future<bool> Function(InventoryFormData data) onSubmit;

  const InventoryForm({
    super.key,
    this.initial,
    this.existingImageUrl,
    this.imageRequired = false,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _itemName = TextEditingController();
  final _category = TextEditingController();
  final _rate = TextEditingController();
  final _weight = TextEditingController();
  final _remaining = TextEditingController();
  final _description = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;

  // While true, the remaining weight follows the total weight automatically.
  bool _remainingFollowsWeight = true;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _itemName.text = i['item_name'] ?? '';
      _category.text = i['item_category'] ?? '';
      _rate.text = formatNum(i['final_rate_per_kg']);
      _weight.text = formatNum(i['weight']);
      _remaining.text = formatNum(i['remaining_weight']);
      _description.text = i['item_description'] ?? '';
      _remainingFollowsWeight = false;
    }
    _weight.addListener(() {
      if (_remainingFollowsWeight) _remaining.text = _weight.text;
    });
  }

  @override
  void dispose() {
    for (final c in [_itemName, _category, _rate, _weight, _remaining, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600, // keeps uploads small and fast
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.imageRequired && _imageBytes == null) {
      showAppSnackBar(context, 'Please pick a photo of the item', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final ok = await widget.onSubmit(InventoryFormData(
      itemName: _itemName.text.trim(),
      category: _category.text.trim(),
      ratePerKg: double.parse(_rate.text.trim()),
      weight: double.parse(_weight.text.trim()),
      remainingWeight: double.parse(_remaining.text.trim()),
      description: _description.text.trim(),
      imageBytes: _imageBytes,
      imageName: _imageName,
    ));

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok && widget.initial == null) {
      // Clear the form after adding a new item.
      _formKey.currentState!.reset();
      for (final c in [_itemName, _category, _rate, _weight, _remaining, _description]) {
        c.clear();
      }
      setState(() {
        _imageBytes = null;
        _imageName = null;
        _remainingFollowsWeight = true;
      });
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixText: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  String? _required(String? v, String name) =>
      (v == null || v.trim().isEmpty) ? 'Please enter $name' : null;

  Widget _imageSection() {
    Widget preview;
    if (_imageBytes != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_imageBytes!,
            height: 200, width: double.infinity, fit: BoxFit.cover),
      );
    } else if (widget.existingImageUrl != null) {
      preview = NetworkImageBox(
        url: widget.existingImageUrl,
        height: 200,
        borderRadius: BorderRadius.circular(12),
      );
    } else {
      preview = Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.green[600]),
              const SizedBox(height: 8),
              Text('No photo selected', style: TextStyle(color: Colors.green[800])),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(onTap: _pickImage, child: preview),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(_imageBytes == null && widget.existingImageUrl == null
              ? 'Pick Photo'
              : 'Change Photo'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = Column(
      children: [
        TextFormField(
          controller: _itemName,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration('Item Name', Icons.eco_outlined),
          validator: (v) => _required(v, 'the item name'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _category,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration('Category (e.g. Vegetable, Fruit)', Icons.category_outlined),
          validator: (v) => _required(v, 'the category'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration('Rate per KG', Icons.currency_rupee, suffix: '₹/kg'),
          validator: (v) => validatePositiveNumber(v, 'the rate'),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration('Total Weight', Icons.scale_outlined, suffix: 'kg'),
                validator: (v) => validatePositiveNumber(v, 'the weight'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _remaining,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration('Remaining', Icons.inventory_2_outlined, suffix: 'kg'),
                onChanged: (_) => _remainingFollowsWeight = false,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter remaining';
                  final r = double.tryParse(v.trim());
                  if (r == null) return 'Enter a valid number';
                  if (r < 0) return 'Cannot be negative';
                  final w = double.tryParse(_weight.text.trim());
                  if (w != null && r > w) return 'More than total weight';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _description,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration('Description', Icons.notes_outlined),
          validator: (v) => _required(v, 'a short description'),
        ),
      ],
    );

    final submit = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(widget.submitLabel, style: const TextStyle(fontSize: 16)),
      ),
    );

    return Form(
      key: _formKey,
      child: LayoutBuilder(builder: (context, constraints) {
        // Wide screens: photo on the left, fields on the right.
        final wide = constraints.maxWidth >= kWideLayoutBreakpoint;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ResponsiveCenter(
              maxWidth: 900,
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _imageSection()),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: Column(children: [fields, const SizedBox(height: 20), submit])),
                      ],
                    )
                  : Column(
                      children: [
                        _imageSection(),
                        const SizedBox(height: 20),
                        fields,
                        const SizedBox(height: 20),
                        submit,
                      ],
                    ),
            ),
          ],
        );
      }),
    );
  }
}
