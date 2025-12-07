import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

final userItemsProvider = StreamProvider.family<List<ItemModel>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getUserItems(userId);
});

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  Future<void> addItem(String userId, ItemModel item) async {
    try {
      // Use the item's ID as the document ID
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(item.id)
          .set(item.toMap());
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  Future<void> updateItem(String userId, ItemModel item) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(item.id)
          .update(item.toMap());
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Stream<List<ItemModel>> getUserItems(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('items')
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> deleteItem(String userId, String itemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Shopping List Management
  Future<void> createShoppingList(String userId, ShoppingListModel list) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(list.id)
          .set(list.toMap());
    } catch (e) {
      throw Exception('Failed to create shopping list: $e');
    }
  }

  Stream<List<ShoppingListModel>> getShoppingLists(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShoppingListModel.fromMap(doc.data());
      }).toList();
    });
  }

  Future<List<ShoppingListModel>> fetchShoppingLists(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ShoppingListModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch shopping lists: $e');
    }
  }

  Future<void> deleteShoppingList(String userId, String listId) async {
    try {
      // Note: Subcollections are not automatically deleted in Firestore.
      // For a production app, you'd use a Cloud Function or batch delete.
      // Here we'll just delete the parent doc for simplicity, 
      // but orphaned items will remain in the subcollection.
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete shopping list: $e');
    }
  }

  // Shopping List Items (Nested)
  Future<void> addShoppingItem(String userId, String listId, ShoppingItemModel item) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(item.id)
          .set(item.toMap());
      
      // Update item count (optional, but nice for UI)
      // We use a transaction or just simple increment for now
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listId)
          .update({'itemCount': FieldValue.increment(1)});

    } catch (e) {
      throw Exception('Failed to add shopping item: $e');
    }
  }

  Stream<List<ShoppingItemModel>> getShoppingListItems(String userId, String listId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .doc(listId)
        .collection('items')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShoppingItemModel.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> toggleShoppingItem(String userId, String listId, String itemId, bool isChecked) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .update({'isChecked': isChecked});
    } catch (e) {
      throw Exception('Failed to update shopping item: $e');
    }
  }

  Future<void> deleteShoppingItem(String userId, String listId, String itemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .delete();
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listId)
          .update({'itemCount': FieldValue.increment(-1)});
    } catch (e) {
      throw Exception('Failed to delete shopping item: $e');
    }
  }
}
