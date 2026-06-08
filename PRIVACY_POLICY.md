# Privacy Policy — UMSL Veterans Center App

**Effective date:** June 8, 2026
**Last updated:** June 8, 2026
**App name:** UMSL Veterans Center
**Platform:** iOS and macOS (Apple App Store) · Android (Google Play Store)
**Developer:** Stormtheory for the UMSL Veterans Center, University of Missouri–St. Louis
**Contact:** VeteransOffice@umsl.edu · (314) 516-5705

---

## Overview

The UMSL Veterans Center app is a free utility application built exclusively for student veterans, active duty servicemembers, military-connected students, and their dependents enrolled at the University of Missouri–St. Louis. It is distributed as an **unlisted app** — it is not publicly searchable on the App Store or Google Play and is accessed only by those provided a direct link by the UMSL Veterans Center.

This privacy policy describes how the app handles user information. The short version: **we collect 3 pieces of information locally, we store nothing on any server, and we share nothing with anyone.**

---

## 1. Data We Collect and How We Use It

### 1.1 Information entered during onboarding

When a student first opens the app, they are asked to provide:

| Field                    | Purpose                                                 | Stored?                          |
|--------------------------|---------------------------------------------------------|----------------------------------|
| University email address | Confirms the user holds a valid UMSL or UM System email | Yes — encrypted on device only   |
| First name               | Personalizes the greeting on the home screen            | Yes — encrypted on device only   |
| Last name                | Personalizes the greeting on the home screen            | Yes — encrypted on device only   |
| Student ID number        | Used once to validate enrollment status                 | **No — discarded immediately**.  |

**Student ID handling:** The student ID number is entered during onboarding solely to confirm the user is an enrolled UMSL student. It is validated in memory and then immediately discarded. It is never written to device storage, never transmitted, and cannot be retrieved after the onboarding screen closes. No record of the student ID is retained anywhere by the app.

### 1.2 User-generated checklist data

Students may add personal tasks to their semester checklist. These tasks are stored locally on the device. They never leave the device.

### 1.3 App preferences

Theme selection (light, dark, or system default) is stored locally on the device.

### 1.4 Data we do not collect

The app does not collect, access, or process any of the following:

- Location data
- Contact list or address book
- Camera or microphone
- Photos or media library
- Browsing history
- Device identifiers (IDFA, IDFV, Android Advertising ID)
- Crash logs or analytics
- Usage statistics or telemetry
- Biometric data
- Payment or financial information
- Social network credentials

---

## 2. How Data Is Stored

All data entered by the user is stored **exclusively on the user's device** using the platform's native encrypted storage:

- **iOS and macOS:** iOS Keychain (`kSecClassGenericPassword`) via `flutter_secure_storage`. Configured with `synchronizable: false` — data is explicitly prevented from syncing to iCloud or any Apple server.
- **Android:** Android Keystore system backed by `EncryptedSharedPreferences`. Hardware-backed encryption where the device supports it.

No backend server, database, cloud storage, or third-party data processor receives any data from this app.

---

## 3. Data Transmission

The app makes outbound network connections only in the following circumstances, all of which are initiated explicitly by the user:

| Action                                                | Destination                                    | What is sent                                            |
|-------------------------------------------------------|------------------------------------------------|---------------------------------------------------------|
| Tapping an external link (VA.gov, UMSL website, etc.) | The linked website                             | Nothing beyond what a standard browser request includes |
| Tapping "Directions"                                  | Apple Maps or Google Maps                      | The destination address or GPS coordinates of the selected campus building |
| Tapping "Call"                                        | The device's phone dialer                      | The phone number                                        |
| Tapping "Report an issue"                             | The device's mail app                          | A pre-composed email draft opened for the user to review and send manually |
| Loading the interactive campus map                    | OpenStreetMap tile servers (openstreetmap.org) | Tile coordinates only — no user identity or location data |

The app does not make any background network requests. No data is transmitted without a direct user action.

---

## 4. Data Sharing and Disclosure

We do not sell, rent, license, or share any user data with any third party, including advertisers, data brokers, analytics providers, or any other entity. There are no third-party SDKs, advertising networks, or tracking frameworks integrated into this app.

---

## 5. Children's Privacy

This app is intended for use by enrolled university students and is not directed at children under the age of 13 (United States) or under the age of 16 (where applicable under GDPR or similar regulations). We do not knowingly collect any information from minors. If a minor has installed the app, they should uninstall it. Contact VeteransOffice@umsl.edu if you have concerns.

---

## 6. FERPA Compliance

The University of Missouri–St. Louis is subject to the Family Educational Rights and Privacy Act (FERPA), 20 U.S.C. § 1232g. Consistent with FERPA:

- The app does not have access to or store, therefore does not transmit student education records to any external party.
- The student ID number, which may constitute a student record identifier, is never retained by the app.
- Name and email address are stored only on the student's own device and are not accessible to the university, the app developer, or any third party.

---

## 7. User Control and Data Deletion

Students have full control over all data stored by the app.

**To delete personal data without resetting the full app:**
Settings → Reset personal data

This deletes the stored name, email, and all checklist progress from the device Keychain (Secure Data Storage).

**To delete all app data:**
Settings → Full app reset

This deletes everything the app has stored on the device, equivalent to uninstalling the app.

**To delete all data permanently:** Uninstall the app. Because no data is stored on any server, uninstalling the app removes all associated data completely and irreversibly. There is no account to deactivate and no server-side deletion request is necessary or possible.

---

## 8. Security

Data stored by this app is protected by the device's native encrypted storage mechanisms (iOS Keychain, Android Keystore, MacOS Keychain). These systems use AES-256 encryption and, on modern hardware, are backed by a secure enclave or trusted execution environment. The app does not implement its own encryption layer — it relies entirely on the platform's built-in, audited security infrastructure.

The app does not require a login, does not issue session tokens, and does not maintain any authenticated session with any server.

---

## 9. Changes to This Policy

If this policy changes materially, the updated version will be distributed through the same channel used to distribute the app (direct link from the UMSL Veterans Center). The effective date at the top of this document will be updated. Because the app is unlisted and distributed to a known audience, users will be notified directly by the Veterans Center staff.

---

## 10. Contact

Questions about this privacy policy or the app's data practices:

**UMSL Veterans Center**
211 Clark Hall
1 University Blvd., St. Louis, MO 63121
VeteransOffice@umsl.edu
(314) 516-5705

For FERPA-related concerns:
**UMSL Office of the Registrar**
325 Millennium Student Center
registrar@umsl.edu · (314) 516-5545

---

*This app is provided as a free service to student veterans at the University of Missouri–St. Louis. It is not a commercial product and generates no revenue.*
