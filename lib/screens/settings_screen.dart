import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _getCurrentLanguageName(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = L10n.of(context)!;

    if (localeProvider.locale == null) {
      return l10n.languageSystem;
    }

    return LocaleProvider.getLanguageName(localeProvider.locale!.languageCode);
  }

  void _showLanguageSelector(BuildContext context) {
    final l10n = L10n.of(context)!;
    final localeProvider = context.read<LocaleProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                l10n.languageSelect,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text('🌐', style: TextStyle(fontSize: 24)),
                title: Text(
                  l10n.languageSystem,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: localeProvider.locale == null
                    ? const Icon(Icons.check, color: Colors.cyanAccent)
                    : null,
                onTap: () {
                  localeProvider.clearLocale();
                  Navigator.pop(context);
                },
              ),
              ...LocaleProvider.supportedLocales.map((locale) => ListTile(
                    leading: Text(
                      LocaleProvider.getLanguageFlag(locale.languageCode),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      LocaleProvider.getLanguageName(locale.languageCode),
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: localeProvider.locale?.languageCode ==
                            locale.languageCode
                        ? const Icon(Icons.check, color: Colors.cyanAccent)
                        : null,
                    onTap: () {
                      localeProvider.setLocale(locale);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = L10n.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          l10n.logout,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.logoutConfirm,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.person,
                  iconColor: Colors.cyanAccent,
                  title: l10n.myInfo,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.comingSoon)),
                    );
                  },
                ),
                const Divider(color: Colors.grey, height: 1),
                _SettingsTile(
                  icon: Icons.language,
                  iconColor: Colors.cyanAccent,
                  title: l10n.language,
                  trailing: Text(
                    _getCurrentLanguageName(context),
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  onTap: () => _showLanguageSelector(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.logout,
                  iconColor: Colors.redAccent,
                  title: l10n.logout,
                  titleColor: Colors.redAccent,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: Colors.grey[600],
          ),
      onTap: onTap,
    );
  }
}
