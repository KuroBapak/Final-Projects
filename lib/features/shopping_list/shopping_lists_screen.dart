import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/shopping_list_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'shopping_list_detail_screen.dart';

final shoppingListsProvider = StreamProvider.family<List<ShoppingListModel>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getShoppingLists(userId);
});

class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  Future<void> _createNewList(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Shopping List'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'e.g., Weekly Groceries',
            labelText: 'List Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final user = ref.read(authServiceProvider).currentUser;
                if (user != null) {
                  final newList = ShoppingListModel(
                    id: const Uuid().v4(),
                    title: title,
                    createdAt: DateTime.now(),
                  );
                  await ref.read(firestoreServiceProvider).createShoppingList(user.uid, newList);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final listsAsync = ref.watch(shoppingListsProvider(user?.uid ?? ''));

    return Scaffold(
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No shopping lists yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _createNewList(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First List'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShoppingListDetailScreen(list: list),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      list.title.isNotEmpty ? list.title[0].toUpperCase() : '?',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  title: Text(list.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${DateFormat('MMM d, y').format(list.createdAt)} • ${list.itemCount} items',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: listsAsync.when(
        data: (lists) => lists.isEmpty
            ? null
            : FloatingActionButton(
                onPressed: () => _createNewList(context, ref),
                child: const Icon(Icons.add),
              ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}
