import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';

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
  
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _db.addAttendee(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _fullPhoneNumber,
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
                Text(
                  'Kayıt Başarılı!',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                const Text('Dans gecemize hoş geldiniz.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to welcome screen
                  },
                  child: const Text('Tamam'),
                )
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

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
                          // Header (Logo + Title)
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
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
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                              children: const [
                                TextSpan(text: 'United '),
                                TextSpan(text: 'Istanbul', style: TextStyle(color: Color(0xFFD4AF37))),
                              ],
                            ),
                          ),
                          Text(
                            '',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rezervasyon Formu',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Form Fields
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'Adınız', prefixIcon: Icon(Icons.person)),
                            textInputAction: TextInputAction.next,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Lütfen adınızı girin' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Soyadınız', prefixIcon: Icon(Icons.person_outline)),
                            textInputAction: TextInputAction.next,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Lütfen soyadınızı girin' : null,
                          ),
                          const SizedBox(height: 16),
                          IntlPhoneField(
                            decoration: const InputDecoration(
                              labelText: 'Telefon Numaranız',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(),
                              ),
                            ),
                            initialCountryCode: 'TR',
                            languageCode: "tr",
                            onChanged: (phone) {
                              _fullPhoneNumber = phone.completeNumber;
                            },
                            onSubmitted: (_) => _submitForm(),
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Randevu Oluştur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Footer Link
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final Uri url = Uri.parse('https://danceschoolapp.com');
                                if (!await launchUrl(url)) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site açılamadı')));
                                  }
                                }
                              },
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54, fontSize: 13),
                                  children: [
                                    const TextSpan(text: 'Bu uygulama '),
                                    TextSpan(
                                      text: 'danceschoolapp.com',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(text: ' tarafından yapılmıştır'),
                                  ],
                                ),
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
      ),
    );
  }
}
