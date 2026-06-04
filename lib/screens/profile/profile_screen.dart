import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/business_profile.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/tutorial_service.dart';
import '../../utils/constants.dart';
import '../../widgets/tutorial_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _footerController = TextEditingController();

  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _showTutorial = false;

  // Settings toggles
  bool _notifEnabled = false;

  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonScale;

  @override
  void initState() {
    super.initState();
    _saveButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _saveButtonScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _saveButtonController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    final profile = context.read<AppDataProvider>().businessProfile;
    _businessNameController.text = profile.businessName;
    _addressController.text = profile.address;
    _phoneController.text = profile.phone;
    _footerController.text = profile.invoiceFooter;
    _isInitialized = true;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    _saveButtonController.forward().then((_) => _saveButtonController.reverse());
    HapticFeedback.mediumImpact();

    final profile = BusinessProfile(
      businessName: _businessNameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      invoiceFooter: _footerController.text.trim(),
    );

    context.read<AppDataProvider>().updateBusinessProfile(profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil usaha berhasil disimpan ✅')),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await context.read<AppDataProvider>().refreshFromFirebase();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil disinkronisasi dari Firebase!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sinkronisasi gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    AppRoutes.replace(context, AppRoutes.login);
  }

  Future<void> _onTutorialToggle(bool value) async {
    HapticFeedback.selectionClick();
    if (value) {
      // Reset and show tutorial
      await TutorialService.resetTutorial();
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  Future<void> _onTutorialDone() async {
    await TutorialService.markTutorialSeen();
    if (mounted) setState(() => _showTutorial = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Profil Usaha'),
            actions: [
              IconButton(
                tooltip: 'Logout',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF111827), Color(0xFF374151)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identitas Usaha',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Atur nama usaha, alamat, nomor kontak, dan catatan footer invoice di sini.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Form profil usaha ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _businessNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nama usaha',
                              hintText: 'Contoh: Toko Sembako Berkah',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Nama usaha wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 3,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Alamat',
                              hintText: 'Contoh: Jl. Merdeka No. 12, Jakarta',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Alamat wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nomor telepon / WhatsApp',
                              hintText: 'Contoh: 081234567890',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Nomor telepon wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _footerController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Catatan footer invoice / bon',
                              hintText:
                                  'Contoh: Terima kasih atas kunjungannya',
                              prefixIcon: Icon(Icons.format_quote_rounded),
                              helperText:
                                  'Teks ini akan muncul di bagian bawah invoice & bon',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Pengaturan Aplikasi ──
                  const _SectionHeader(title: 'Pengaturan Aplikasi', icon: Icons.tune_rounded),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          // Dark Mode Toggle
                          _SettingsTile(
                            icon: Icons.dark_mode_rounded,
                            iconColor: const Color(0xFF6366F1),
                            title: 'Mode Gelap',
                            subtitle: 'Gunakan tema warna gelap',
                            value: context.watch<ThemeProvider>().isDarkMode,
                            onChanged: (isDarkOn) {
                              HapticFeedback.selectionClick();
                              context.read<ThemeProvider>().toggleTheme(isDarkOn);
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),

                          // Tutorial Toggle
                          _SettingsTile(
                            icon: Icons.school_rounded,
                            iconColor: const Color(0xFF14B8A6),
                            title: 'Tampilkan Tutorial',
                            subtitle: 'Buka kembali panduan penggunaan app',
                            value: false,
                            onChanged: _onTutorialToggle,
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),

                          // Notifikasi Toggle (UI placeholder)
                          _SettingsTile(
                            icon: Icons.notifications_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Notifikasi Transaksi',
                            subtitle: 'Pengingat tagihan yang belum lunas',
                            value: _notifEnabled,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _notifEnabled = val);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? 'Notifikasi diaktifkan'
                                        : 'Notifikasi dinonaktifkan',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Status Firebase Cloud ──
                  const _SectionHeader(
                      title: 'Sinkronisasi Cloud', icon: Icons.cloud_rounded),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cloud_done, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Firebase Cloud (Aktif)',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          Colors.green.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_circle_outlined,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Terhubung ke Firebase',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (auth.currentEmail != null)
                                            Text(
                                              auth.currentEmail!,
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Data Anda disimpan secara aman di Firestore dan ter-enkripsi per akun.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.mutedTextDark
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSyncing ? null : _syncNow,
                              icon: _isSyncing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(_isSyncing
                                  ? 'Mensinkronkan...'
                                  : 'Sinkronkan dari Cloud'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Tombol simpan ──
                  ScaleTransition(
                    scale: _saveButtonScale,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Simpan Profil'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),

        // Tutorial overlay (shown on top)
        if (_showTutorial)
          TutorialOverlay(onDone: _onTutorialDone),
      ],
    );
  }
}

// ── Helper Widgets ──

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: iconColor,
        activeTrackColor: iconColor.withValues(alpha: 0.4),
      ),
    );
  }
}
