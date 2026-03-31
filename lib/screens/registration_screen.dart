import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../l10n/app_strings.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _fullPhoneNumber = '';
  String? _selectedEventId;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _db.getEvents();
    if (mounted) setState(() => _events = events);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(S s) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _db.addAttendee(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _fullPhoneNumber,
        null,
        null,
        _selectedEventId,
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                Text(s.registrationSuccess,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                const SizedBox(height: 8),
                Text(s.welcomeMessage),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(s.ok),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        final s = S(lang);

        return Scaffold(
          body: Container(
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
              child: Column(
                children: [
                  // Dil toggle — sağ üst
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, right: 16),
                      child: _LanguageToggle(),
                    ),
                  ),
                  // Form içeriği — ortalanmış
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isDesktop ? 500 : double.infinity),
                          child: Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                              side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Logo
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Theme.of(context).colorScheme.primary, width: 3),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: Image.asset('assets/new_logo_1.png', fit: BoxFit.contain),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayLarge
                                            ?.copyWith(fontSize: 32),
                                        children: const [
                                          TextSpan(text: 'United '),
                                          TextSpan(
                                              text: 'Istanbul',
                                              style: TextStyle(color: Color(0xFFD4AF37))),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      s.reservationForm,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.6), fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),

                                    // Ad
                                    TextFormField(
                                      controller: _firstNameController,
                                      decoration: InputDecoration(
                                        labelText: s.firstName,
                                        prefixIcon: const Icon(Icons.person),
                                      ),
                                      textInputAction: TextInputAction.next,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty ? s.firstNameRequired : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // Soyad
                                    TextFormField(
                                      controller: _lastNameController,
                                      decoration: InputDecoration(
                                        labelText: s.lastName,
                                        prefixIcon: const Icon(Icons.person_outline),
                                      ),
                                      textInputAction: TextInputAction.next,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty ? s.lastNameRequired : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // Telefon
                                    IntlPhoneField(
                                      decoration: InputDecoration(
                                        labelText: s.phoneNumber,
                                        border: const OutlineInputBorder(
                                            borderSide: BorderSide()),
                                      ),
                                      initialCountryCode: 'TR',
                                      languageCode: lang,
                                      onChanged: (phone) =>
                                          _fullPhoneNumber = phone.completeNumber,
                                      onSubmitted: (_) => _submitForm(s),
                                    ),
                                    const SizedBox(height: 16),

                                    // Etkinlik
                                    if (_events.isEmpty)
                                      const Center(child: CircularProgressIndicator())
                                    else
                                      DropdownButtonFormField<String>(
                                        value: _selectedEventId,
                                        decoration: InputDecoration(
                                          labelText: s.selectEvent,
                                          prefixIcon: const Icon(Icons.event),
                                        ),
                                        items: _events.map((event) {
                                          final date = event['event_date'] != null
                                              ? () {
                                                  try {
                                                    final d = DateTime.parse(
                                                            event['event_date'].toString())
                                                        .toLocal();
                                                    return ' — ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
                                                  } catch (_) {
                                                    return '';
                                                  }
                                                }()
                                              : '';
                                          return DropdownMenuItem<String>(
                                            value: event['id'].toString(),
                                            child: Text('${event['name']}$date'),
                                          );
                                        }).toList(),
                                        onChanged: (v) =>
                                            setState(() => _selectedEventId = v),
                                        validator: (v) =>
                                            v == null ? s.eventRequired : null,
                                      ),
                                    if (_selectedEventId != null) ...[
                                      Builder(builder: (_) {
                                        final selected = _events.firstWhere(
                                          (e) => e['id'].toString() == _selectedEventId,
                                          orElse: () => {},
                                        );
                                        final desc = selected['description']?.toString() ?? '';
                                        if (desc.isEmpty) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Text(
                                            desc,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              height: 1.5,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                    const SizedBox(height: 32),

                                    // Gönder
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : () => _submitForm(s),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15)),
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : Text(s.createReservation,
                                                style: const TextStyle(
                                                    fontSize: 18, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Footer
                                    GestureDetector(
                                      onTap: () async {
                                        final Uri url = Uri.parse('https://danceschoolapp.com');
                                        if (!await launchUrl(url)) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Site açılamadı')));
                                          }
                                        }
                                      },
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: Colors.white54, fontSize: 13),
                                          children: [
                                            TextSpan(text: '${s.madeBy} '),
                                            TextSpan(
                                              text: 'danceschoolapp.com',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            if (s.madeByEnd.isNotEmpty)
                                              TextSpan(text: ' ${s.madeByEnd}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
              border:
                  Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang == 'tr' ? '🇹🇷' : '🇬🇧', style: const TextStyle(fontSize: 16)),
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
