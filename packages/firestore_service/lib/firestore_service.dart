library firestore_service;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  Future<void> setData({
    @required String path,
    @required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    final reference = FirebaseFirestore.instance.doc(path);
    print('$path: $data');
    await reference.set(data, SetOptions(merge: merge));
  }

  Future<DocumentReference> pushDocument({

    @required String collectionPath,
    @required Map<String, dynamic> data
  } ) async{
    final collectionReference = FirebaseFirestore.instance.collection(collectionPath);
    return await collectionReference.add(data);
  }

  Future<QuerySnapshot> getDocuments<T>({@required String collectionPath}) async {
    final reference = FirebaseFirestore.instance.collection(collectionPath);
    print('collectionPath: $collectionPath');
    return reference.get();
  }

  Future<void> deleteData({@required String path}) async {
    final reference = FirebaseFirestore.instance.doc(path);
    print('delete: $path');
    await reference.delete();
  }

  DocumentReference getDocumentReference({@required String path}) {
    return FirebaseFirestore.instance.doc(path);
  }

  CollectionReference getCollectionReference({@required String collectionPath}) {
    return FirebaseFirestore.instance.collection(collectionPath);
  }

  Future<T> getData<T>({@required String path}) async {
    final reference = FirebaseFirestore.instance.doc(path);
    print('get: $path');
    await reference.get();
  }

  Stream<List<T>> collectionStream<T>({
    @required String path,
    T Function(Map<String, dynamic> data, String documentID) builder,
    Future<T> Function(Map<String, dynamic> data, String documentID) asyncBuilder,
    Query Function(Query query) queryBuilder,
    int Function(T lhs, T rhs) sort,
  }) {
    if( (builder == null && asyncBuilder == null) || (builder != null && asyncBuilder != null) ) {
      throw Exception('Specify either a builder OR an async builder function parameter');
    }
    Query query = FirebaseFirestore.instance.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    print("Here $query");
    final Stream<QuerySnapshot> snapshots = query.snapshots();

    return snapshots.map((snapshot) async*{
      print("Found result $snapshot");
      Iterable<QueryDocumentSnapshot> iterable = snapshot.docs
          .where((snapshot) => snapshot.data().isNotEmpty);

      Iterable<T> intermediateResult;
      if(builder!=null) {
        intermediateResult = iterable.map((snapshot) => builder(snapshot.data(), snapshot.id));
      } else {
        intermediateResult = iterable.map((snapshot) async =>  asyncBuilder(snapshot.data(), snapshot.id));
      }
      final result = intermediateResult
          .where((value) => value != null)
          .toList();
      if (sort != null) {
        result.sort(sort);
      }
      yield result;
    });
  }

  Stream<T> documentStream<T>({
    @required String path,
    @required T Function(Map<String, dynamic> data, String documentID) builder,
  }) {
    final DocumentReference reference = FirebaseFirestore.instance.doc(path);
    final Stream<DocumentSnapshot> snapshots = reference.snapshots();
    return snapshots.map((snapshot) => builder(snapshot.data(), snapshot.id));
  }
}
