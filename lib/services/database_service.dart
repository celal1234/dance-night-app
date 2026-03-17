import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final _client = Supabase.instance.client;

  // READ All
  Stream<List<Map<String, dynamic>>> getAttendeesStream() {
    return _client.from('attendees').stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  // CREATE (with newly added fields to the end so existing positional calls like registration form remain valid if we use them positionally, but let's change them to named or optional if needed... actually, it's better to add them as optional named parameters or just simple optional positional parameters since we don't want to break the registration form. Let's make them optional positional.)
  Future<void> addAttendee(String firstName, String lastName, String phone, [String? schoolName, String? instructorName]) async {
    await _client.from('attendees').insert({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      if (schoolName != null && schoolName.isNotEmpty) 'school_name': schoolName,
      if (instructorName != null && instructorName.isNotEmpty) 'instructor_name': instructorName,
    });
  }

  // UPDATE
  Future<void> updateAttendee(String id, String firstName, String lastName, String phone, [String? schoolName, String? instructorName]) async {
    await _client.from('attendees').update({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'school_name': schoolName,
      'instructor_name': instructorName,
    }).eq('id', id);
  }

  // DELETE
  Future<void> deleteAttendee(String id) async {
    await _client.from('attendees').delete().eq('id', id);
  }

  // TOGGLE APPROVAL
  Future<void> toggleApproval(String id, bool currentState) async {
    await _client.from('attendees').update({
      'is_approved': !currentState,
    }).eq('id', id);
  }
}
