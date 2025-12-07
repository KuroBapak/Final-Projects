import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/item_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'package:uuid/uuid.dart';
import '../../models/shopping_list_model.dart';
import '../../models/shopping_item_model.dart';

class ItemDetailScreen extends ConsumerWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  Future<void> _consumeItem(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    if (item.quantity > 1) {
      // Decrement quantity
      final updatedItem = item.copyWith(quantity: item.quantity - 1);
      await ref.read(firestoreServiceProvider).updateItem(user.uid, updatedItem);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item consumed. Quantity updated.')),
        );
        Navigator.pop(context);
      }
    } else {
      // Quantity is 1, ask to add to shopping list
      final addToShoppingList = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Out of Stock!'),
          content: const Text('You used the last one. Add to shopping list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, just delete'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Add to List'),
            ),
          ],
        ),
      );

      if (addToShoppingList == true) {
        // Add to shopping list logic
        try {
          final firestore = ref.read(firestoreServiceProvider);
          // 1. Fetch existing lists
          final existingLists = await firestore.fetchShoppingLists(user.uid);
          
          ShoppingListModel? targetList;
          // 2. Look for "Out Of Stock" list
          try {
             targetList = existingLists.firstWhere((list) => list.title == 'Out Of Stock');
          } catch (_) {
            targetList = null;
          }

          // 3. Create if not exists
          if (targetList == null) {
            targetList = ShoppingListModel(
              id: const Uuid().v4(),
              title: 'Out Of Stock',
              createdAt: DateTime.now(),
            );
            await firestore.createShoppingList(user.uid, targetList);
          }

          // 4. Add item to the list
          final newItem = ShoppingItemModel(
            id: const Uuid().v4(),
            name: item.name,
            isChecked: false,
          );
          await firestore.addShoppingItem(user.uid, targetList.id, newItem);

          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added "${item.name}" to Out Of Stock list')),
            );
          }
        } catch (e) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add to list: $e')),
            );
          }
        }
      }
      
      // Delete item
      await ref.read(firestoreServiceProvider).deleteItem(user.uid, item.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(firestoreServiceProvider).deleteItem(user.uid, item.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showFullImage(BuildContext context) {
    if (item.imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _getImageProvider(item.imageUrl),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      return FileImage(File(imageUrl));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
    final daysLeft = expiryDate.difference(today).inDays;
    final isExpired = daysLeft <= 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteItem(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Header
            if (item.imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _showFullImage(context),
                child: Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.black,
                  child: Hero(
                    tag: item.id,
                    child: Image(
                      image: _getImageProvider(item.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Category
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(item.category),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  const SizedBox(height: 24),

                  // Dates
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Purchased',
                    value: DateFormat('MMMM d, y').format(item.purchaseDate),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.event_busy,
                    label: 'Expires',
                    value: DateFormat('MMMM d, y').format(item.expiryDate),
                    valueColor: isExpired ? Colors.red : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.notifications_active_outlined,
                    label: 'Reminder',
                    value: '${item.reminderConfig} days before',
                  ),
                  const SizedBox(height: 24),

                  // Quantity & Consume
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quantity',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${item.quantity}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _consumeItem(context, ref),
                            icon: const Icon(Icons.restaurant_menu),
                            label: const Text('Consume Item'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
