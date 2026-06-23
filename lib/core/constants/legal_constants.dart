/// Centralized legal / compliance metadata for store submission.
///
/// IMPORTANT: Before publishing, replace the placeholder URLs/email below with
/// your live, publicly reachable pages. The Play Store Data Safety form and the
/// App Store privacy questionnaire both require a working Privacy Policy URL,
/// and the in-app screens link out to these.
class LegalInfo {
  LegalInfo._();

  /// Public legal name of the app/operator shown in policy headers.
  static const String appName = 'Life Link';
  static const String operator = 'Life Link';

  /// Support / privacy contact address (used in policies and "Contact us").
  static const String supportEmail = 'support@lifelinkapp.com';

  /// Publicly hosted policy pages (REQUIRED by both stores). Replace these.
  static const String privacyPolicyUrl = 'https://lifelinkapp.com/privacy';
  static const String termsUrl = 'https://lifelinkapp.com/terms';

  /// Last time the policy/terms text below was revised.
  static const String lastUpdated = 'June 2026';

  /// Minimum age to use the app (stated in Terms; keep in sync with store age
  /// rating and your data-safety declarations).
  static const int minimumAge = 18;
}
