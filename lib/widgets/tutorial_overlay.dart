import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

const List<TutorialStep> kTutorialSteps = [
  TutorialStep(
    icon: Icons.waving_hand_rounded,
    title: 'Selamat datang di FinTrack! 🎉',
    description:
        'Aplikasi pencatat invoice, bon, dan keuangan usaha Anda. Kami akan tunjukkan cara menggunakan fitur-fitur utamanya.',
    accentColor: Color(0xFF6366F1),
  ),
  TutorialStep(
    icon: Icons.dashboard_rounded,
    title: 'Dashboard Usaha',
    description:
        'Di sini Anda bisa melihat ringkasan total invoice, bon, saldo kas, dan transaksi terbaru dalam satu tampilan.',
    accentColor: Color(0xFF8B5CF6),
  ),
  TutorialStep(
    icon: Icons.add_card_rounded,
    title: 'Buat Invoice & Bon',
    description:
        'Tap tombol "Buat Invoice Baru" atau "Tambah Bon" untuk mencatat tagihan atau piutang pelanggan. Mudah dan cepat!',
    accentColor: Color(0xFF14B8A6),
  ),
  TutorialStep(
    icon: Icons.account_balance_wallet_rounded,
    title: 'Pantau Keuangan',
    description:
        'Menu Keuangan menampilkan pemasukan, pengeluaran, dan laporan yang bisa diekspor ke PDF untuk pembukuan.',
    accentColor: Color(0xFFF59E0B),
  ),
  TutorialStep(
    icon: Icons.people_alt_rounded,
    title: 'Pelanggan & Barang',
    description:
        'Kelola data pelanggan dan stok barang Anda. Semua data tersinkron aman ke Firebase Cloud secara real-time.',
    accentColor: Color(0xFF10B981),
  ),
];

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const TutorialOverlay({super.key, required this.onDone});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _slideController;
  late AnimationController _iconController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconPulseAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _iconPulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentStep < kTutorialSteps.length - 1) {
      _slideController.reset();
      setState(() => _currentStep++);
      _slideController.forward();
    } else {
      _done();
    }
  }

  void _done() {
    HapticFeedback.mediumImpact();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final step = kTutorialSteps[_currentStep];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // Background gradient orb
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.accentColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.accentColor.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceContainerDark
                          : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: step.accentColor.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: -5,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Step indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            kTutorialSteps.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _currentStep ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _currentStep
                                    ? step.accentColor
                                    : step.accentColor.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Animated icon
                        ScaleTransition(
                          scale: _iconPulseAnimation,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  step.accentColor.withValues(alpha: 0.15),
                                  step.accentColor.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: step.accentColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: ScaleTransition(
                              scale: _iconScaleAnimation,
                              child: Icon(
                                step.icon,
                                size: 44,
                                color: step.accentColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Title
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                              ),
                        ),
                        const SizedBox(height: 32),

                        // Buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: step.accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _currentStep < kTutorialSteps.length - 1
                                  ? 'Lanjut →'
                                  : 'Mulai Sekarang! 🚀',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        if (_currentStep < kTutorialSteps.length - 1) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _done,
                            child: Text(
                              'Lewati Tutorial',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.mutedTextDark
                                    : AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
