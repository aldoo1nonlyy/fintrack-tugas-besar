import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bon.dart';
import '../models/business_profile.dart';
import '../models/customer.dart';
import '../models/financial_entry.dart';
import '../models/hutang_usaha.dart';
import '../models/invoice.dart';
import '../models/product_item.dart';
import '../models/transaction_status.dart';

class StorageService {
  static const String _keyCustomers = 'customers_data';
  static const String _keyProducts = 'products_data';
  static const String _keyInvoices = 'invoices_data';
  static const String _keyBons = 'bons_data';
  static const String _keyHutangUsahas = 'hutang_usahas_data';
  static const String _keyFinancialEntries = 'financial_entries_data';
  static const String _keyProfile = 'business_profile_data';

  final SharedPreferences prefs;

  StorageService(this.prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- SAVE METHODS ---

  Future<void> saveCustomers(List<Customer> list) async {
    final jsonList = list.map((e) => {
      'id': e.id,
      'name': e.name,
      'phone': e.phone,
      'address': e.address,
      'email': e.email,
    }).toList();
    await prefs.setString(_keyCustomers, jsonEncode(jsonList));
  }

  Future<void> saveProducts(List<ProductItem> list) async {
    final jsonList = list.map((e) => {
      'id': e.id,
      'name': e.name,
      'price': e.price,
      'category': e.category,
    }).toList();
    await prefs.setString(_keyProducts, jsonEncode(jsonList));
  }

  Future<void> saveInvoices(List<Invoice> list) async {
    final jsonList = list.map((e) => {
      'id': e.id,
      'number': e.number,
      'customerId': e.customerId,
      'customerName': e.customerName,
      'date': e.date.toIso8601String(),
      'items': e.items.map((i) => {
        'id': i.id,
        'itemName': i.itemName,
        'qty': i.qty,
        'price': i.price,
      }).toList(),
      'notes': e.notes,
      'status': e.status.index,
    }).toList();
    await prefs.setString(_keyInvoices, jsonEncode(jsonList));
  }

  Future<void> saveBons(List<Bon> list) async {
    final jsonList = list.map((e) => {
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
    }).toList();
    await prefs.setString(_keyBons, jsonEncode(jsonList));
  }

  Future<void> saveHutangUsahas(List<HutangUsaha> list) async {
    final jsonList = list.map((e) => {
      'id': e.id,
      'number': e.number,
      'supplierName': e.supplierName,
      'amount': e.amount,
      'date': e.date.toIso8601String(),
      'notes': e.notes,
      'status': e.status.index,
    }).toList();
    await prefs.setString(_keyHutangUsahas, jsonEncode(jsonList));
  }

  Future<void> saveFinancialEntries(List<FinancialEntry> list) async {
    final jsonList = list.map((e) => {
      'id': e.id,
      'title': e.title,
      'description': e.description,
      'amount': e.amount,
      'date': e.date.toIso8601String(),
      'type': e.type.index,
      'sourceLabel': e.sourceLabel,
      'sourceId': e.sourceId,
      'status': e.status?.index,
    }).toList();
    await prefs.setString(_keyFinancialEntries, jsonEncode(jsonList));
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    final jsonMap = {
      'businessName': profile.businessName,
      'address': profile.address,
      'phone': profile.phone,
      'invoiceFooter': profile.invoiceFooter,
    };
    await prefs.setString(_keyProfile, jsonEncode(jsonMap));
  }

  Future<void> clearAll() async {
    await prefs.remove(_keyCustomers);
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyInvoices);
    await prefs.remove(_keyBons);
    await prefs.remove(_keyHutangUsahas);
    await prefs.remove(_keyFinancialEntries);
    await prefs.remove(_keyProfile);
  }

  // --- LOAD METHODS ---

  List<Customer> loadCustomers() {
    final str = prefs.getString(_keyCustomers);
    if (str == null) return [];
    final List<dynamic> jsonList = jsonDecode(str);
    return jsonList.map((e) => Customer(
      id: e['id'],
      name: e['name'],
      phone: e['phone'],
      address: e['address'],
      email: e['email'],
    )).toList();
  }

  List<ProductItem> loadProducts() {
    final str = prefs.getString(_keyProducts);
    if (str == null) return [];
    final List<dynamic> jsonList = jsonDecode(str);
    return jsonList.map((e) => ProductItem(
      id: e['id'],
      name: e['name'],
      price: (e['price'] as num).toDouble(),
      category: e['category'],
    )).toList();
  }

  List<Invoice> loadInvoices() {
    final str = prefs.getString(_keyInvoices);
    if (str == null) return [];
    final List<dynamic> jsonList = jsonDecode(str);
    return jsonList.map((e) => Invoice(
      id: e['id'],
      number: e['number'],
      customerId: e['customerId'],
      customerName: e['customerName'],
      date: DateTime.parse(e['date']),
      notes: e['notes'],
      status: TransactionStatus.values[e['status'] as int],
      items: (e['items'] as List<dynamic>).map((i) => InvoiceLine(
        id: i['id'],
        itemName: i['itemName'],
        qty: i['qty'] as int,
        price: (i['price'] as num).toDouble(),
      )).toList(),
    )).toList();
  }

  List<Bon> loadBons() {
    final str = prefs.getString(_keyBons);
    if (str == null) return [];
    final jsonList = jsonDecode(str) as List<dynamic>;
    return jsonList.map((e) => Bon(
      id: e['id'] as String,
      customerName: e['customerName'] as String,
      amount: (e['amount'] as num).toDouble(),
      date: DateTime.parse(e['date'] as String),
      notes: e['notes'] as String,
      status: TransactionStatus.values[e['status'] as int],
      items: e['items'] == null ? <BonLine>[] : (e['items'] as List<dynamic>).map((i) => BonLine(
        id: i['id'] as String,
        itemName: i['itemName'] as String,
        qty: i['qty'] as int,
        price: (i['price'] as num).toDouble(),
      )).toList(),
    )).toList();
  }

  List<HutangUsaha> loadHutangUsahas() {
    final str = prefs.getString(_keyHutangUsahas);
    if (str == null) return [];
    final List<dynamic> jsonList = jsonDecode(str);
    return jsonList.map((e) => HutangUsaha(
      id: e['id'],
      number: e['number'],
      supplierName: e['supplierName'],
      amount: (e['amount'] as num).toDouble(),
      date: DateTime.parse(e['date']),
      notes: e['notes'],
      status: TransactionStatus.values[e['status'] as int],
    )).toList();
  }

  List<FinancialEntry> loadFinancialEntries() {
    final str = prefs.getString(_keyFinancialEntries);
    if (str == null) return [];
    final List<dynamic> jsonList = jsonDecode(str);
    return jsonList.map((e) => FinancialEntry(
      id: e['id'],
      title: e['title'],
      description: e['description'],
      amount: (e['amount'] as num).toDouble(),
      date: DateTime.parse(e['date']),
      type: FinancialEntryType.values[e['type'] as int],
      sourceLabel: e['sourceLabel'] ?? 'Manual',
      sourceId: e['sourceId'],
      status: e['status'] != null ? TransactionStatus.values[e['status'] as int] : null,
    )).toList();
  }

  BusinessProfile? loadProfile() {
    final str = prefs.getString(_keyProfile);
    if (str == null) return null;
    final Map<String, dynamic> map = jsonDecode(str);
    return BusinessProfile(
      businessName: map['businessName'],
      address: map['address'],
      phone: map['phone'],
      invoiceFooter: map['invoiceFooter'],
    );
  }
}
