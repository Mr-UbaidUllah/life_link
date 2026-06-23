import 'package:blood_donation/core/constants/legal_constants.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

/// A single titled block of policy text.
class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

/// Shared scaffold for the static legal documents (Privacy / Terms). Renders a
/// gradient header, a "last updated" line, the sections, and a contact footer.
class _LegalScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final String intro;
  final List<_Section> sections;
  final String? webUrl;

  const _LegalScaffold({
    required this.title,
    required this.icon,
    required this.intro,
    required this.sections,
    this.webUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
        ),
        title: Text(title, style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        children: [
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.circular(AppRadii.xl.r),
              boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.28),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(11.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3)),
                      SizedBox(height: 3.h),
                      Text('Last updated · ${LegalInfo.lastUpdated}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.sp)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Text(intro,
              style: TextStyle(fontSize: 14.sp, height: 1.55, color: muted)),
          SizedBox(height: 8.h),
          for (final s in sections) _sectionWidget(theme, s, muted),
          SizedBox(height: 8.h),
          if (webUrl != null)
            _LinkRow(
              icon: Icons.open_in_new_rounded,
              label: 'View the full version online',
              onTap: () => _open(webUrl!),
            ),
          _LinkRow(
            icon: Icons.mail_outline_rounded,
            label: 'Contact us · ${LegalInfo.supportEmail}',
            onTap: () => _open('mailto:${LegalInfo.supportEmail}'),
          ),
        ],
      ),
    );
  }

  Widget _sectionWidget(ThemeData theme, _Section s, Color muted) {
    return Padding(
      padding: EdgeInsets.only(top: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 15.5.sp)),
          SizedBox(height: 6.h),
          Text(s.body,
              style: TextStyle(fontSize: 13.5.sp, height: 1.55, color: muted)),
        ],
      ),
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Row(
            children: [
              Icon(icon, size: 18.sp, color: theme.colorScheme.primary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5.sp)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Privacy Policy
// ---------------------------------------------------------------------------

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalScaffold(
      title: 'Privacy Policy',
      icon: Icons.shield_outlined,
      webUrl: LegalInfo.privacyPolicyUrl,
      intro:
          'This policy explains what ${LegalInfo.appName} collects, why, and the '
          'choices you have. By using the app you agree to the practices below.',
      sections: const [
        _Section(
          'Information we collect',
          'Account: your email address.\n'
              'Profile: your name, phone number, city, country, blood group, '
              'profile photo and optional bio.\n'
              'Health details (optional): weight, last donation date and any '
              'health conditions you choose to add for eligibility checks.\n'
              'Location: your approximate device location, only while the app is '
              'in use, to show nearby requests and distances.\n'
              'Activity: blood requests you create or accept, and messages you '
              'send to other users.\n'
              'Device: a push-notification token so we can alert you.',
        ),
        _Section(
          'How we use your information',
          'To match donors with nearby blood requests, show how far each request '
              'is, send you relevant notifications, enable messaging between a '
              'requester and donors, run eligibility checks, and keep the '
              'community safe (e.g. handling reports and blocks).',
        ),
        _Section(
          'What other users can see',
          'Your public profile shows only your name, blood group, city and photo. '
              'Your phone number is private and is revealed to a donor only after '
              'they accept your specific request, so you can coordinate the '
              'donation. Health details are never shown to other users.',
        ),
        _Section(
          'How your data is stored & shared',
          'Your data is stored on Google Firebase (Authentication, Cloud '
              'Firestore, Cloud Storage and Cloud Messaging), which processes it '
              'on our behalf. We do not sell your personal data or share it with '
              'advertisers. We may disclose information if required by law.',
        ),
        _Section(
          'Data retention & deletion',
          'We keep your data while your account is active. You can delete your '
              'account at any time from Settings → Delete Account. This permanently '
              'removes your profile, your blood requests and your notifications. '
              'Some content may persist briefly in backups before being purged.',
        ),
        _Section(
          'Security',
          'Access is protected by authentication and server-side security rules '
              'so users can only read and write the data they are permitted to. No '
              'method of transmission or storage is 100% secure, but we work to '
              'protect your information.',
        ),
        _Section(
          'Your rights',
          'You can access and update your information in the app, and delete your '
              'account and associated data at any time. For any privacy request, '
              'contact us using the address below.',
        ),
        _Section(
          'Children',
          'Life Link is intended for users aged 18 and over and is not directed '
              'to children.',
        ),
        _Section(
          'Changes to this policy',
          'We may update this policy from time to time. Material changes will be '
              'reflected here with a new "last updated" date.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Terms of Service
// ---------------------------------------------------------------------------

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalScaffold(
      title: 'Terms of Service',
      icon: Icons.gavel_rounded,
      webUrl: LegalInfo.termsUrl,
      intro:
          'Please read these terms carefully. By creating an account or using '
          '${LegalInfo.appName}, you agree to them.',
      sections: const [
        _Section(
          'Eligibility',
          'You must be at least 18 years old to use Life Link and provide '
              'accurate information about yourself.',
        ),
        _Section(
          'Not a medical or emergency service',
          'Life Link is a platform that helps connect blood donors and people in '
              'need. It is NOT a hospital, blood bank, ambulance dispatcher or '
              'medical provider, and does not give medical advice. In an emergency, '
              'always call your local emergency number. Donor eligibility, blood '
              'compatibility and the safety of any donation must be confirmed by '
              'qualified medical professionals. We do not guarantee that a donor '
              'or the blood you need will be found.',
        ),
        _Section(
          'Your responsibilities',
          'You agree to: provide truthful information; use the app lawfully; not '
              'post fake, fraudulent or duplicate requests; not harass, deceive or '
              'endanger others; and verify the identity and details of anyone you '
              'arrange to meet. Donations are voluntary and must never be bought '
              'or sold.',
        ),
        _Section(
          'Content & conduct',
          'You are responsible for the content you submit. We may remove content '
              'and suspend or terminate accounts that violate these terms, abuse '
              'the service, or put others at risk.',
        ),
        _Section(
          'Account termination',
          'You may delete your account at any time from Settings. We may suspend '
              'or terminate access if you breach these terms.',
        ),
        _Section(
          'Disclaimers & limitation of liability',
          'The app is provided "as is" without warranties of any kind. To the '
              'fullest extent permitted by law, ${LegalInfo.operator} is not liable '
              'for any harm, loss or damages arising from your use of the app or '
              'from interactions, arrangements or donations between users.',
        ),
        _Section(
          'Changes to these terms',
          'We may update these terms. Continued use after changes means you '
              'accept the updated terms.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FAQ
// ---------------------------------------------------------------------------

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}

const List<_Faq> _faqs = [
  _Faq('How does Life Link match me with requests?',
      'When you set your blood group, the home screen highlights open requests '
          'that need your type and sorts what\'s nearby using your approximate '
          'location, so you can help where you\'re needed most.'),
  _Faq('Who can see my phone number?',
      'Your phone number stays private. It is shared with a donor only after '
          'they accept your specific request, so the two of you can coordinate.'),
  _Faq('What information is public?',
      'Only your name, blood group, city and profile photo. Your health details '
          'and contact number are never shown publicly.'),
  _Faq('How do I become a donor?',
      'Open "Donate" from the home screen and turn on your donor status. You '
          'can toggle "Available to donate now" any time from the home banner.'),
  _Faq('When can I donate again?',
      'After a donation there is a recovery cooldown. Once you add your last '
          'donation date, the app shows when you\'ll be eligible again.'),
  _Faq('How do I create a blood request?',
      'Tap the + button, then follow the short steps: blood group and units, '
          'hospital and location, details and contact, then review and post. '
          'Matching donors nearby are alerted instantly.'),
  _Faq('Why does the app need my location?',
      'Location (used only while the app is open) lets us show nearby requests '
          'and how far away each one is. You can use the app without it, but '
          'distance sorting won\'t be available.'),
  _Faq('How do I block or report someone?',
      'Open a request or profile and use the menu to report the content or '
          'block the user. Blocked users can\'t contact you or see your requests.'),
  _Faq('How do I delete my account?',
      'Go to Settings → Delete Account. This permanently removes your profile, '
          'your requests and your notifications. The action cannot be undone.'),
];

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
        ),
        title: Text('Help & FAQ', style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
        children: [
          for (final f in _faqs) _FaqTile(faq: f),
          SizedBox(height: 20.h),
          _LinkRow(
            icon: Icons.mail_outline_rounded,
            label: 'Still need help? ${LegalInfo.supportEmail}',
            onTap: () => _LegalScaffold._open('mailto:${LegalInfo.supportEmail}'),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          iconColor: theme.colorScheme.primary,
          collapsedIconColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.4),
          title: Text(faq.q,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(faq.a,
                  style: TextStyle(
                      fontSize: 13.5.sp,
                      height: 1.55,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.7))),
            ),
          ],
        ),
      ),
    );
  }
}
