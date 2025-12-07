import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/shopping_item_model.dart';
import '../../models/shopping_list_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

final shoppingListItemsProvider = StreamProvider.family<List<ShoppingItemModel>, String>((ref, listId) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getShoppingListItems(user.uid, listId);
});

class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final ShoppingListModel list;

  const ShoppingListDetailScreen({super.key, required this.list});

  @override
  ConsumerState<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends ConsumerState<ShoppingListDetailScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _textController.text.trim();
    if (name.isEmpty) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final newItem = ShoppingItemModel(
      id: const Uuid().v4(),
      name: name,
    );

    try {
      await ref.read(firestoreServiceProvider).addShoppingItem(user.uid, widget.list.id, newItem);
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  Future<void> _toggleItem(ShoppingItemModel item) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    await ref.read(firestoreServiceProvider).toggleShoppingItem(user.uid, widget.list.id, item.id, !item.isChecked);
  }

  Future<void> _deleteItem(String itemId) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    await ref.read(firestoreServiceProvider).deleteShoppingItem(user.uid, widget.list.id, itemId);
  }

  Future<void> _deleteList() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List?'),
        content: const Text('This will delete the list and all its items. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(firestoreServiceProvider).deleteShoppingList(user.uid, widget.list.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingListItemsProvider(widget.list.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteList,
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Item Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Add item...',
                      prefixIcon: Icon(Icons.add_shopping_cart),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No items in this list',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Dismissible(
                      key: Key(item.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteItem(item.id),
                      child: CheckboxListTile(
                        value: item.isChecked,
                        onChanged: (_) => _toggleItem(item),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.isChecked ? TextDecoration.lineThrough : null,
                            color: item.isChecked ? Colors.grey : null,
                          ),
                        ),
                        secondary: const Icon(Icons.circle, size: 12),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
