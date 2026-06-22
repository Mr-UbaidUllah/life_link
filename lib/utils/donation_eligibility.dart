/// Blood-donation eligibility rules.
///
/// These are conservative, widely-used whole-blood guidelines (WHO / Red Cross
/// style). They are screening aids, NOT medical advice — final eligibility is
/// always confirmed by the collecting facility.
class DonationEligibility {
  DonationEligibility._();

  /// Minimum donor weight in kilograms.
  static const double minWeightKg = 50;

  /// Whole-blood donation cooldown: 8 weeks between donations.
  static const int cooldownDays = 56;

  /// Common conditions that typically defer a donor. Selecting any of these
  /// flags the donor as temporarily/permanently ineligible pending review.
  static const List<String> deferringConditions = [
    'Diabetes (on insulin)',
    'Hepatitis B or C',
    'HIV / AIDS',
    'Heart disease',
    'Recent surgery (< 6 months)',
    'Pregnant / recently gave birth',
    'Active infection or fever',
    'Cancer (current treatment)',
  ];

  /// Selectable conditions shown in the UI ("None" means no deferring issues).
  static const List<String> selectableConditions = [
    'None',
    ...deferringConditions,
  ];
}

/// The outcome of evaluating a donor's eligibility, with a human-readable
/// reason when they're not currently eligible.
class EligibilityResult {
  final bool isEligible;
  final String reason;
  final DateTime? nextEligibleDate;

  const EligibilityResult({
    required this.isEligible,
    required this.reason,
    this.nextEligibleDate,
  });
}
