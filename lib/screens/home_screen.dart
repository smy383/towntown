import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              // 시스템 설정 옵션
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
              // 각 언어 옵션
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

  void _showSettings(BuildContext context) {
    final l10n = L10n.of(context)!;

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
                l10n.settings,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: Text(
                  l10n.myInfo,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 내 정보 화면으로 이동
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.white70),
                title: Text(
                  l10n.language,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: Text(
                  _getCurrentLanguageName(context),
                  style: TextStyle(color: Colors.grey[400]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageSelector(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  l10n.logout,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLogout(context);
                },
              ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'NEON',
                style: TextStyle(
                  color: Colors.purpleAccent[100],
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.purpleAccent.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                    Shadow(
                      color: Colors.purpleAccent.withOpacity(0.6),
                      blurRadius: 20,
                    ),
                    Shadow(
                      color: Colors.purpleAccent.withOpacity(0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'TOWN',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.6),
                      blurRadius: 20,
                    ),
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // 환영 메시지
              Text(
                l10n.homeWelcome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.homeSubtitle,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // 마을 만들기 버튼
              _MenuCard(
                icon: Icons.add_home_outlined,
                title: l10n.createVillage,
                subtitle: l10n.createVillageDesc,
                color: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.comingSoon)),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 마을 탐험 버튼
              _MenuCard(
                icon: Icons.explore_outlined,
                title: l10n.exploreVillage,
                subtitle: l10n.exploreVillageDesc,
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.comingSoon)),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 내 마을 버튼
              _MenuCard(
                icon: Icons.home_outlined,
                title: l10n.myVillage,
                subtitle: l10n.myVillageDesc,
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.comingSoon)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
