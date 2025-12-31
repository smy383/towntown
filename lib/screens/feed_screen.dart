import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 48,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.feedEmpty,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.feedEmptyDesc,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
