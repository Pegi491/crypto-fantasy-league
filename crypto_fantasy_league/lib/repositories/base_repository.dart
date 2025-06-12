// ABOUTME: Base repository class providing common Firestore operations and error handling
// ABOUTME: Implements repository pattern with standardized CRUD operations and real-time listeners

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

abstract class BaseRepository<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath;

  BaseRepository(this.collectionPath);

  // Abstract methods that must be implemented by subclasses
  T fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore(T item);
  String getId(T item);

  // Get collection reference
  CollectionReference get collection => _firestore.collection(collectionPath);

  // Get document reference
  DocumentReference getDocRef(String id) => collection.doc(id);

  // Create a new document
  Future<String> create(T item) async {
    try {
      AppLogger.info('Creating document in $collectionPath');
      
      final docRef = collection.doc();
      final data = toFirestore(item);
      
      await docRef.set(data);
      AppLogger.info('Document created successfully: ${docRef.id}');
      
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create document in $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Create with specific ID
  Future<void> createWithId(String id, T item) async {
    try {
      AppLogger.info('Creating document with ID $id in $collectionPath');
      
      final data = toFirestore(item);
      await getDocRef(id).set(data);
      
      AppLogger.info('Document created successfully with ID: $id');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create document with ID $id in $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Get a document by ID
  Future<T?> getById(String id) async {
    try {
      AppLogger.debug('Getting document $id from $collectionPath');
      
      final doc = await getDocRef(id).get();
      
      if (!doc.exists) {
        AppLogger.warning('Document $id not found in $collectionPath');
        return null;
      }
      
      return fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get document $id from $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Update a document
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      AppLogger.info('Updating document $id in $collectionPath');
      
      data['updated_at'] = FieldValue.serverTimestamp();
      await getDocRef(id).update(data);
      
      AppLogger.info('Document updated successfully: $id');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update document $id in $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Update or create (upsert)
  Future<void> upsert(String id, T item) async {
    try {
      AppLogger.info('Upserting document $id in $collectionPath');
      
      final data = toFirestore(item);
      await getDocRef(id).set(data, SetOptions(merge: true));
      
      AppLogger.info('Document upserted successfully: $id');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upsert document $id in $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Delete a document
  Future<void> delete(String id) async {
    try {
      AppLogger.info('Deleting document $id from $collectionPath');
      
      await getDocRef(id).delete();
      
      AppLogger.info('Document deleted successfully: $id');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete document $id from $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Get all documents
  Future<List<T>> getAll({Query Function(CollectionReference)? queryBuilder}) async {
    try {
      AppLogger.debug('Getting all documents from $collectionPath');
      
      Query query = collection;
      if (queryBuilder != null) {
        query = queryBuilder(collection);
      }
      
      final snapshot = await query.get();
      
      final items = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
      AppLogger.debug('Retrieved ${items.length} documents from $collectionPath');
      
      return items;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all documents from $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Get documents with pagination
  Future<List<T>> getPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    Query Function(CollectionReference)? queryBuilder,
  }) async {
    try {
      AppLogger.debug('Getting paginated documents from $collectionPath (limit: $limit)');
      
      Query query = collection;
      if (queryBuilder != null) {
        query = queryBuilder(collection);
      }
      
      query = query.limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final snapshot = await query.get();
      
      final items = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
      AppLogger.debug('Retrieved ${items.length} paginated documents from $collectionPath');
      
      return items;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get paginated documents from $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Real-time listener for a single document
  Stream<T?> watchById(String id) {
    AppLogger.debug('Starting real-time listener for document $id in $collectionPath');
    
    return getDocRef(id).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return fromFirestore(doc);
    }).handleError((error, stackTrace) {
      AppLogger.error('Error in real-time listener for $id in $collectionPath', error, stackTrace);
    });
  }

  // Real-time listener for multiple documents
  Stream<List<T>> watchAll({Query Function(CollectionReference)? queryBuilder}) {
    AppLogger.debug('Starting real-time listener for collection $collectionPath');
    
    Query query = collection;
    if (queryBuilder != null) {
      query = queryBuilder(collection);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    }).handleError((error, stackTrace) {
      AppLogger.error('Error in real-time listener for collection $collectionPath', error, stackTrace);
    });
  }

  // Batch operations
  Future<void> batchWrite(List<BatchOperation<T>> operations) async {
    try {
      AppLogger.info('Starting batch write with ${operations.length} operations in $collectionPath');
      
      final batch = _firestore.batch();
      
      for (final operation in operations) {
        switch (operation.type) {
          case BatchOperationType.create:
            final docRef = operation.id != null 
                ? getDocRef(operation.id!) 
                : collection.doc();
            batch.set(docRef, toFirestore(operation.item!));
            break;
          case BatchOperationType.update:
            final data = operation.data!;
            data['updated_at'] = FieldValue.serverTimestamp();
            batch.update(getDocRef(operation.id!), data);
            break;
          case BatchOperationType.delete:
            batch.delete(getDocRef(operation.id!));
            break;
        }
      }
      
      await batch.commit();
      AppLogger.info('Batch write completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to execute batch write in $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Count documents
  Future<int> count({Query Function(CollectionReference)? queryBuilder}) async {
    try {
      Query query = collection;
      if (queryBuilder != null) {
        query = queryBuilder(collection);
      }
      
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to count documents in $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  // Check if document exists
  Future<bool> exists(String id) async {
    try {
      final doc = await getDocRef(id).get();
      return doc.exists;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check existence of document $id in $collectionPath', e, stackTrace);
      rethrow;
    }
  }
}

// Batch operation types
enum BatchOperationType { create, update, delete }

class BatchOperation<T> {
  final BatchOperationType type;
  final String? id;
  final T? item;
  final Map<String, dynamic>? data;

  BatchOperation.create(this.item, {this.id}) 
      : type = BatchOperationType.create, data = null;
  
  BatchOperation.update(this.id, this.data) 
      : type = BatchOperationType.update, item = null;
  
  BatchOperation.delete(this.id) 
      : type = BatchOperationType.delete, item = null, data = null;
}