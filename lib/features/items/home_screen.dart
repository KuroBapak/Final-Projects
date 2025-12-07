import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/item_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../shopping_list/shopping_lists_screen.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  Future<void> _deleteSelectedItems() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedIds.length} items?'),
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
      for (final id in _selectedIds) {
        await ref.read(firestoreServiceProvider).deleteItem(user.uid, id);
      }
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items deleted')),
        );
      }
    }
  }

  final _pageController = PageController();



  // ... (selection mode methods remain same)

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final itemsAsync = ref.watch(userItemsProvider(user?.uid ?? ''));
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final List<Widget> pages = [
      _buildItemList(itemsAsync),
      const ShoppingListsScreen(),
      const DashboardScreen(),
    ];

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              // ... (selection mode app bar remains same)
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                }),
              ),
              title: Text('${_selectedIds.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    itemsAsync.whenData((items) {
                      setState(() {
                        _selectedIds.addAll(items.map((e) => e.id));
                      });
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedItems,
                ),
              ],
            )
          : AppBar(
              title: const Text('ExpiryGuard'),
              actions: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
      body: Column(
        children: [
          if (_currentIndex == 0 && !_isSelectionMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          
          // Filter & Sort Row
          if (_currentIndex == 0 && !_isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Sort Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showSortSheet,
                      icon: const Icon(Icons.sort, size: 18),
                      label: Text(
                        _sortBy == 'expiry' ? 'Expiry' : _sortBy == 'name' ? 'Name' : 'Qty',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Category Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showCategorySheet,
                      icon: const Icon(Icons.category_outlined, size: 18),
                      label: Text(
                        _filterCategory,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          

            
          if (_currentIndex == 0 && !_isSelectionMode)
            const SizedBox(height: 8),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (_isSelectionMode) return;
                setState(() => _currentIndex = index);
              },
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_isSelectionMode) return;
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Items',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Shopping',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Dashboard',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 && !_isSelectionMode)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItemScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
    );
  }

  // Sort & Filter State
  String _sortBy = 'expiry'; // expiry, name, quantity
  String _filterCategory = 'All';

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Expiry Date'),
                  selected: _sortBy == 'expiry',
                  onSelected: (selected) {
                    setState(() => _sortBy = 'expiry');
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Name'),
                  selected: _sortBy == 'name',
                  onSelected: (selected) {
                    setState(() => _sortBy = 'name');
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Quantity'),
                  selected: _sortBy == 'quantity',
                  onSelected: (selected) {
                    setState(() => _sortBy = 'quantity');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Category', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filterCategory == 'All',
                    onSelected: (selected) {
                      setState(() => _filterCategory = 'All');
                      Navigator.pop(context);
                    },
                  ),
                  ...AppConstants.categories.map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _filterCategory == c,
                        onSelected: (selected) {
                          setState(() => _filterCategory = c);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemList(AsyncValue<List<ItemModel>> itemsAsync) {
    // ... (rest of method)
    return itemsAsync.when(
      data: (items) {
        var filteredItems = items.where((item) {
          final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.category.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _filterCategory == 'All' || item.category == _filterCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        // Sort
        filteredItems.sort((a, b) {
          switch (_sortBy) {
            case 'name':
              return a.name.compareTo(b.name);
            case 'quantity':
              return b.quantity.compareTo(a.quantity); // Descending
            case 'expiry':
            default:
              return a.expiryDate.compareTo(b.expiryDate);
          }
        });

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No items found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return _buildItemCard(item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
    final daysLeft = expiryDate.difference(today).inDays;
    
    final isExpired = daysLeft <= 0;
    final isWarning = daysLeft < 7 && !isExpired;
    
    Color statusColor = Colors.green;
    if (isExpired) {
      statusColor = Colors.red;
    } else if (isWarning) {
      statusColor = Colors.orange;
    }

    final isSelected = _selectedIds.contains(item.id);

    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(item.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(item: item),
              ),
            );
          }
        },
        onLongPress: () => _enterSelectionMode(item.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Selection Checkbox or Image
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

              // Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  image: item.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: _getImageProvider(item.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imageUrl.isEmpty
                    ? const Icon(Icons.image_not_supported, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          isExpired
                              ? (daysLeft == 0 ? 'Expired Today' : 'Expired ${daysLeft.abs()} days ago')
                              : 'Expires in $daysLeft days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}
