import 'package:flutter/material.dart';

import '../models/bon.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/product_item.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/customers/customer_form_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/main_shell.dart';
import '../screens/products/product_form_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/transactions/bon_detail_screen.dart';
import '../screens/transactions/bon_form_screen.dart';
import '../screens/transactions/invoice_detail_screen.dart';
import '../screens/transactions/invoice_form_screen.dart';
import '../screens/transactions/hutang_usaha_detail_screen.dart';
import '../screens/transactions/hutang_usaha_form_screen.dart';
import '../screens/finance/financial_entry_detail_screen.dart';
import '../models/hutang_usaha.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const shell = '/shell';
  static const customerForm = '/customer/form';
  static const customerDetail = '/customer/detail';
  static const productForm = '/product/form';
  static const productDetail = '/product/detail';
  static const invoiceForm = '/invoice/form';
  static const invoiceDetail = '/invoice/detail';
  static const bonForm = '/bon/form';
  static const bonDetail = '/bon/detail';
  static const String hutangUsahaForm = '/hutang-usaha-form';
  static const String financialEntryDetail = '/financial-entry-detail';
  static const hutangUsahaDetail = '/hutang-usaha/detail';
  static const finance = '/finance';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(settings, const LoginScreen());
      case register:
        return _buildRoute(settings, const RegisterScreen());
      case forgotPassword:
        return _buildRoute(settings, const ForgotPasswordScreen());
      case shell:
        final initialIndex = settings.arguments as int? ?? 0;
        return _buildRoute(
          settings,
          MainShell(initialIndex: initialIndex),
        );
      case finance:
        return _buildRoute(
          settings,
          const MainShell(initialIndex: 2),
        );
      case customerForm:
        final customer = settings.arguments as Customer?;
        return _buildRoute(
          settings,
          CustomerFormScreen(customer: customer),
        );
      case customerDetail:
        final customer = settings.arguments as Customer;
        return _buildRoute(
          settings,
          CustomerDetailScreen(customer: customer),
        );
      case productForm:
        final product = settings.arguments as ProductItem?;
        return _buildRoute(
          settings,
          ProductFormScreen(product: product),
        );
      case productDetail:
        final product = settings.arguments as ProductItem;
        return _buildRoute(
          settings,
          ProductDetailScreen(product: product),
        );
      case invoiceForm:
        final invoice = settings.arguments as Invoice?;
        return _buildRoute(
          settings,
          InvoiceFormScreen(invoice: invoice),
        );
      case invoiceDetail:
        final invoiceId = settings.arguments as String;
        return _buildRoute(
          settings,
          InvoiceDetailScreen(invoiceId: invoiceId),
        );
      case bonForm:
        final bon = settings.arguments as Bon?;
        return _buildRoute(
          settings,
          BonFormScreen(bon: bon),
        );
      case bonDetail:
        final bonId = settings.arguments as String;
        return _buildRoute(
          settings,
          BonDetailScreen(bonId: bonId),
        );
      case hutangUsahaForm:
        final hutangUsaha = settings.arguments as HutangUsaha?;
        return _buildRoute(
          settings,
          HutangUsahaFormScreen(hutangUsaha: hutangUsaha),
        );
      case hutangUsahaDetail:
        final hutangUsahaId = settings.arguments as String;
        return _buildRoute(
          settings,
          HutangUsahaDetailScreen(hutangUsahaId: hutangUsahaId),
        );
      case financialEntryDetail:
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => FinancialEntryDetailScreen(id: args as String),
        );
      default:
        return _buildRoute(settings, const LoginScreen());
    }
  }

  static Future<T?> push<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> replace<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static PageRouteBuilder<dynamic> _buildRoute(
    RouteSettings settings,
    Widget page,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: page,
      ),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 220),
    );
  }
}
