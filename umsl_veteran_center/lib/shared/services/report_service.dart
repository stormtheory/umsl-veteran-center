// lib/shared/services/report_service.dart
//
// Builds mailto: URIs for reporting task errors and general feedback.
// All contact info (email, subjects, body templates) comes from
// ContactsData loaded from assets/data/contacts.json — never hardcoded here.
//
// Usage:
//   ReportService.reportTask(contacts: contacts, taskTitle: ..., ...)
//   ReportService.reportGeneral(contacts: contacts)

import 'package:url_launcher/url_launcher.dart';
import 'contacts_service.dart';

class ReportService {

  // ---------------------------------------------------------------------------
  // Report a specific task as potentially incorrect
  // ---------------------------------------------------------------------------
  static Future<void> reportTask({
    required ContactsData contacts,
    required String taskTitle,
    required String benefitName,
    required String semesterLabel,
  }) async {
    final subject = Uri.encodeComponent(contacts.app.reportSubjectTask);
    final body    = Uri.encodeComponent(
      contacts.app.buildTaskReportBody(
        taskTitle:     taskTitle,
        benefitName:   benefitName,
        semesterLabel: semesterLabel,
      ),
    );
    final uri = Uri.parse(
      'mailto:${contacts.app.reportEmail}?subject=$subject&body=$body',
    );
    await _launch(uri);
  }

  // ---------------------------------------------------------------------------
  // General feedback or issue report — used from Settings tab
  // ---------------------------------------------------------------------------
  static Future<void> reportGeneral({
    required ContactsData contacts,
    String? context,
  }) async {
    final subject = Uri.encodeComponent(contacts.app.reportSubjectGeneral);
    final bodyText = context != null
        ? contacts.app.reportBodyGeneral.replaceFirst(
            '[Your message here]',
            'Context: $context\n\n[Your message here]',
          )
        : contacts.app.reportBodyGeneral;
    final body = Uri.encodeComponent(bodyText);
    final uri = Uri.parse(
      'mailto:${contacts.app.reportEmail}?subject=$subject&body=$body',
    );
    await _launch(uri);
  }

  // ---------------------------------------------------------------------------
  // Internal launch helper
  // ---------------------------------------------------------------------------
  static Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    // If mailto: can't launch (e.g. no Mail app configured on device),
    // the call silently completes — no crash. On physical devices with
    // Mail or a default mail client configured this always succeeds.
  }
}
