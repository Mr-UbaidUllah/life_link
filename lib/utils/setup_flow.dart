/// The profile-setup steps, in order.
enum SetupStep { personalInfo, basicInfo, photo, completed }

/// Given a user's saved Firestore document, returns the first step that still
/// needs to be done — so a returning user resumes where they left off instead
/// of restarting at Step 1. Each step writes its data as it's completed, so we
/// infer progress from what's already saved.
SetupStep firstIncompleteStep(Map<String, dynamic> data) {
  if (data['profileCompleted'] == true) return SetupStep.completed;

  bool hasText(String key) => (data[key] ?? '').toString().trim().isNotEmpty;

  // Step 1: personal/contact details.
  final step1Done = hasText('name') &&
      hasText('phone') &&
      hasText('bloodGroup') &&
      hasText('country') &&
      hasText('city');
  if (!step1Done) return SetupStep.personalInfo;

  // Step 2: donation preference (marker written when the step is submitted).
  if (data['basicInfoCompleted'] != true) return SetupStep.basicInfo;

  // Step 1 & 2 done but setup not marked complete → Step 3 (photo).
  return SetupStep.photo;
}
