import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../services/barcode_service.dart';
import 'add_item_controller.dart';
import 'barcode_scanner_screen.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCategory = AppConstants.categories.first;
  DateTime _purchaseDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  int _reminderDays = 7;
  int _quantity = 1;
  File? _imageFile;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ref.read(addItemControllerProvider.notifier).pickImage(source);
    if (file != null) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fetching product details...')),
        );
      }

      final product = await ref.read(barcodeServiceProvider).fetchProductDetails(barcode);
      
      if (mounted) {
        if (product != null) {
          setState(() {
            _nameController.text = product.name;
            if (AppConstants.categories.contains(product.category)) {
              _selectedCategory = product.category;
            }
          });

          // Auto-download image if available
          if (product.imageUrl.isNotEmpty) {
            try {
              final response = await http.get(Uri.parse(product.imageUrl));
              if (response.statusCode == 200) {
                final directory = await getApplicationDocumentsDirectory();
                final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                final file = File(path.join(directory.path, fileName));
                await file.writeAsBytes(response.bodyBytes);
                
                setState(() => _imageFile = file);
              }
            } catch (e) {
              debugPrint('Failed to download image: $e');
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Found: ${product.name}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found')),
          );
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPurchase) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPurchase ? _purchaseDate : _expiryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isPurchase) {
          _purchaseDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _scanDate() async {
    if (_imageFile == null) return;
    
    final date = await ref.read(addItemControllerProvider.notifier).scanDateFromImage(_imageFile!);
    
    if (mounted) {
      if (date != null) {
        setState(() => _expiryDate = date);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Date detected: ${DateFormat('dd/MM/yyyy').format(date)}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No date detected in image')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(addItemControllerProvider.notifier).addItem(
            name: _nameController.text.trim(),
            category: _selectedCategory,
            purchaseDate: _purchaseDate,
            expiryDate: _expiryDate,
            reminderConfig: _reminderDays,
            quantity: _quantity,
            imageFile: _imageFile,
          );

      if (mounted) {
        final state = ref.read(addItemControllerProvider);
        if (!state.hasError) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item Added Successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.error}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addItemControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Camera'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('Tap to add photo', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        )
                      : null,
                ),
              ),
              
              // Scan Actions
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    if (_imageFile != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _scanDate,
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Scan Date'),
                        ),
                      ),
                    if (_imageFile != null) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Barcode'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              const SizedBox(height: 16),
              
              // Quantity
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: AppConstants.categories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text(
                          '$_quantity',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Purchase Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_purchaseDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          prefixIcon: Icon(Icons.event_busy),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_expiryDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reminder Slider
              Text('Remind me $_reminderDays days before', style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _reminderDays.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: '$_reminderDays days',
                onChanged: (val) => setState(() => _reminderDays = val.toInt()),
              ),
              const SizedBox(height: 24),

              // Submit Button
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Item'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
