import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final _client = Supabase.instance.client;

  // READ All
  Stream<List<Map<String, dynamic>>> getAttendeesStream() {
    return _client.from('attendees').stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  // GET EVENTS (active only, for dropdowns)
  Future<List<Map<String, dynamic>>> getEvents() async {
    final response = await _client
        .from('events')
        .select()
        .eq('is_active', true)
        .order('event_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // GET EVENTS STREAM (all, for admin panel)
  Stream<List<Map<String, dynamic>>> getEventsStream() {
    return _client.from('events').stream(primaryKey: ['id']).order('event_date', ascending: true);
  }

  // ADD EVENT
  Future<void> addEvent(String name, DateTime? eventDate, String? description) async {
    await _client.from('events').insert({
      'name': name,
      if (eventDate != null) 'event_date': eventDate.toUtc().toIso8601String(),
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }

  // UPDATE EVENT
  Future<void> updateEvent(String id, String name, DateTime? eventDate, String? description, bool isActive) async {
    await _client.from('events').update({
      'name': name,
      'event_date': eventDate?.toUtc().toIso8601String(),
      'description': description,
      'is_active': isActive,
    }).eq('id', id);
  }

  // TOGGLE EVENT ACTIVE
  Future<void> toggleEventActive(String id, bool currentState) async {
    await _client.from('events').update({'is_active': !currentState}).eq('id', id);
  }

  // DELETE EVENT
  Future<void> deleteEvent(String id) async {
    await _client.from('attendees').update({'event_id': null}).eq('event_id', id);
    await _client.from('events').delete().eq('id', id);
  }

  // CREATE
  Future<void> addAttendee(String firstName, String lastName, String phone, [String? schoolName, String? instructorName, String? eventId]) async {
    await _client.from('attendees').insert({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      if (schoolName != null && schoolName.isNotEmpty) 'school_name': schoolName,
      if (instructorName != null && instructorName.isNotEmpty) 'instructor_name': instructorName,
      if (eventId != null) 'event_id': eventId,
    });
  }

  // UPDATE
  Future<void> updateAttendee(String id, String firstName, String lastName, String phone, [String? schoolName, String? instructorName, String? eventId]) async {
    await _client.from('attendees').update({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'school_name': schoolName,
      'instructor_name': instructorName,
      'event_id': eventId,
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

  // TOGGLE CHECK-IN
  Future<void> toggleCheckIn(String id, bool currentState) async {
    await _client.from('attendees').update({
      'checked_in': !currentState,
    }).eq('id', id);
  }
}
