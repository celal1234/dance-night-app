import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'registration_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        final s = S(lang);
        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Dil toggle — sağ üst köşe
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _LanguageToggle(),
                  ),
                  // İçerik
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset('assets/new_logo_1.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 32),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 42),
                            children: const [
                              TextSpan(text: 'United '),
                              TextSpan(text: 'Istanbul', style: TextStyle(color: Color(0xFFD4AF37))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.reservationForm,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
                        ),
                        const SizedBox(height: 64),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen()));
                                },
                                icon: const Icon(Icons.person_add_alt_1, size: 28),
                                label: Text(s.reservationForm, style: const TextStyle(fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        return GestureDetector(
          onTap: () => appLanguage.value = lang == 'tr' ? 'en' : 'tr',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang == 'tr' ? '🇹🇷' : '🇬🇧',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  S.toggleLabel(lang),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
