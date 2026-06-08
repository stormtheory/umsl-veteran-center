// lib/shared/services/contacts_service.dart
//
// Loads assets/data/contacts.json once at startup.
// Every screen, widget, and service that needs a phone number,
// email address, office name, or URL pulls from here by ID.
//
// To update any contact info: edit contacts.json and rebuild.
// No Dart changes needed unless the schema itself changes.
//
// Usage:
//   final contacts = ref.watch(contactsProvider);
//   final vetCenter = contacts.office('vet_center');
//   final crisisLine = contacts.external('crisis_line');
//   final reportEmail = contacts.app.reportEmail;

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Address model
// ---------------------------------------------------------------------------
class OfficeAddress {
  final String building;
  final String room;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String full;
  final String? mapsUrl;

  const OfficeAddress({
    required this.building,
    required this.room,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.full,
    this.mapsUrl,
  });

  factory OfficeAddress.fromJson(Map<String, dynamic> j) => OfficeAddress(
        building: j['building'] as String? ?? '',
        room:     j['room'] as String? ?? '',
        street:   j['street'] as String? ?? '',
        city:     j['city'] as String? ?? '',
        state:    j['state'] as String? ?? '',
        zip:      j['zip'] as String? ?? '',
        full:     j['full'] as String? ?? '',
        mapsUrl:  j['maps_url'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Hours entry
// ---------------------------------------------------------------------------
class OfficeHours {
  final String days;
  final String hours;
  const OfficeHours({required this.days, required this.hours});

  factory OfficeHours.fromJson(Map<String, dynamic> j) => OfficeHours(
        days:  j['days'] as String,
        hours: j['hours'] as String,
      );
}

// ---------------------------------------------------------------------------
// Campus office (UMSL)
// ---------------------------------------------------------------------------
class OfficeContact {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final OfficeAddress address;
  final String phone;
  final String phoneTel;   // tel: URI for url_launcher
  final String email;
  final String website;
  final List<OfficeHours> hours;
  final String? notes;

  const OfficeContact({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.address,
    required this.phone,
    required this.phoneTel,
    required this.email,
    required this.website,
    required this.hours,
    this.notes,
  });

  factory OfficeContact.fromJson(Map<String, dynamic> j) => OfficeContact(
        id:          j['id'] as String,
        name:        j['name'] as String,
        shortName:   j['short_name'] as String,
        description: j['description'] as String? ?? '',
        address:     OfficeAddress.fromJson(j['address'] as Map<String, dynamic>),
        phone:       j['phone'] as String? ?? '',
        phoneTel:    j['phone_tel'] as String? ?? '',
        email:       j['email'] as String? ?? '',
        website:     j['website'] as String? ?? '',
        hours: (j['hours'] as List<dynamic>? ?? [])
            .map((h) => OfficeHours.fromJson(h as Map<String, dynamic>))
            .toList(),
        notes: j['notes'] as String?,
      );

  // Formatted hours as a single readable string
  String get hoursFormatted =>
      hours.map((h) => '${h.days}: ${h.hours}').join('\n');
}

// ---------------------------------------------------------------------------
// External resource (VA, crisis line, etc.)
// ---------------------------------------------------------------------------
class ExternalContact {
  final String id;
  final String name;
  final String shortName;
  final String phone;
  final String phoneTel;
  final String website;
  final String? notes;

  const ExternalContact({
    required this.id,
    required this.name,
    required this.shortName,
    required this.phone,
    required this.phoneTel,
    required this.website,
    this.notes,
  });

  factory ExternalContact.fromJson(Map<String, dynamic> j) => ExternalContact(
        id:        j['id'] as String,
        name:      j['name'] as String,
        shortName: j['short_name'] as String,
        phone:     j['phone'] as String? ?? '',
        phoneTel:  j['phone_tel'] as String? ?? '',
        website:   j['website'] as String? ?? '',
        notes:     j['notes'] as String?,
      );
}

// ---------------------------------------------------------------------------
// App-level contact config (report emails, subjects, body templates)
// ---------------------------------------------------------------------------
class AppContacts {
  final String reportEmail;
  final String reportSubjectTask;
  final String reportSubjectGeneral;
  final String reportBodyTask;
  final String reportBodyGeneral;

  const AppContacts({
    required this.reportEmail,
    required this.reportSubjectTask,
    required this.reportSubjectGeneral,
    required this.reportBodyTask,
    required this.reportBodyGeneral,
  });

  factory AppContacts.fromJson(Map<String, dynamic> j) => AppContacts(
        reportEmail:           j['report_email'] as String,
        reportSubjectTask:     j['report_subject_task'] as String,
        reportSubjectGeneral:  j['report_subject_general'] as String,
        reportBodyTask:        j['report_body_task'] as String,
        reportBodyGeneral:     j['report_body_general'] as String,
      );

  // Build the report body for a specific task, filling in the placeholders
  String buildTaskReportBody({
    required String taskTitle,
    required String benefitName,
    required String semesterLabel,
  }) =>
      reportBodyTask
          .replaceAll('{task_title}', taskTitle)
          .replaceAll('{benefit_name}', benefitName)
          .replaceAll('{semester_label}', semesterLabel);
}

// ---------------------------------------------------------------------------
// ContactsData — the top-level object returned by the provider
// ---------------------------------------------------------------------------
class ContactsData {
  final List<OfficeContact> offices;
  final List<ExternalContact> externalResources;
  final AppContacts app;

  const ContactsData({
    required this.offices,
    required this.externalResources,
    required this.app,
  });

  // Lookup an office by ID — returns null if not found
  OfficeContact? office(String id) =>
      offices.where((o) => o.id == id).isNotEmpty
          ? offices.firstWhere((o) => o.id == id)
          : null;

  // Lookup an external resource by ID — returns null if not found
  ExternalContact? external(String id) =>
      externalResources.where((e) => e.id == id).isNotEmpty
          ? externalResources.firstWhere((e) => e.id == id)
          : null;

  // Convenience getters for the most-used contacts
  OfficeContact? get vetCenter    => office('vet_center');
  OfficeContact? get registrar    => office('registrar');
  OfficeContact? get financialAid => office('financial_aid');
  OfficeContact? get bursar       => office('bursar');
  ExternalContact? get crisisLine => external('crisis_line');
  ExternalContact? get vaMain     => external('va_main');
  ExternalContact? get vaEducation => external('va_education');
}

// ---------------------------------------------------------------------------
// ContactsNotifier
// ---------------------------------------------------------------------------
class ContactsNotifier extends StateNotifier<AsyncValue<ContactsData>> {
  ContactsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/contacts.json');
      final j   = jsonDecode(raw) as Map<String, dynamic>;

      final data = ContactsData(
        offices: (j['offices'] as List<dynamic>)
            .map((o) => OfficeContact.fromJson(o as Map<String, dynamic>))
            .toList(),
        externalResources: (j['external_resources'] as List<dynamic>)
            .map((e) => ExternalContact.fromJson(e as Map<String, dynamic>))
            .toList(),
        app: AppContacts.fromJson(j['app_contacts'] as Map<String, dynamic>),
      );

      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider — loaded once, available everywhere
// ---------------------------------------------------------------------------
final contactsProvider =
    StateNotifierProvider<ContactsNotifier, AsyncValue<ContactsData>>(
  (ref) => ContactsNotifier(),
);
