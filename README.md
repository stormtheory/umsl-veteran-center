# UMSL Veterans Center App

A Flutter application for student veterans at the University of Missouri–St. Louis. Provides a semester checklist, BAH/MHA calculator, benefits calendar, VA resource directory, and direct access to Vet Center contact information — all on-device with no server required.

**App Store description:**
> Checklist, BAH calculator & VA resources for UMSL student veterans.

---

## Contact

**UMSL Veterans Center**
211 Clark Hall, 1 University Blvd., St. Louis, MO 63121
(314) 516-5705 | VeteransOffice@umsl.edu
Mon–Thu 8:00 AM–7:00 PM | Fri 8:00 AM–4:00 PM
https://www.umsl.edu/veterans/index.html

---

## Project Structure

```
umsl-veteran-center/
├── .gitignore
├── README.md
└── umsl_veteran_center/               Flutter app
    ├── assets/
    │   ├── data/                      JSON content files — edit these, no recompile needed
    │   │   ├── contacts.json          Master contact directory — all phones, emails, addresses
    │   │   ├── calendar.json          Home screen calendar events
    │   │   ├── news.json              Home screen announcements
    │   │   ├── benefits.json          Benefit program definitions (Ch. 33, Ch. 30, etc.)
    │   │   ├── benefit_tasks.json     Per-benefit per-semester task lists
    │   │   ├── graduation_tasks.json  Fixed graduation checklist
    │   │   ├── semesters.json         Semester dates, sub-terms, lock dates
    │   │   └── bah_rates.json         BAH/MHA rates and summer session thresholds
    │   ├── images/                    UMSL Vet Center logo, lounge photo, app icon SVG
    │   ├── seals/                     Official US military branch seals (PNG, transparent)
    │   └── svg/                       NDSM ribbon SVG
    ├── lib/
    │   ├── main.dart
    │   ├── core/
    │   │   └── theme/                 AppTheme, VetTheme extension, ThemeProvider
    │   ├── shell/
    │   │   └── main_shell.dart        5-tab navigation shell
    │   ├── features/
    │   │   ├── onboarding/            Email, identity, welcome screens + provider
    │   │   ├── home/                  Home screen, calendar widget, news feed
    │   │   ├── checklist/             Semester checklist, setup, detail screens
    │   │   ├── bah/                   BAH/MHA calculator
    │   │   ├── resources/             Resources tab with Vet Center info and VA links
    │   │   └── settings/              Theme toggle, profile edit, data reset
    │   └── shared/
    │       └── services/
    │           ├── secure_storage_service.dart   iOS Keychain wrapper
    │           ├── storage_providers.dart        Riverpod providers for storage
    │           ├── contacts_service.dart         Loads contacts.json, exposes by ID
    │           └── report_service.dart           Pre-filled mailto for Vet Center reports
    ├── ios/Podfile
    ├── macos/Podfile
    └── pubspec.yaml
```

---

## Features

### Completed
- Onboarding — email validation, student ID (not stored), secure Keychain storage
- Home screen — interactive color-coded calendar and announcements feed
- Semester checklist — full enrollment system with 6 benefit programs, degree levels, summer sub-terms, graduation tasks, custom tasks, and read-only locking
- BAH/MHA calculator — Ch. 33, Ch. 30, Ch. 35, Ch. 1606, Ch. 31, Missouri Returning Heroes. Summer session complexity built in.
- Resources tab — Vet Center info, quick links, VA contacts, crisis line
- Settings — System/Light/Dark theme, profile editing, data reset options
- Full light and dark mode support via VetTheme extension
- App icon — UMSL crimson with gold trident, star bar, Veterans Center label

### Planned
- Push notifications for deadline reminders
- go_router navigation (currently using Navigator directly)

---

## Updating Content — No Recompile Required

All content the Vet Center manages lives in `assets/data/`. Edit a JSON file, rebuild and distribute the app. No Dart changes needed unless the data schema itself changes.

### Adding or editing a calendar event

Open `assets/data/calendar.json`:

```json
{
  "date": "2026-09-18",
  "type": "green",
  "name": "Coffee and connect",
  "time": "9:00 AM",
  "location": "MSC Room 219",
  "desc": "Monthly Vet Center coffee hour. Drop in any time between 9 and 11 AM.",
  "links": [
    { "label": "Vet Center", "url": "https://www.umsl.edu/veterans/index.html" }
  ]
}
```

| JSON type  | Color              | Meaning                             |
|------------|--------------------|-------------------------------------|
| purple     | Purple #7B1FA2     | Academic / school dates             |
| light_blue | Light blue #29B6F6 | Holidays and campus closures        |
| red        | Red #E53935        | Deadlines                           |
| gold       | Gold #C0A060       | Campus events                       |
| green      | Green #4CAF50      | Veteran and Vet Center events       |

### Adding an announcement

Open `assets/data/news.json`:

```json
{
  "tag": "Vet Center",
  "title": "Your announcement title",
  "body": "Body text here.",
  "date": "2026-06-01",
  "link": { "label": "Learn more", "url": "https://vetcenter.umsl.edu" }
}
```

Set `"link": null` if no external link is needed. Keep the list sorted newest first.

### Adding or editing a semester

Open `assets/data/semesters.json`:

| Field | Meaning |
|---|---|
| `opens_date` | When students can start setting up their checklist |
| `start_date` | First day of classes |
| `end_date` | Last day of classes |
| `lock_date` | After this date the checklist becomes read-only |

Summer semesters include a `sub_terms` array. Students multi-select which sub-terms they are enrolled in.

### Updating BAH/MHA rates

Open `assets/data/bah_rates.json` each August when the VA publishes new rates. Update the `monthly_rate` values for Ch. 30, Ch. 35, and Ch. 1606, and update `mha_full_inperson` for Ch. 33. Also update `academic_year` at the top.

### Updating contact information

Open `assets/data/contacts.json`. This is the single source of truth for every phone number, email, office location, and hours across the entire app. Update here and it propagates everywhere on the next rebuild.

---

## Development Setup

### Prerequisites

- Flutter SDK (stable channel)
- Xcode 15 or later
- CocoaPods — `brew install cocoapods`
- Android Studio (for Android builds)

### First run

```bash
cd umsl_veteran_center
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Release builds

```bash
# iOS
flutter build ipa

# Android
flutter build appbundle
```

### Clean build (run this if you see stale error messages)

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## Architecture

### State management — Riverpod

| Provider | Location | Purpose |
|---|---|---|
| `onboardingProvider` | `features/onboarding/providers/` | Onboarding flow state |
| `themeModeProvider` | `core/theme/` | Light/dark/system theme — persisted to Keychain |
| `userProfileProvider` | `shared/services/` | User profile from Keychain |
| `calendarProvider` | `features/home/providers/` | Calendar events from JSON |
| `newsProvider` | `features/home/providers/` | Announcements from JSON |
| `checklistProvider` | `features/checklist/providers/` | Full checklist state |
| `bahProvider` | `features/bah/providers/` | BAH calculator state |
| `contactsProvider` | `shared/services/` | Contact directory from JSON |

### Theme system

`VetTheme` is a Flutter `ThemeExtension` that provides semantic color tokens for both light and dark modes. Every widget reads colors via `context.vetTheme` — never hardcoded. Defined in `lib/core/theme/vet_theme.dart`.

Key tokens: `pageBackground`, `cardBackground`, `cardBorder`, `textPrimary`, `textSecondary`, `textTertiary`, `textOnDark`, `accentGold`, `primaryRed`, `selectedBackground`, `divider`.

### Secure storage

All PII (email, name) and student checklist data is stored using `flutter_secure_storage` — the iOS Keychain on iPhone/iPad, and the Android Keystore backed by EncryptedSharedPreferences on Android. Both use hardware-backed encryption where available. Nothing is ever transmitted to a server.

Storage keys:
- `onboarding_complete` — boolean flag
- `user_profile` — JSON: email, firstName, lastName, studentId
- `theme_mode` — light/dark/system
- `checklist_enrollments` — JSON array of all semester enrollment data and completions
- `checklist_disclaimer_accepted` — boolean flag

### Data flow

```
JSON assets (read-only)           Keychain (read-write)
       |                                  |
  Riverpod Providers  <------------------+
       |
  Screens and Widgets
```

---

## App Icon

The app icon is built from `assets/images/app_icon.svg`:
- UMSL Triton Red Letters and Background (`#ba0c2f`)
- UMSL in Oswald Bold
- White stars on a blue field bar
- Veterans Center label

Pre-exported PNG sizes live in the `AppIcons/` and `AppIcons_macOS/` folders (not committed — regenerate from the SVG using `cairosvg` if needed).

---

## App Store

### iOS App Store
- Bundle ID: `edu.umsl.veteranscenter`
- Category: Education
- Age rating: 4+
- Privacy policy required (collects name and email on-device )

### Google Play Store
- Package name: `edu.umsl.veteranscenter`
- Category: Education
- Content rating: Everyone
- Signing keystore: keep the `.jks` file backed up permanently

**Short description (80 chars):**
> Checklist, BAH calculator & VA resources for UMSL student veterans.

**Promotional text (170 chars):**
> Your semester checklist, BAH calculator, VA resources, and Vet Center contacts — built for UMSL student veterans.

---

## Assets

### Military branch seals

The six official branch seals (`assets/seals/`) are public domain works of the United States federal government, sourced from Wikimedia Commons. Each PNG has been processed to remove the black background and saved as transparent RGBA images.

### NDSM ribbon

`assets/svg/ndsm_ribbon.svg` — National Defense Service Medal ribbon bar. Accurate stripe specification: Scarlet, White, Old Glory Blue, White, Scarlet, Gold center, mirrored.

---

## Branch

Active development branch: `Perfect_Storm`

---

## Privacy

This app stores all data locally on the student's device using platform-native encrypted storage — iOS Keychain on iPhone/iPad, MacOS Keychain, Android Keystore on Android. No analytics, no tracking, no external data transmission of any kind. The only outbound network activity is when a student taps an external link or uses the report feature which opens their mail app with a pre-filled email — the student reviews and sends it manually. Nothing is sent automatically.
