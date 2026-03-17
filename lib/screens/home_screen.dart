import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/database_service.dart';
import '../widgets/attendee_form_dialog.dart';
import 'registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = '';
  String _sortBy = 'Tarih (Yeniden Eskiye)';

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
            child: const Text('Sil')
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        await _db.deleteAttendee(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kişi silindi.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
        }
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
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Hayır', style: TextStyle(color: Colors.white70))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Evet')
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        await _db.toggleApproval(id, currentState);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kişinin onay durumu güncellendi.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _exportToExcel(List<Map<String, dynamic>> attendeesList) async {
    try {
      var excel = ex.Excel.createExcel();
      ex.Sheet sheetObject = excel['Katılımcılar'];
      excel.setDefaultSheet('Katılımcılar');

      // Add Headers
      sheetObject.appendRow([
        ex.TextCellValue('Ad'),
        ex.TextCellValue('Soyad'),
        ex.TextCellValue('Telefon'),
        ex.TextCellValue('Okul'),
        ex.TextCellValue('Eğitmen'),
        ex.TextCellValue('Onay Durumu'),
        ex.TextCellValue('Kayıt Tarihi'),
      ]);

      // Add Data
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

      if (kIsWeb) {
        // Web Download
        if (fileBytes != null) {
          final blob = html.Blob([fileBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", "latin_nation_katilimcilar.xlsx")
            ..click();
          html.Url.revokeObjectUrl(url);
        }
      } else {
        // Mobile/Desktop could use path_provider (omitted full logic here to keep focus on simple web/general usage assuming mostly web for admin right now, but simple to add)
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sadece web ortamında indirme şu an için aktiftir.')));
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel dışa aktarma hatası: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add constraints for web responsive layout
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
              constraints: const BoxConstraints(maxWidth: 1000), // Limit width on large screens
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/logo.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Latin Nation', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
                                    Text('Turkey', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isDesktop) ...[
                          IconButton(
                            onPressed: _showAddDialog,
                            icon: const Icon(Icons.add_circle, size: 48),
                            color: Theme.of(context).colorScheme.primary,
                          )
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Kayıt'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
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
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                if (value != null) {
                                  setState(() {
                                    _sortBy = value;
                                  });
                                }
                              },
                            ),
                          ),
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
                          return Center(child: Text('Bir hata oluştu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                        }
                        
                        var attendees = snapshot.data ?? [];
                        
                        // Apply search filter
                        if (_searchQuery.isNotEmpty) {
                          final query = _searchQuery.toLowerCase();
                          attendees = attendees.where((a) {
                            final fName = (a['first_name'] ?? '').toString().toLowerCase();
                            final lName = (a['last_name'] ?? '').toString().toLowerCase();
                            final school = (a['school_name'] ?? '').toString().toLowerCase();
                            return fName.contains(query) || lName.contains(query) || school.contains(query);
                          }).toList();
                        }

                        // Apply sorting
                        if (_sortBy == 'İsim (A-Z)') {
                          attendees.sort((a, b) => (a['first_name'] ?? '').toString().toLowerCase().compareTo((b['first_name'] ?? '').toString().toLowerCase()));
                        } else if (_sortBy == 'İsim (Z-A)') {
                          attendees.sort((a, b) => (b['first_name'] ?? '').toString().toLowerCase().compareTo((a['first_name'] ?? '').toString().toLowerCase()));
                        }
                        // Default is Date DESC which is already handled by descending stream, so no else needed.

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
                              padding: const EdgeInsets.only(right: 24.0, bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
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
                            Expanded(child: _buildAttendeesList(attendees, isDesktop)),
                          ],
                        );
                      },
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

  Widget _buildAttendeesList(List<Map<String, dynamic>> attendees, bool isDesktop) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: attendees.length,
      itemBuilder: (context, index) => _buildAttendeeCard(attendees[index]),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day.$month.$year $hour:$min';
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
      child: Center(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                attendee['first_name'].toString().isNotEmpty ? attendee['first_name'][0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          title: Text(
            '${attendee['first_name']} ${attendee['last_name']}', 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text(attendee['phone'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  ],
                ),
                if (attendee['school_name'] != null && attendee['school_name'].toString().isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school, size: 14, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text(attendee['school_name'], style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                if (attendee['instructor_name'] != null && attendee['instructor_name'].toString().isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_run, size: 14, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text(attendee['instructor_name'], style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                if (attendee['created_at'] != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text(_formatDate(attendee['created_at']), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),
          trailing: Row(
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
        ),
      ),
    );
  }
}
