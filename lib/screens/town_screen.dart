import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class TownScreen extends StatelessWidget {
  const TownScreen({super.key});

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

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
