import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/features/auth/providers/auth_provider.dart';
import 'package:openlist/features/auth/providers/profile_provider.dart';
import 'package:openlist/core/providers/theme_provider.dart';
import 'package:openlist/data/sync/sync_manager.dart';
import 'package:openlist/features/settings/presentation/ai_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Your data will be synced to the cloud before signing out.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      setState(() {
        _isSigningOut = true;
      });

      try {
        // Show syncing message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Syncing your data...'),
                ],
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }

        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        
        if (mounted) {
          ref.read(currentUserProvider.notifier).state = null;
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSigningOut = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _showManageProfileDialog(BuildContext context, bool isDarkMode, dynamic currentUser, AsyncValue profileAsync) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Manage Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        content: profileAsync.when(
          data: (profile) {
            final email = currentUser?.email ?? 'N/A';
            final displayName = profile?.displayName ?? email.split('@')[0];
            final plan = 'Free'; // Default plan, can be extended later
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileInfoRow(
                  isDarkMode: isDarkMode,
                  label: 'Name',
                  value: displayName,
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(
                  isDarkMode: isDarkMode,
                  label: 'Email',
                  value: email,
                  icon: Icons.email,
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(
                  isDarkMode: isDarkMode,
                  label: 'Plan',
                  value: plan,
                  icon: Icons.workspace_premium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await ref.read(profileNotifierProvider.notifier).sendPasswordReset(email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Password reset email sent to $email'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Reset Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Text(
            'Error loading profile: $error',
            style: GoogleFonts.inter(
              color: AppColors.danger,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow({
    required bool isDarkMode,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileNotifierProvider);
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            Text(
              'APPEARANCE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.dark_mode_outlined,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryLight,
                    title: 'Dark Mode',
                    subtitle: 'Switch between light and dark theme',
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).setTheme(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value 
                                  ? '🌙 Dark mode enabled' 
                                  : '☀️ Light mode enabled',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      activeColor: AppColors.primary,
                    ),
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // AI Section
            Text(
              'AI FEATURES',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.auto_awesome,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryLight,
                    title: 'AI Extraction',
                    subtitle: 'Configure AI-powered task extraction',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AISettingsScreen(),
                        ),
                      );
                    },
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notifications Section
            Text(
              'NOTIFICATIONS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.warning,
                    iconBg: AppColors.warningLight,
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on this device',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _notificationsEnabled 
                                  ? '🔔 Notifications enabled' 
                                  : '🔕 Notifications disabled',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      activeColor: AppColors.primary,
                    ),
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Section
            Text(
              'ACCOUNT',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.person_outline,
                    iconColor: AppColors.success,
                    iconBg: AppColors.successLight,
                    title: 'Manage Profile',
                    subtitle: 'View your account details',
                    trailing: Icon(
                      Icons.chevron_right, 
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                    onTap: () {
                      _showManageProfileDialog(context, isDarkMode, currentUser, profileAsync);
                    },
                    isDarkMode: isDarkMode,
                  ),
                  Divider(
                    height: 1, 
                    color: isDarkMode ? AppColors.borderDark : AppColors.border,
                  ),
                  _buildSettingTile(
                    icon: Icons.sync,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryLight,
                    title: 'Sync Now',
                    subtitle: 'Manually sync your data',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                    onTap: () async {
                      await SyncManager.instance.triggerSync();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔄 Syncing...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    isDarkMode: isDarkMode,
                  ),
                  Divider(
                    height: 1, 
                    color: isDarkMode ? AppColors.borderDark : AppColors.border,
                  ),
                  _buildSettingTile(
                    icon: Icons.logout,
                    iconColor: AppColors.danger,
                    iconBg: AppColors.dangerLight,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    trailing: _isSigningOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.chevron_right, 
                            color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                          ),
                    onTap: _isSigningOut ? null : _handleSignOut,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'OpenList',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget trailing,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}
