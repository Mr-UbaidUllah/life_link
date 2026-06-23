import 'package:blood_donation/core/constants/app_constants.dart';
import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/blood_request_provider.dart';
import 'package:blood_donation/services/location_service.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/bottom_navigation.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// Create-request flow, rebuilt as a guided 4-step wizard.
///
/// A blood request is created under stress, often on someone else's behalf — so
/// the flow is broken into small, single-focus steps with per-step validation,
/// a final review, and a success state, instead of one intimidating long form:
///
///   1. The need        — blood group · units · urgency  (the triage core)
///   2. Hospital & where — hospital · country · city · needed-by date
///   3. Details          — title · reason · contact · phone
///   4. Review & post    — confirm everything, then submit
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  static const int _stepCount = 4;

  final PageController _pageController = PageController();
  int _step = 0;
  bool _submitted = false;
  bool _submitting = false;

  // ---- Form state ----
  final TextEditingController titleController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final List<String> bloodGroups = kBloodGroups;
  final Map<String, List<String>> countryCities = kCountryCities;

  String? selectedBloodGroup;
  String? selectedCountry;
  String? selectedCity;
  DateTime? selectedDate;
  String selectedUrgency = 'urgent';
  int bags = 1;

  @override
  void dispose() {
    _pageController.dispose();
    titleController.dispose();
    hospitalController.dispose();
    reasonController.dispose();
    contactController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? theme.colorScheme.error : AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
  }

  /// Validates the current step. Returns an error string, or null if valid.
  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (selectedBloodGroup == null) return 'Select a blood group';
        if (bags <= 0) return 'Choose how many units are needed';
        return null;
      case 1:
        if (hospitalController.text.trim().isEmpty) {
          return 'Enter the hospital name';
        }
        if (selectedCountry == null) return 'Select a country';
        if (selectedCity == null) return 'Select a city';
        if (selectedDate == null) return 'Pick the date blood is needed by';
        return null;
      case 2:
        if (titleController.text.trim().isEmpty) return 'Add a short title';
        if (phoneController.text.trim().isEmpty) {
          return 'Add a contact number';
        }
        return null;
      default:
        return null;
    }
  }

  void _next() {
    if (_step == _stepCount - 1) {
      _submit();
      return;
    }
    final error = _validateStep(_step);
    if (error != null) {
      _showSnackBar(error, isError: true);
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(_step,
        duration: AppMotion.base, curve: AppMotion.standard);
    FocusScope.of(context).unfocus();
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step--);
    _pageController.animateToPage(_step,
        duration: AppMotion.base, curve: AppMotion.standard);
    FocusScope.of(context).unfocus();
  }

  void _jumpTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(step,
        duration: AppMotion.base, curve: AppMotion.standard);
  }

  Future<void> _submit() async {
    // Guard against a double-tap. provider.isLoading only flips once
    // bloodRequest() runs, but getCurrentPosition() below awaits first and can
    // take seconds — during which a second tap would post a duplicate request.
    if (_submitting) return;
    _submitting = true;
    try {
      await _submitInner();
    } finally {
      _submitting = false;
    }
  }

  Future<void> _submitInner() async {
    final provider = context.read<BloodrequestProvider>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Defensive: re-check every step in case state was bypassed.
    for (var s = 0; s < _stepCount - 1; s++) {
      final error = _validateStep(s);
      if (error != null) {
        _jumpTo(s);
        _showSnackBar(error, isError: true);
        return;
      }
    }

    final expiry = DateTime(selectedDate!.year, selectedDate!.month,
        selectedDate!.day, 23, 59, 59);

    // Best-effort: attach coordinates so donors can see distance.
    final pos = await LocationService.getCurrentPosition();

    final request = BloodRequestModel(
      id: '',
      title: titleController.text.trim(),
      bloodGroup: selectedBloodGroup ?? '',
      bags: bags,
      hospital: hospitalController.text.trim(),
      reason: reasonController.text.trim(),
      contactName: contactController.text.trim(),
      phone: phoneController.text.trim(),
      country: selectedCountry ?? '',
      city: selectedCity ?? '',
      userId: user.uid,
      createdAt: DateTime.now(),
      expiryDate: expiry,
      status: 'open',
      urgency: selectedUrgency,
      lat: pos?.latitude,
      lng: pos?.longitude,
    );

    try {
      await provider.bloodRequest(request);
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_submitted) return _SuccessView(theme: theme);

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            onPressed: _back,
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.onSurface),
          ),
          title: Text(_stepTitle, style: TextStyle(fontSize: 17.sp)),
        ),
        body: Column(
          children: [
            _progress(theme),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepNeed(theme),
                  _stepWhere(theme),
                  _stepDetails(theme),
                  _stepReview(theme),
                ],
              ),
            ),
            _bottomBar(theme),
          ],
        ),
      ),
    );
  }

  String get _stepTitle => switch (_step) {
        0 => 'The need',
        1 => 'Hospital & location',
        2 => 'Details',
        _ => 'Review & post',
      };

  String get _stepSubtitle => switch (_step) {
        0 => 'What blood is needed, and how urgently?',
        1 => 'Where and by when is it needed?',
        2 => 'A short description and how to reach you.',
        _ => 'Check everything before posting.',
      };

  // ----------------------------------------------------------- Progress bar

  Widget _progress(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < _stepCount; i++) ...[
                if (i > 0) SizedBox(width: 6.w),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    curve: AppMotion.standard,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(AppRadii.pill.r),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          Text('Step ${_step + 1} of $_stepCount',
              style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary)),
          SizedBox(height: 2.h),
          Text(_stepSubtitle,
              style: TextStyle(
                  fontSize: 13.sp,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }

  EdgeInsets get _pagePadding => EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h);

  // ----------------------------------------------------------- Step 1: need

  Widget _stepNeed(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(theme, 'Blood group'),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final g in bloodGroups) _bloodChip(theme, g),
            ],
          ),
          SizedBox(height: 24.h),
          _label(theme, 'Units needed'),
          SizedBox(height: 12.h),
          _unitsStepper(theme),
          SizedBox(height: 24.h),
          _label(theme, 'How urgent is this?'),
          SizedBox(height: 12.h),
          _urgencySelector(theme),
        ],
      ),
    );
  }

  Widget _bloodChip(ThemeData theme, String g) {
    final selected = selectedBloodGroup == g;
    return TapScale(
      onTap: () => setState(() => selectedBloodGroup = g),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: 64.w,
        height: 56.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.hero : null,
          color: selected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md.r),
          border: Border.all(
              color: selected
                  ? Colors.transparent
                  : theme.colorScheme.outline),
          boxShadow:
              selected ? AppGradients.glow(AppColors.primary, alpha: 0.3) : null,
        ),
        child: Text(g,
            style: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 16.sp,
                letterSpacing: -0.5)),
      ),
    );
  }

  Widget _unitsStepper(ThemeData theme) {
    Widget btn(IconData icon, VoidCallback? onTap) => TapScale(
          onTap: onTap,
          child: Container(
            height: 48.r,
            width: 48.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Icon(icon,
                size: 22.sp,
                color: onTap == null
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
                    : theme.colorScheme.primary),
          ),
        );

    return Row(
      children: [
        btn(Icons.remove_rounded, bags > 1 ? () => setState(() => bags--) : null),
        Expanded(
          child: Column(
            children: [
              Text('$bags',
                  style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1)),
              Text(bags == 1 ? 'unit' : 'units',
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
        btn(Icons.add_rounded,
            bags < 20 ? () => setState(() => bags++) : null),
      ],
    );
  }

  Widget _urgencySelector(ThemeData theme) {
    const levels = [
      UrgencyLevel.critical,
      UrgencyLevel.urgent,
      UrgencyLevel.routine
    ];
    return Row(
      children: [
        for (final lvl in levels)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: lvl == levels.last ? 0 : 8.w),
              child: TapScale(
                onTap: () => setState(() => selectedUrgency = lvl.name),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: selectedUrgency == lvl.name
                        ? lvl.color
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md.r),
                    border: Border.all(
                      color: selectedUrgency == lvl.name
                          ? lvl.color
                          : theme.colorScheme.outline,
                    ),
                    boxShadow: selectedUrgency == lvl.name
                        ? AppGradients.glow(lvl.color, alpha: 0.3)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(lvl.icon,
                          color: selectedUrgency == lvl.name
                              ? Colors.white
                              : lvl.color,
                          size: 22.sp),
                      SizedBox(height: 6.h),
                      Text(
                        lvl.label,
                        style: TextStyle(
                          color: selectedUrgency == lvl.name
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------- Step 2: location

  Widget _stepWhere(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: hospitalController,
            labelText: 'Hospital name',
            hintText: 'Type hospital name',
            prefixIcon: Icons.local_hospital_rounded,
            borderRadius: 16.r,
          ),
          SizedBox(height: 16.h),
          CustomDropdownFormField<String>(
            labelText: 'Country',
            hintText: 'Select country',
            value: selectedCountry,
            items: countryCities.keys.toList(),
            itemToString: (e) => e,
            prefixIcon: Icon(Icons.public_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 22.sp),
            onChanged: (val) => setState(() {
              selectedCountry = val;
              selectedCity = null;
            }),
            focusedBorderColor: theme.colorScheme.primary,
            borderRadius: 16.r,
          ),
          SizedBox(height: 16.h),
          CustomDropdownFormField<String>(
            labelText: 'City',
            hintText: 'Select city',
            value: selectedCity,
            items: selectedCountry == null
                ? []
                : countryCities[selectedCountry] ?? [],
            itemToString: (e) => e,
            prefixIcon: Icon(Icons.location_city_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 22.sp),
            enabled: selectedCountry != null,
            onChanged: (val) => setState(() => selectedCity = val),
            focusedBorderColor: theme.colorScheme.primary,
            borderRadius: 16.r,
          ),
          SizedBox(height: 16.h),
          _dateField(theme),
        ],
      ),
    );
  }

  Widget _dateField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(theme, 'Needed by'),
        SizedBox(height: 8.h),
        InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ??
                  DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(colorScheme: theme.colorScheme),
                child: child!,
              ),
            );
            if (date != null) setState(() => selectedDate = date);
          },
          child: Container(
            height: 56.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 20.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                SizedBox(width: 12.w),
                Text(
                  selectedDate == null
                      ? 'Select date'
                      : _fmtDate(selectedDate!),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: selectedDate == null
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down_rounded,
                    size: 24.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------- Step 3: details

  Widget _stepDetails(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: titleController,
            labelText: 'Title',
            hintText: 'e.g. Urgent O+ blood needed',
            prefixIcon: Icons.title_rounded,
            borderRadius: 16.r,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            controller: reasonController,
            labelText: 'Reason (optional)',
            hintText: 'Explain the situation…',
            maxLines: 3,
            prefixIcon: Icons.info_outline_rounded,
            borderRadius: 16.r,
            height: 120.h,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            controller: contactController,
            labelText: 'Contact person (optional)',
            hintText: 'Full name of contact',
            prefixIcon: Icons.person_outline_rounded,
            borderRadius: 16.r,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            controller: phoneController,
            labelText: 'Mobile number',
            hintText: 'e.g. +92 300 1234567',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android_rounded,
            borderRadius: 16.r,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- Step 4: review

  Widget _stepReview(ThemeData theme) {
    final urgency = UrgencyLevel.fromName(selectedUrgency);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline card: blood group + urgency at a glance.
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl.r),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                BloodTypeBadge(group: selectedBloodGroup ?? '?', size: 54),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleController.text.trim().isEmpty
                            ? '${selectedBloodGroup ?? ''} blood needed'
                            : titleController.text.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15.sp),
                      ),
                      SizedBox(height: 8.h),
                      UrgencyBadge(level: urgency),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _reviewGroup(theme, 'The need', 0, [
            _reviewRow(theme, Icons.bloodtype_rounded, 'Blood group',
                selectedBloodGroup ?? '—'),
            _reviewRow(theme, Icons.opacity_rounded, 'Units',
                '$bags ${bags == 1 ? "unit" : "units"}'),
            _reviewRow(theme, urgency.icon, 'Urgency', urgency.label),
          ]),
          SizedBox(height: 12.h),
          _reviewGroup(theme, 'Hospital & location', 1, [
            _reviewRow(theme, Icons.local_hospital_rounded, 'Hospital',
                hospitalController.text.trim()),
            _reviewRow(theme, Icons.location_on_rounded, 'Location',
                [selectedCity, selectedCountry].where((e) => e != null).join(', ')),
            _reviewRow(theme, Icons.calendar_today_rounded, 'Needed by',
                selectedDate == null ? '—' : _fmtDate(selectedDate!)),
          ]),
          SizedBox(height: 12.h),
          _reviewGroup(theme, 'Details', 2, [
            if (reasonController.text.trim().isNotEmpty)
              _reviewRow(theme, Icons.info_outline_rounded, 'Reason',
                  reasonController.text.trim()),
            if (contactController.text.trim().isNotEmpty)
              _reviewRow(theme, Icons.person_outline_rounded, 'Contact',
                  contactController.text.trim()),
            _reviewRow(theme, Icons.phone_android_rounded, 'Phone',
                phoneController.text.trim()),
          ]),
        ],
      ),
    );
  }

  Widget _reviewGroup(
      ThemeData theme, String title, int editStep, List<Widget> rows) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl.r),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              GestureDetector(
                onTap: () => _jumpTo(editStep),
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  Icon(Icons.edit_rounded,
                      size: 14.sp, color: theme.colorScheme.primary),
                  SizedBox(width: 4.w),
                  Text('Edit',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp)),
                ]),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
          SizedBox(width: 12.w),
          Text('$label  ',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                textAlign: TextAlign.right,
                style:
                    TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Bottom bar

  Widget _bottomBar(ThemeData theme) {
    final isLast = _step == _stepCount - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(54.h),
                    side: BorderSide(color: theme.colorScheme.outline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md.r)),
                  ),
                  child: const Text('Back'),
                ),
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              flex: 3,
              child: Consumer<BloodrequestProvider>(
                builder: (context, provider, _) {
                  final loading = provider.isLoading;
                  return TapScale(
                    onTap: loading ? null : _next,
                    child: Container(
                      height: 54.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.hero,
                        borderRadius: BorderRadius.circular(AppRadii.md.r),
                        boxShadow:
                            AppGradients.glow(AppColors.primary, alpha: 0.35),
                      ),
                      child: loading
                          ? SizedBox(
                              height: 22.h,
                              width: 22.h,
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              isLast ? 'Post request' : 'Continue',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.sp),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Helpers

  Widget _label(ThemeData theme, String text) => Text(text,
      style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface));

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// Full-screen confirmation shown after a request is posted.
class _SuccessView extends StatelessWidget {
  final ThemeData theme;
  const _SuccessView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppMotion.slow,
                curve: AppMotion.emphasized,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Center(
                  child: Container(
                    height: 96.r,
                    width: 96.r,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 52.sp),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Text('Request posted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              SizedBox(height: 10.h),
              Text(
                  'Matching donors nearby are being alerted now. You’ll be notified when someone responds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.4,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6))),
              SizedBox(height: 36.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  MainScreen.switchTab(MainScreen.tabRequests);
                },
                child: const Text('View my requests'),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
