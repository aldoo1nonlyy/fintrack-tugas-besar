import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/product_item.dart';
import '../models/invoice.dart';
import '../models/bon.dart';
import '../models/hutang_usaha.dart';
import '../models/financial_entry.dart';
import '../models/business_profile.dart';
import '../models/transaction_status.dart';

/// Service untuk semua operasi Firestore.
/// Data disimpan per-pengguna: users/{uid}/collection
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// UID pengguna yang sedang login
  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Pengguna belum login.');
    return uid;
  }

  /// Apakah pengguna sedang login
  bool get isLoggedIn => _auth.currentUser != null;

  // --- COLLECTION GETTERS (per user) ---

  CollectionReference<Map<String, dynamic>> get _customersCol =>
      _db.collection('users').doc(_uid).collection('customers');

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _db.collection('users').doc(_uid).collection('products');

  CollectionReference<Map<String, dynamic>> get _invoicesCol =>
      _db.collection('users').doc(_uid).collection('invoices');

  CollectionReference<Map<String, dynamic>> get _bonsCol =>
      _db.collection('users').doc(_uid).collection('bons');


  CollectionReference<Map<String, dynamic>> get _hutangUsahasCol =>
      _db.collection('users').doc(_uid).collection('hutangUsahas');

  CollectionReference<Map<String, dynamic>> get _financialEntriesCol =>
      _db.collection('users').doc(_uid).collection('financialEntries');

  DocumentReference<Map<String, dynamic>> get _profileDoc =>
      _db.collection('users').doc(_uid).collection('settings').doc('profile');

  // --- MAP CONVERSION HELPERS ---


  Map<String, dynamic> _customerToMap(Customer e) => {
    'id': e.id,
    'name': e.name,
    'phone': e.phone,
    'address': e.address,
    'email': e.email,
  };

  Customer _customerFromMap(Map<String, dynamic> map) => Customer(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    address: map['address'] ?? '',
    email: map['email'],
  );

  Map<String, dynamic> _productToMap(ProductItem e) => {
    'id': e.id,
    'name': e.name,
    'price': e.price,
    'category': e.category,
  };

  ProductItem _productFromMap(Map<String, dynamic> map) => ProductItem(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    category: map['category'] ?? '',
  );

  Map<String, dynamic> _invoiceToMap(Invoice e) => {
    'id': e.id,
    'number': e.number,
    'customerId': e.customerId,
    'customerName': e.customerName,
    'date': e.date.toIso8601String(),
    'notes': e.notes,
    'status': e.status.index,
    'items': e.items.map((i) => {
      'id': i.id,
      'itemName': i.itemName,
      'qty': i.qty,
      'price': i.price,
    }).toList(),
  };

  Invoice _invoiceFromMap(Map<String, dynamic> map) => Invoice(
    id: map['id'] ?? '',
    number: map['number'] ?? '',
    customerId: map['customerId'] ?? '',
    customerName: map['customerName'] ?? '',
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    notes: map['notes'] ?? '',
    status: TransactionStatus.values[(map['status'] as int?) ?? 0],
    items: ((map['items'] as List<dynamic>?) ?? []).map((i) => InvoiceLine(
      id: i['id'] ?? '',
      itemName: i['itemName'] ?? '',
      qty: (i['qty'] as num?)?.toInt() ?? 0,
      price: (i['price'] as num?)?.toDouble() ?? 0.0,
    )).toList(),
  );

  Map<String, dynamic> _bonToMap(Bon e) => {
        'id': e.id,
        'customerName': e.customerName,
        'amount': e.amount,
        'date': e.date.toIso8601String(),
        'notes': e.notes,
        'status': e.status.index,
        'items': e.items.map((i) => {
          'id': i.id,
          'itemName': i.itemName,
          'qty': i.qty,
          'price': i.price,
        }).toList(),
      };

  Bon _bonFromMap(Map<String, dynamic> map) => Bon(
        id: map['id'] ?? '',
        customerName: map['customerName'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
        notes: map['notes'] ?? '',
        status: TransactionStatus.values[(map['status'] as int?) ?? 0],
        items: map['items'] == null ? <BonLine>[] : (map['items'] as List<dynamic>).map((i) => BonLine(
          id: i['id'] ?? '',
          itemName: i['itemName'] ?? '',
          qty: (i['qty'] as num?)?.toInt() ?? 0,
          price: (i['price'] as num?)?.toDouble() ?? 0.0,
        )).toList(),
      );

  Map<String, dynamic> _hutangUsahaToMap(HutangUsaha e) => {
    'id': e.id,
    'number': e.number,
    'supplierName': e.supplierName,
    'amount': e.amount,
    'date': e.date.toIso8601String(),
    'notes': e.notes,
    'status': e.status.index,
  };

  HutangUsaha _hutangUsahaFromMap(Map<String, dynamic> map) => HutangUsaha(
    id: map['id'] ?? '',
    number: map['number'] ?? '',
    supplierName: map['supplierName'] ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    notes: map['notes'] ?? '',
    status: TransactionStatus.values[(map['status'] as int?) ?? 0],
  );

  Map<String, dynamic> _financialToMap(FinancialEntry e) => {
    'id': e.id,
    'title': e.title,
    'description': e.description,
    'amount': e.amount,
    'date': e.date.toIso8601String(),
    'type': e.type.index,
    'sourceLabel': e.sourceLabel,
    'sourceId': e.sourceId,
    'status': e.status?.index,
  };

  FinancialEntry _financialFromMap(Map<String, dynamic> map) => FinancialEntry(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    type: FinancialEntryType.values[(map['type'] as int?) ?? 0],
    sourceLabel: map['sourceLabel'] ?? 'Manual',
    sourceId: map['sourceId'],
    status: map['status'] != null ? TransactionStatus.values[map['status'] as int] : null,
  );

  Map<String, dynamic> _profileToMap(BusinessProfile e) => {
    'businessName': e.businessName,
    'address': e.address,
    'phone': e.phone,
    'invoiceFooter': e.invoiceFooter,
  };

  BusinessProfile _profileFromMap(Map<String, dynamic> map) => BusinessProfile(
    businessName: map['businessName'] ?? '',
    address: map['address'] ?? '',
    phone: map['phone'] ?? '',
    invoiceFooter: map['invoiceFooter'] ?? '',
  );

  // --- CRUD: Customers ---

  Future<List<Customer>> fetchCustomers() async {
    try {
      final snap = await _customersCol.get();
      return snap.docs.map((doc) => _customerFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore fetchCustomers Error: $e');
      return [];
    }
  }

  Future<void> saveCustomer(Customer item) async {
    try {
      await _customersCol.doc(item.id).set(_customerToMap(item));
    } catch (e) {
      debugPrint('Firestore saveCustomer Error: $e');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _customersCol.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteCustomer Error: $e');
    }
  }

  // --- CRUD: Products ---

  Future<List<ProductItem>> fetchProducts() async {
    try {
      final snap = await _productsCol.get();
      return snap.docs.map((doc) => _productFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore fetchProducts Error: $e');
      return [];
    }
  }

  Future<void> saveProduct(ProductItem item) async {
    try {
      await _productsCol.doc(item.id).set(_productToMap(item));
    } catch (e) {
      debugPrint('Firestore saveProduct Error: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productsCol.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteProduct Error: $e');
    }
  }

  // --- CRUD: Invoices ---

  Future<List<Invoice>> fetchInvoices() async {
    try {
      final snap = await _invoicesCol.get();
      return snap.docs.map((doc) => _invoiceFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore fetchInvoices Error: $e');
      return [];
    }
  }

  Future<void> saveInvoice(Invoice item) async {
    try {
      await _invoicesCol.doc(item.id).set(_invoiceToMap(item));
    } catch (e) {
      debugPrint('Firestore saveInvoice Error: $e');
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _invoicesCol.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteInvoice Error: $e');
    }
  }

  // --- CRUD: Bons ---

  Future<List<Bon>> fetchBons() async {
    try {
      final snap = await _bonsCol.get();
      return snap.docs.map((doc) => _bonFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore fetchBons Error: $e');
      return [];
    }
  }

  Future<void> saveBon(Bon item) async {
    try {
      await _bonsCol.doc(item.id).set(_bonToMap(item));
    } catch (e) {
      debugPrint('Firestore saveBon Error: $e');
    }
  }

  Future<void> deleteBon(String id) async {
    try {
      await _bonsCol.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteBon Error: $e');
    }
  }

  // --- CRUD: HutangUsahas ---

  Future<List<HutangUsaha>> fetchHutangUsahas() async {
    try {
      final snap = await _hutangUsahasCol.get();
      return snap.docs.map((doc) => _hutangUsahaFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore fetchHutangUsahas Error: $e');
      return [];
    }
  }

  Future<void> saveHutangUsaha(HutangUsaha item) async {
    try {
      await _hutangUsahasCol.doc(item.id).set(_hutangUsahaToMap(item));
    } catch (e) {
      debugPrint('Firestore saveHutangUsaha Error: $e');
    }
  }

  Future<void> deleteHutangUsaha(String id) async {
    try {
      await _hutangUsahasCol.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteHutangUsaha Error: $e');
    }
  }

  // --- CRUD: Financial Entries ---

  Future<List<FinancialEntry>> fetchFinancialEntries() async {
    try {
      final snap = await _financialEntriesCol.get();
      return snap.docs.map((doc) => _financialFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore fetchFinancialEntries Error: $e');
      return [];
    }
  }

  Future<void> saveFinancialEntry(FinancialEntry item) async {
    try {
      await _financialEntriesCol.doc(item.id).set(_financialToMap(item));
    } catch (e) {
      debugPrint('Firestore saveFinancialEntry Error: $e');
    }
  }

  Future<void> deleteFinancialEntry(String id) async {
    try {
      await _financialEntriesCol.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteFinancialEntry Error: $e');
    }
  }

  // --- CRUD: Business Profile ---

  Future<BusinessProfile?> fetchBusinessProfile() async {
    try {
      final snap = await _profileDoc.get();
      if (snap.exists && snap.data() != null) {
        return _profileFromMap(snap.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Firestore fetchBusinessProfile Error: $e');
      return null;
    }
  }

  Future<void> saveBusinessProfile(BusinessProfile item) async {
    try {
      await _profileDoc.set(_profileToMap(item));
    } catch (e) {
      debugPrint('Firestore saveBusinessProfile Error: $e');
    }
  }

  // --- BULK SYNC ---

  /// Upload semua data lokal ke Firestore dalam satu batch
  Future<void> uploadAllLocalData({
    required List<Customer> customers,
    required List<ProductItem> products,
    required List<Invoice> invoices,
    required List<Bon> bons,
    required List<HutangUsaha> hutangUsahas,
    required List<FinancialEntry> financialEntries,
    required BusinessProfile businessProfile,
  }) async {
    // Firestore batch limit: 500 operasi per commit
    // Jika data besar, split menjadi beberapa batch
    var batch = _db.batch();
    int count = 0;

    Future<void> maybeCommit() async {
      if (count >= 490) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    for (final e in customers) {
      batch.set(_customersCol.doc(e.id), _customerToMap(e));
      count++;
      await maybeCommit();
    }
    for (final e in products) {
      batch.set(_productsCol.doc(e.id), _productToMap(e));
      count++;
      await maybeCommit();
    }
    for (final e in invoices) {
      batch.set(_invoicesCol.doc(e.id), _invoiceToMap(e));
      count++;
      await maybeCommit();
    }
    for (final e in bons) {
      batch.set(_bonsCol.doc(e.id), _bonToMap(e));
      count++;
      await maybeCommit();
    }
    for (final e in hutangUsahas) {
      batch.set(_hutangUsahasCol.doc(e.id), _hutangUsahaToMap(e));
      count++;
      await maybeCommit();
    }
    for (final e in financialEntries) {
      batch.set(_financialEntriesCol.doc(e.id), _financialToMap(e));
      count++;
      await maybeCommit();
    }
    batch.set(_profileDoc, _profileToMap(businessProfile));

    await batch.commit();
  }
}
