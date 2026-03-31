import 'dart:async';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/database_service.dart';
import '../widgets/attendee_form_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;
  StreamSubscription? _eventsSubscription;

  // Attendees state
  String _searchQuery = '';
  String _sortBy = 'Tarih (Yeniden Eskiye)';
  String _checkInFilter = 'Tümü';
  String? _selectedEventFilter;
  Map<String, String> _eventNames = {};
  List<Map<String, dynamic>> _allEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Events stream'e abone ol — ekle/sil/güncelle anında yansısın
    _eventsSubscription = _db.getEventsStream().listen((events) {
      if (!mounted) return;
      final map = <String, String>{};
      for (final e in events) {
        map[e['id'].toString()] = e['name'].toString();
      }
      setState(() {
        _allEvents = events;
        _eventNames = map;
        // Seçili event silindiyse filtreyi sıfırla
        if (_selectedEventFilter != null && !map.containsKey(_selectedEventFilter)) {
          _selectedEventFilter = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Attendee methods ───────────────────────────────────────────────────────

  Future<void> _showAddDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AttendeeFormDialog(),
    );
    if (result != null) {
      try {
        await _db.addAttendee(
          result['first_name'],
          result['last_name'],
          result['phone'],
          result['school_name'],
          result['instructor_name'],
          result['event_id'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kişi başarıyla eklendi!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> attendee) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AttendeeFormDialog(attendee: attendee),
    );
    if (result != null) {
      try {
        await _db.updateAttendee(
          attendee['id'].toString(),
          result['first_name'],
          result['last_name'],
          result['phone'],
          result['school_name'],
          result['instructor_name'],
          result['event_id'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kişi başarıyla güncellendi!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _deleteAttendee(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Silmeyi Onayla'),
        content: const Text('Bu kişiyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _db.deleteAttendee(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kişi silindi.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _toggleApproval(String id, bool currentState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Ödeme Durumunu Değiştir'),
        content: const Text('Ödeme durumunu değiştirmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hayır', style: TextStyle(color: Colors.white70))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _db.toggleApproval(id, currentState);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Onay durumu güncellendi.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _toggleCheckIn(String id, bool currentState) async {
    try {
      await _db.toggleCheckIn(id, currentState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentState ? 'Katılımcı "gelmedi" olarak işaretlendi.' : '✅ Katılımcı geldi olarak işaretlendi!'),
            backgroundColor: currentState ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportToExcel(List<Map<String, dynamic>> attendeesList) async {
    try {
      var excel = ex.Excel.createExcel();
      ex.Sheet sheetObject = excel['Katılımcılar'];
      excel.setDefaultSheet('Katılımcılar');
      sheetObject.appendRow([
        ex.TextCellValue('Ad'),
        ex.TextCellValue('Soyad'),
        ex.TextCellValue('Telefon'),
        ex.TextCellValue('Okul'),
        ex.TextCellValue('Eğitmen'),
        ex.TextCellValue('Onay Durumu'),
        ex.TextCellValue('Kayıt Tarihi'),
      ]);
      for (var attendee in attendeesList) {
        sheetObject.appendRow([
          ex.TextCellValue(attendee['first_name']?.toString() ?? ''),
          ex.TextCellValue(attendee['last_name']?.toString() ?? ''),
          ex.TextCellValue(attendee['phone']?.toString() ?? ''),
          ex.TextCellValue(attendee['school_name']?.toString() ?? ''),
          ex.TextCellValue(attendee['instructor_name']?.toString() ?? ''),
          ex.TextCellValue(attendee['is_approved'] == true ? 'Onaylı' : 'Bekliyor'),
          ex.TextCellValue(attendee['created_at']?.toString() ?? ''),
        ]);
      }
      var fileBytes = excel.save();
      if (kIsWeb && fileBytes != null) {
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "latin_nation_katilimcilar.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel hatası: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── Event methods ───────────────────────────────────────────────────────────

  Future<void> _showAddEventDialog() async {
    final result = await _showEventFormDialog();
    if (result != null) {
      try {
        await _db.addEvent(result['name'], result['event_date'], result['description']);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etkinlik oluşturuldu!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _editEvent(Map<String, dynamic> event) async {
    final result = await _showEventFormDialog(event);
    if (result != null) {
      try {
        await _db.updateEvent(
          event['id'].toString(),
          result['name'],
          result['event_date'],
          result['description'],
          result['is_active'],
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etkinlik güncellendi!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Etkinliği Sil'),
        content: const Text('Bu etkinliği silmek istediğinize emin misiniz?\nBağlı kayıtlar etkinliksiz kalır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _db.deleteEvent(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etkinlik silindi.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<Map<String, dynamic>?> _showEventFormDialog([Map<String, dynamic>? event]) {
    final nameController = TextEditingController(text: event?['name'] ?? '');
    final descController = TextEditingController(text: event?['description'] ?? '');
    DateTime? selectedDate;
    if (event?['event_date'] != null) {
      selectedDate = DateTime.tryParse(event!['event_date'].toString());
    }
    bool isActive = event?['is_active'] ?? true;
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event == null ? 'Yeni Etkinlik' : 'Etkinliği Düzenle',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Etkinlik Adı', prefixIcon: Icon(Icons.event)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Etkinlik adı gerekli' : null,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(primary: Theme.of(context).colorScheme.primary),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setDialogState(() => selectedDate = picked);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white54, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedDate != null
                                    ? '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}'
                                    : 'Tarih Seçin (Opsiyonel)',
                                style: TextStyle(
                                  color: selectedDate != null ? Colors.white : Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (selectedDate != null)
                              GestureDetector(
                                onTap: () => setDialogState(() => selectedDate = null),
                                child: const Icon(Icons.clear, color: Colors.white38, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Açıklama (Opsiyonel)', prefixIcon: Icon(Icons.description)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.white54),
                        const SizedBox(width: 12),
                        const Text('Aktif', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const Spacer(),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setDialogState(() => isActive = v),
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('İptal', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(ctx, {
                                'name': nameController.text.trim(),
                                'event_date': selectedDate,
                                'description': descController.text.trim(),
                                'is_active': isActive,
                              });
                            }
                          },
                          child: Text(event == null ? 'Oluştur' : 'Güncelle'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset('assets/new_logo_1.png', fit: BoxFit.contain),
                              ),
                            ),
                            const SizedBox(width: 16),
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                                children: const [
                                  TextSpan(text: 'United '),
                                  TextSpan(text: 'Istanbul', style: TextStyle(color: Color(0xFFD4AF37))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Yeni Kayıt butonu (sadece Katılımcılar tab için)
                        isDesktop
                            ? ElevatedButton.icon(
                                onPressed: _showAddDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Yeni Kayıt'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                ),
                              )
                            : IconButton(
                                onPressed: _showAddDialog,
                                icon: const Icon(Icons.add_circle, size: 48),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      ],
                    ),
                  ),

                  // Tab bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(icon: Icon(Icons.people), text: 'Katılımcılar'),
                        Tab(icon: Icon(Icons.event), text: 'Etkinlikler'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildAttendeesTab(isDesktop),
                        _buildEventsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Attendees Tab ───────────────────────────────────────────────────────────

  Widget _buildAttendeesTab(bool isDesktop) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ad, soyad veya okul ismi ile ara...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        icon: const Icon(Icons.sort, color: Colors.white70),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        items: const [
                          DropdownMenuItem(value: 'Tarih (Yeniden Eskiye)', child: Text('Tarih (En Yeni)')),
                          DropdownMenuItem(value: 'İsim (A-Z)', child: Text('İsim (A-Z)')),
                          DropdownMenuItem(value: 'İsim (Z-A)', child: Text('İsim (Z-A)')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _sortBy = value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Etkinlik filtresi — her zaman göster
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedEventFilter != null
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
                            : Colors.white.withOpacity(0.1),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: _selectedEventFilter != null
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Theme.of(context).colorScheme.surface,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedEventFilter,
                        icon: Icon(
                          Icons.event,
                          color: _selectedEventFilter != null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white54,
                          size: 18,
                        ),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tüm Etkinlikler', style: TextStyle(color: Colors.white70)),
                          ),
                          ..._allEvents.map((e) {
                            final date = e['event_date'] != null
                                ? () { try { final d = DateTime.parse(e['event_date'].toString()).toLocal(); return ' — ${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}'; } catch(_) { return ''; } }()
                                : '';
                            return DropdownMenuItem<String?>(
                              value: e['id'].toString(),
                              child: Text('${e['name']}$date', style: const TextStyle(color: Colors.white)),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => _selectedEventFilter = value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _filterChip('Tümü', Icons.people, Colors.white70),
                  const SizedBox(width: 6),
                  _filterChip('Geldi', Icons.door_front_door, Colors.amber),
                  const SizedBox(width: 6),
                  _filterChip('Gelmedi', Icons.door_front_door_outlined, Colors.white30),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db.getAttendeesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              var attendees = snapshot.data ?? [];

              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                attendees = attendees.where((a) {
                  final fName = (a['first_name'] ?? '').toString().toLowerCase();
                  final lName = (a['last_name'] ?? '').toString().toLowerCase();
                  final school = (a['school_name'] ?? '').toString().toLowerCase();
                  final eventName = (a['event_id'] != null ? _eventNames[a['event_id'].toString()] ?? '' : '').toLowerCase();
                  return fName.contains(query) || lName.contains(query) || school.contains(query) || eventName.contains(query);
                }).toList();
              }

              if (_selectedEventFilter != null) {
                attendees = attendees.where((a) => a['event_id']?.toString() == _selectedEventFilter).toList();
              }

              if (_checkInFilter == 'Geldi') {
                attendees = attendees.where((a) => a['checked_in'] == true).toList();
              } else if (_checkInFilter == 'Gelmedi') {
                attendees = attendees.where((a) => a['checked_in'] != true).toList();
              }

              if (_sortBy == 'İsim (A-Z)') {
                attendees.sort((a, b) => (a['first_name'] ?? '').toString().toLowerCase().compareTo((b['first_name'] ?? '').toString().toLowerCase()));
              } else if (_sortBy == 'İsim (Z-A)') {
                attendees.sort((a, b) => (b['first_name'] ?? '').toString().toLowerCase().compareTo((a['first_name'] ?? '').toString().toLowerCase()));
              }

              if (attendees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('Henüz kayıtlı katılımcı yok.', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people, size: 18, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Toplam: ${attendees.length} kişi',
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _exportToExcel(attendees),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Excel\'e Aktar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: attendees.length,
                      itemBuilder: (context, index) => _buildAttendeeCard(attendees[index]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, IconData icon, Color activeColor) {
    final isSelected = _checkInFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _checkInFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor : Colors.white.withOpacity(0.15), width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildAttendeeCard(Map<String, dynamic> attendee) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  attendee['first_name'].toString().isNotEmpty ? attendee['first_name'][0].toUpperCase() : '?',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${attendee['first_name']} ${attendee['last_name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.phone, size: 13, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text(attendee['phone'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      ]),
                      if (attendee['school_name'] != null && attendee['school_name'].toString().isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.school, size: 13, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(attendee['school_name'], style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        ]),
                      if (attendee['instructor_name'] != null && attendee['instructor_name'].toString().isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.directions_run, size: 13, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(attendee['instructor_name'], style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        ]),
                      if (attendee['event_id'] != null && _eventNames.containsKey(attendee['event_id'].toString()))
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.event, size: 13, color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
                          const SizedBox(width: 6),
                          Text(_eventNames[attendee['event_id'].toString()]!,
                              style: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                        ]),
                      if (attendee['created_at'] != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.access_time, size: 13, color: Colors.white.withOpacity(0.4)),
                          const SizedBox(width: 6),
                          Text(_formatDate(attendee['created_at']), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        ]),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    attendee['is_approved'] == true ? Icons.check_circle : Icons.check_circle_outline,
                    color: attendee['is_approved'] == true ? Colors.green : Colors.white30,
                  ),
                  tooltip: attendee['is_approved'] == true ? 'Onayı Kaldır' : 'Onayla',
                  onPressed: () => _toggleApproval(attendee['id'].toString(), attendee['is_approved'] == true),
                ),
                IconButton(
                  icon: Icon(
                    attendee['checked_in'] == true ? Icons.door_front_door : Icons.door_front_door_outlined,
                    color: attendee['checked_in'] == true ? Colors.amber : Colors.white30,
                  ),
                  tooltip: attendee['checked_in'] == true ? 'Gelmedi' : 'Geldi',
                  onPressed: () => _toggleCheckIn(attendee['id'].toString(), attendee['checked_in'] == true),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  tooltip: 'Düzenle',
                  onPressed: () => _showEditDialog(attendee),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  tooltip: 'Sil',
                  onPressed: () => _deleteAttendee(attendee['id'].toString()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Events Tab ───────────────────────────────────────────────────────────────

  Widget _buildEventsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text('Henüz etkinlik yok.', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddEventDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('İlk Etkinliği Oluştur'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 8.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Toplam: ${events.length} etkinlik',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddEventDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Etkinlik'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: events.length,
                itemBuilder: (context, index) => _buildEventCard(events[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isActive = event['is_active'] == true;
    String dateStr = '';
    if (event['event_date'] != null) {
      try {
        final dt = DateTime.parse(event['event_date'].toString()).toLocal();
        dateStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.event, color: isActive ? Theme.of(context).colorScheme.primary : Colors.white38),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(event['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          isActive ? 'Aktif' : 'Pasif',
                          style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (dateStr.isNotEmpty || (event['description'] != null && event['description'].toString().isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (dateStr.isNotEmpty)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.calendar_today, size: 13, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          ]),
                        if (event['description'] != null && event['description'].toString().isNotEmpty)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.description, size: 13, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Text(event['description'], style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          ]),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  tooltip: 'Düzenle',
                  onPressed: () => _editEvent(event),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  tooltip: 'Sil',
                  onPressed: () => _deleteEvent(event['id'].toString()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
