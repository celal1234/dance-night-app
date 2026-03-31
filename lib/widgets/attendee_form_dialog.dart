import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/database_service.dart';

class AttendeeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? attendee; // null ise Ekle, değilse Düzenle modu

  const AttendeeFormDialog({super.key, this.attendee});

  @override
  State<AttendeeFormDialog> createState() => _AttendeeFormDialogState();
}

class _AttendeeFormDialogState extends State<AttendeeFormDialog> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _schoolNameController;
  late TextEditingController _instructorNameController;
  String _fullPhoneNumber = '';
  String? _selectedEventId;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.attendee?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.attendee?['last_name'] ?? '');
    _fullPhoneNumber = widget.attendee?['phone'] ?? '';
    _schoolNameController = TextEditingController(text: widget.attendee?['school_name'] ?? '');
    _instructorNameController = TextEditingController(text: widget.attendee?['instructor_name'] ?? '');
    _selectedEventId = widget.attendee?['event_id']?.toString();
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
    _schoolNameController.dispose();
    _instructorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.attendee != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Kişiyi Düzenle' : 'Yeni Kayıt Ekle',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person)),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ad gerekli' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Soyad gerekli' : null,
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(),
                    ),
                  ),
                  initialCountryCode: 'TR',
                  languageCode: "tr",
                  initialValue: _fullPhoneNumber.startsWith('+') ? null : _fullPhoneNumber, // Basic fallback
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _schoolNameController,
                  decoration: const InputDecoration(labelText: 'Okul İsmi (Opsiyonel)', prefixIcon: Icon(Icons.school)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructorNameController,
                  decoration: const InputDecoration(labelText: 'Eğitmen Adı (Opsiyonel)', prefixIcon: Icon(Icons.directions_run)),
                ),
                const SizedBox(height: 16),
                if (_events.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedEventId,
                    decoration: const InputDecoration(
                      labelText: 'Etkinlik (Opsiyonel)',
                      prefixIcon: Icon(Icons.event),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('— Seçilmedi —')),
                      ..._events.map((event) {
                        final date = event['event_date'] != null
                            ? () { try { final d = DateTime.parse(event['event_date'].toString()).toLocal(); return ' — ${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}'; } catch(_) { return ''; } }()
                            : '';
                        return DropdownMenuItem<String>(
                          value: event['id'].toString(),
                          child: Text('${event['name']}$date'),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() => _selectedEventId = value),
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'first_name': _firstNameController.text.trim(),
                            'last_name': _lastNameController.text.trim(),
                            'phone': _fullPhoneNumber,
                            'school_name': _schoolNameController.text.trim(),
                            'instructor_name': _instructorNameController.text.trim(),
                            'event_id': _selectedEventId,
                          });
                        }
                      },
                      child: Text(isEdit ? 'Güncelle' : 'Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
