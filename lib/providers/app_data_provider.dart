import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bon.dart';
import '../models/business_profile.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/hutang_usaha.dart';
import '../models/financial_entry.dart';
import '../models/product_item.dart';
import '../models/transaction_status.dart';

import '../services/storage_service.dart';
import '../services/firebase_service.dart';

class AppDataProvider extends ChangeNotifier {
  final StorageService storageService;
  final FirebaseService firebaseService;

  List<Customer> _customers = [];
  List<ProductItem> _products = [];
  List<Invoice> _invoices = [];
  List<Bon> _bons = [];
  List<HutangUsaha> _hutangUsahas = [];
  List<FinancialEntry> _financialEntries = [];
  BusinessProfile _businessProfile = BusinessProfile(
    businessName: 'Toko Saya',
    address: 'Alamat Toko',
    phone: '08123456789',
    invoiceFooter: 'Terima kasih atas kepercayaannya',
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AppDataProvider(this.storageService, this.firebaseService) {
    _loadLocalData();
    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        clearData();
      } else {
        _syncFromFirebase();
      }
    });
  }

  void clearData() {
    _customers = [];
    _products = [];
    _invoices = [];
    _bons = [];
    _hutangUsahas = [];
    _financialEntries = [];
    _businessProfile = BusinessProfile(
      businessName: 'Toko Saya',
      address: 'Alamat Toko',
      phone: '08123456789',
      invoiceFooter: 'Terima kasih atas kepercayaannya',
    );
    storageService.clearAll();
    notifyListeners();
  }

  void _loadLocalData() {
    _customers = storageService.loadCustomers();
    _products = storageService.loadProducts();
    _invoices = storageService.loadInvoices();
    _bons = storageService.loadBons();
    _hutangUsahas = storageService.loadHutangUsahas();
    _financialEntries = storageService.loadFinancialEntries();

    final savedProfile = storageService.loadProfile();
    if (savedProfile != null) {
      _businessProfile = savedProfile;
    }

    notifyListeners();
  }

  Future<void> _syncFromFirebase() async {
    if (!firebaseService.isLoggedIn) return;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        firebaseService.fetchCustomers(),
        firebaseService.fetchProducts(),
        firebaseService.fetchInvoices(),
        firebaseService.fetchBons(),
        firebaseService.fetchHutangUsahas(),
        firebaseService.fetchFinancialEntries(),
      ]);

      final fbCustomers = results[0] as List<Customer>;
      final fbProducts = results[1] as List<ProductItem>;
      final fbInvoices = results[2] as List<Invoice>;
      final fbBons = results[3] as List<Bon>;
      final fbHutangUsahas = results[4] as List<HutangUsaha>;
      final fbFinancials = results[5] as List<FinancialEntry>;
      final fbProfile = await firebaseService.fetchBusinessProfile();

      if (fbCustomers.isNotEmpty) {
        _customers = fbCustomers;
        await storageService.saveCustomers(_customers);
      }
      if (fbProducts.isNotEmpty) {
        _products = fbProducts;
        await storageService.saveProducts(_products);
      }
      if (fbInvoices.isNotEmpty) {
        _invoices = fbInvoices;
        await storageService.saveInvoices(_invoices);
      }
      if (fbBons.isNotEmpty) {
        _bons = fbBons;
        await storageService.saveBons(_bons);
      }
      if (fbHutangUsahas.isNotEmpty) {
        _hutangUsahas = fbHutangUsahas;
        await storageService.saveHutangUsahas(_hutangUsahas);
      }
      if (fbFinancials.isNotEmpty) {
        _financialEntries = fbFinancials;
        await storageService.saveFinancialEntries(_financialEntries);
      }
      if (fbProfile != null) {
        _businessProfile = fbProfile;
        await storageService.saveProfile(_businessProfile);
      }
    } catch (e) {
      debugPrint('Sinkronisasi Firestore gagal: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Paksa sinkronisasi ulang dari Firestore
  Future<void> refreshFromFirebase() async {
    await _syncFromFirebase();
  }

  /// Upload semua data lokal ke Firestore (migrasi / backup manual)
  Future<void> syncLocalDataToFirebase() async {
    await firebaseService.uploadAllLocalData(
      customers: _customers,
      products: _products,
      invoices: _invoices,
      bons: _bons,
      hutangUsahas: _hutangUsahas,
      financialEntries: _financialEntries,
      businessProfile: _businessProfile,
    );
  }

  // --- GETTERS ---

  List<Customer> get customers => List.unmodifiable(_customers);
  List<ProductItem> get products => List.unmodifiable(_products);
  List<Invoice> get invoices => List.unmodifiable(_invoices);
  List<Bon> get bons => List.unmodifiable(_bons);
  List<HutangUsaha> get hutangUsahas => List.unmodifiable(_hutangUsahas);
  List<FinancialEntry> get financialEntries => List.unmodifiable(_financialEntries);
  BusinessProfile get businessProfile => _businessProfile;

  List<Map<String, dynamic>> get combinedDocumentTransactions {
    final invoiceTransactions = _invoices.map(
      (invoice) => {
        'id': invoice.id,
        'title': invoice.number,
        'subtitle': invoice.customerName,
        'amount': invoice.total,
        'date': invoice.date,
        'status': invoice.status,
        'type': 'Invoice',
      },
    );

    final bonTransactions = _bons.map(
      (bon) => {
        'id': bon.id,
        'title': 'Bon ${bon.id}',
        'subtitle': bon.customerName,
        'amount': bon.amount,
        'date': bon.date,
        'status': bon.status,
        'type': 'Bon',
      },
    );


    final hutangUsahaTransactions = _hutangUsahas.map(
      (hu) => {
        'id': hu.id,
        'title': hu.number,
        'subtitle': hu.supplierName,
        'amount': hu.amount,
        'date': hu.date,
        'status': hu.status,
        'type': 'Hutang Usaha',
      },
    );

    final merged = [...invoiceTransactions, ...bonTransactions, ...hutangUsahaTransactions];
    merged.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return merged;
  }

  List<FinancialEntry> get combinedFinancialEntries {
    final autoFromInvoices = _invoices.map((invoice) {
      final isPaid = invoice.status == TransactionStatus.paid;
      return FinancialEntry(
        id: 'AUTO-${invoice.id}',
        title: invoice.number,
        description: isPaid
            ? 'Invoice sudah lunas dan dihitung sebagai pemasukan.'
            : 'Invoice belum lunas dan dihitung sebagai hutang/piutang pelanggan.',
        amount: invoice.total,
        date: invoice.date,
        type: isPaid ? FinancialEntryType.income : FinancialEntryType.receivable,
        sourceLabel: 'Invoice',
        sourceId: invoice.id,
        status: invoice.status,
      );
    });

    final autoFromBons = _bons.map((bon) {
      final isPaid = bon.status == TransactionStatus.paid;
      return FinancialEntry(
        id: 'AUTO-${bon.id}',
        title: 'Bon ${bon.id} - ${bon.customerName}',
        description: isPaid
            ? 'Bon sudah selesai dan dihitung sebagai pemasukan/pengembalian.'
            : 'Bon belum lunas dan dihitung sebagai hutang/piutang pelanggan.',
        amount: bon.amount,
        date: bon.date,
        type: isPaid ? FinancialEntryType.income : FinancialEntryType.receivable,
        sourceLabel: 'Bon',
        sourceId: bon.id,
        status: bon.status,
      );
    });


    final autoFromHutangUsahas = _hutangUsahas.map((hu) {
      final isPaid = hu.status == TransactionStatus.paid;
      return FinancialEntry(
        id: 'AUTO-${hu.id}',
        title: 'Hutang ke ${hu.supplierName}',
        description: isPaid
            ? 'Hutang usaha telah dilunasi dan dihitung sebagai pengeluaran.'
            : 'Hutang usaha (beban kewajiban).',
        amount: hu.amount,
        date: hu.date,
        type: isPaid ? FinancialEntryType.expense : FinancialEntryType.payable,
        sourceLabel: 'Hutang Usaha',
        sourceId: hu.id,
        status: hu.status,
      );
    });

    final merged = [...autoFromInvoices, ...autoFromBons, ...autoFromHutangUsahas, ..._financialEntries];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  FinancialSummary get financialSummary {
    double income = 0;
    double expense = 0;
    double payable = 0;
    double receivable = 0;

    for (final entry in combinedFinancialEntries) {
      switch (entry.type) {
        case FinancialEntryType.income:
          income += entry.amount;
          break;
        case FinancialEntryType.expense:
          expense += entry.amount;
          break;
        case FinancialEntryType.payable:
          if (entry.status == TransactionStatus.paid) {
            expense += entry.amount;
          } else {
            payable += entry.amount;
          }
          break;
        case FinancialEntryType.receivable:
          if (entry.status == TransactionStatus.paid) {
            income += entry.amount;
          } else {
            receivable += entry.amount;
          }
          break;
      }
    }

    return FinancialSummary(
      income: income,
      expense: expense,
      payable: payable,
      receivable: receivable,
    );
  }

  int get totalInvoice => _invoices.length;
  int get totalBon => _bons.length;
  int get unpaidCount =>
      _invoices.where((e) => e.status == TransactionStatus.unpaid).length +
      _bons.where((e) => e.status == TransactionStatus.unpaid).length +
      _hutangUsahas.where((e) => e.status == TransactionStatus.unpaid).length;
  int get overdueCount =>
      _invoices.where((e) => e.status == TransactionStatus.overdue).length +
      _bons.where((e) => e.status == TransactionStatus.overdue).length +
      _hutangUsahas.where((e) => e.status == TransactionStatus.overdue).length;

  List<Map<String, dynamic>> get recentTransactions => combinedDocumentTransactions.take(6).toList();

  // --- FIND HELPERS ---

  Customer? findCustomerById(String id) {
    try {
      return _customers.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Invoice? findInvoiceById(String id) {
    try {
      return _invoices.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Bon? findBonById(String id) {
    try {
      return _bons.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }


  HutangUsaha? findHutangUsahaById(String id) {
    try {
      return _hutangUsahas.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- CRUD: Customers ---

  void addCustomer(Customer customer) {
    _customers.insert(0, customer);
    storageService.saveCustomers(_customers);
    firebaseService.saveCustomer(customer);
    notifyListeners();
  }

  void updateCustomer(Customer customer) {
    final index = _customers.indexWhere((element) => element.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      storageService.saveCustomers(_customers);
      firebaseService.saveCustomer(customer);
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((element) => element.id == id);
    storageService.saveCustomers(_customers);
    firebaseService.deleteCustomer(id);
    notifyListeners();
  }

  // --- CRUD: Products ---

  void addProduct(ProductItem product) {
    _products.insert(0, product);
    storageService.saveProducts(_products);
    firebaseService.saveProduct(product);
    notifyListeners();
  }

  void updateProduct(ProductItem product) {
    final index = _products.indexWhere((element) => element.id == product.id);
    if (index != -1) {
      _products[index] = product;
      storageService.saveProducts(_products);
      firebaseService.saveProduct(product);
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((element) => element.id == id);
    storageService.saveProducts(_products);
    firebaseService.deleteProduct(id);
    notifyListeners();
  }

  // --- CRUD: Invoices ---

  void addInvoice(Invoice invoice) {
    _invoices.insert(0, invoice);
    storageService.saveInvoices(_invoices);
    firebaseService.saveInvoice(invoice);
    notifyListeners();
  }

  void updateInvoice(Invoice invoice) {
    final index = _invoices.indexWhere((element) => element.id == invoice.id);
    if (index != -1) {
      _invoices[index] = invoice;
      storageService.saveInvoices(_invoices);
      firebaseService.saveInvoice(invoice);
      notifyListeners();
    }
  }

  void deleteInvoice(String id) {
    _invoices.removeWhere((element) => element.id == id);
    storageService.saveInvoices(_invoices);
    firebaseService.deleteInvoice(id);
    notifyListeners();
  }

  void markInvoiceAsPaid(String id) {
    final index = _invoices.indexWhere((element) => element.id == id);
    if (index != -1) {
      _invoices[index] = _invoices[index].copyWith(status: TransactionStatus.paid);
      storageService.saveInvoices(_invoices);
      firebaseService.saveInvoice(_invoices[index]);
      notifyListeners();
    }
  }

  // --- CRUD: Bons ---

  void addBon(Bon bon) {
    _bons.insert(0, bon);
    storageService.saveBons(_bons);
    firebaseService.saveBon(bon);
    notifyListeners();
  }

  void updateBon(Bon bon) {
    final index = _bons.indexWhere((element) => element.id == bon.id);
    if (index != -1) {
      _bons[index] = bon;
      storageService.saveBons(_bons);
      firebaseService.saveBon(bon);
      notifyListeners();
    }
  }

  void deleteBon(String id) {
    _bons.removeWhere((element) => element.id == id);
    storageService.saveBons(_bons);
    firebaseService.deleteBon(id);
    notifyListeners();
  }

  void markBonAsPaid(String id) {
    final index = _bons.indexWhere((element) => element.id == id);
    if (index != -1) {
      _bons[index] = _bons[index].copyWith(status: TransactionStatus.paid);
      storageService.saveBons(_bons);
      firebaseService.saveBon(_bons[index]);
      notifyListeners();
    }
  }


  // --- CRUD: HutangUsahas ---

  void addHutangUsaha(HutangUsaha hutangUsaha) {
    _hutangUsahas.insert(0, hutangUsaha);
    storageService.saveHutangUsahas(_hutangUsahas);
    firebaseService.saveHutangUsaha(hutangUsaha);
    notifyListeners();
  }

  void updateHutangUsaha(HutangUsaha hutangUsaha) {
    final index = _hutangUsahas.indexWhere((element) => element.id == hutangUsaha.id);
    if (index != -1) {
      _hutangUsahas[index] = hutangUsaha;
      storageService.saveHutangUsahas(_hutangUsahas);
      firebaseService.saveHutangUsaha(hutangUsaha);
      notifyListeners();
    }
  }

  void deleteHutangUsaha(String id) {
    _hutangUsahas.removeWhere((element) => element.id == id);
    storageService.saveHutangUsahas(_hutangUsahas);
    firebaseService.deleteHutangUsaha(id);
    notifyListeners();
  }

  void markHutangUsahaAsPaid(String id) {
    final index = _hutangUsahas.indexWhere((element) => element.id == id);
    if (index != -1) {
      _hutangUsahas[index] = _hutangUsahas[index].copyWith(status: TransactionStatus.paid);
      storageService.saveHutangUsahas(_hutangUsahas);
      firebaseService.saveHutangUsaha(_hutangUsahas[index]);
      notifyListeners();
    }
  }

  // --- CRUD: Financial Entries ---

  void addFinancialEntry(FinancialEntry entry) {
    _financialEntries.insert(0, entry);
    storageService.saveFinancialEntries(_financialEntries);
    firebaseService.saveFinancialEntry(entry);
    notifyListeners();
  }

  void updateFinancialEntry(FinancialEntry entry) {
    final index = _financialEntries.indexWhere((element) => element.id == entry.id);
    if (index != -1) {
      _financialEntries[index] = entry;
      storageService.saveFinancialEntries(_financialEntries);
      firebaseService.saveFinancialEntry(entry);
      notifyListeners();
    }
  }

  void deleteFinancialEntry(String id) {
    _financialEntries.removeWhere((element) => element.id == id);
    storageService.saveFinancialEntries(_financialEntries);
    firebaseService.deleteFinancialEntry(id);
    notifyListeners();
  }

  void markFinancialEntryAsPaid(String id) {
    final index = _financialEntries.indexWhere((element) => element.id == id);
    if (index != -1) {
      _financialEntries[index] = _financialEntries[index].copyWith(status: TransactionStatus.paid);
      storageService.saveFinancialEntries(_financialEntries);
      firebaseService.saveFinancialEntry(_financialEntries[index]);
      notifyListeners();
    }
  }

  // --- Business Profile ---

  void updateBusinessProfile(BusinessProfile profile) {
    _businessProfile = profile;
    storageService.saveProfile(_businessProfile);
    firebaseService.saveBusinessProfile(_businessProfile);
    notifyListeners();
  }

  // --- ID GENERATORS ---

  String generateCustomerId() {
    int nextNum = _customers.length + 1;
    while (true) {
      final id = 'C${nextNum.toString().padLeft(3, '0')}';
      if (!_customers.any((e) => e.id == id)) {
        return id;
      }
      nextNum++;
    }
  }

  String generateProductId() {
    int nextNum = _products.length + 1;
    while (true) {
      final id = 'P${nextNum.toString().padLeft(3, '0')}';
      if (!_products.any((e) => e.id == id)) {
        return id;
      }
      nextNum++;
    }
  }

  String generateInvoiceId() {
    int nextNum = _invoices.length + 1;
    while (true) {
      final id = 'I${nextNum.toString().padLeft(3, '0')}';
      if (!_invoices.any((e) => e.id == id)) {
        return id;
      }
      nextNum++;
    }
  }

  String generateInvoiceNumber() {
    int nextNum = _invoices.length + 1;
    while (true) {
      final numStr = 'INV-2026-${nextNum.toString().padLeft(3, '0')}';
      if (!_invoices.any((e) => e.number == numStr)) {
        return numStr;
      }
      nextNum++;
    }
  }

  String generateLineId(int index) => 'IL${DateTime.now().millisecondsSinceEpoch}$index';

  String generateBonId() {
    int nextNum = _bons.length + 1;
    while (true) {
      final id = 'B${nextNum.toString().padLeft(3, '0')}';
      if (!_bons.any((e) => e.id == id)) {
        return id;
      }
      nextNum++;
    }
  }


  String generateHutangUsahaId() {
    int nextNum = _hutangUsahas.length + 1;
    while (true) {
      final id = 'HU${nextNum.toString().padLeft(3, '0')}';
      if (!_hutangUsahas.any((e) => e.id == id)) {
        return id;
      }
      nextNum++;
    }
  }

  String generateHutangUsahaNumber() {
    int nextNum = _hutangUsahas.length + 1;
    while (true) {
      final numStr = 'HTGU-2026-${nextNum.toString().padLeft(3, '0')}';
      if (!_hutangUsahas.any((e) => e.number == numStr)) {
        return numStr;
      }
      nextNum++;
    }
  }

  String generateFinancialEntryId() {
    int nextNum = _financialEntries.length + 1;
    while (true) {
      final id = 'F${nextNum.toString().padLeft(3, '0')}';
      if (!_financialEntries.any((e) => e.id == id)) {
        return id;
      }
      nextNum++;
    }
  }
}
