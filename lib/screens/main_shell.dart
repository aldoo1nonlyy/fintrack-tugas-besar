import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'customers/customer_screen.dart';
import 'finance/finance_screen.dart';
import 'home/home_screen.dart';
import 'products/product_screen.dart';
import 'profile/profile_screen.dart';
import 'transactions/transaction_screen.dart';

import '../utils/constants.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  late int _currentIndex;
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconScales;

  late final List<Widget> _screens = const [
    HomeScreen(),
    TransactionScreen(),
    FinanceScreen(),
    CustomerScreen(),
    ProductScreen(),
    ProfileScreen(),
  ];

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'Transaksi'),
    (icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet_rounded, label: 'Keuangan'),
    (icon: Icons.people_outline, selectedIcon: Icons.people_rounded, label: 'Pelanggan'),
    (icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'Barang'),
    (icon: Icons.storefront_outlined, selectedIcon: Icons.storefront_rounded, label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _iconControllers = List.generate(
      _destinations.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _iconScales = _iconControllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.35)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.35, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60,
        ),
      ]).animate(controller);
    }).toList();

    // Animate the initial selected tab
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconControllers[_currentIndex].forward(from: 0);
    });
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _iconControllers[index].forward(from: 0);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: AppShadows.softFloat,
              color: Theme.of(context).navigationBarTheme.backgroundColor ??
                  Theme.of(context).colorScheme.surface,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                onDestinationSelected: _onTabSelected,
                destinations: List.generate(
                  _destinations.length,
                  (i) {
                    final dest = _destinations[i];
                    return NavigationDestination(
                      icon: ScaleTransition(
                        scale: _iconScales[i],
                        child: Icon(dest.icon),
                      ),
                      selectedIcon: ScaleTransition(
                        scale: _iconScales[i],
                        child: Icon(dest.selectedIcon),
                      ),
                      label: dest.label,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
