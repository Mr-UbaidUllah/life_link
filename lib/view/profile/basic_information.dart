import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/utils/donation_eligibility.dart';
import 'package:blood_donation/view/profile/image_screen.dart';
import 'package:blood_donation/widgets/app_snackbar.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BasicInformation extends StatefulWidget {
  /// When true, this screen edits an already-onboarded user's health details
  /// (opened from Settings) rather than acting as Step 2 of first-time setup.
  final bool isEditMode;

  const BasicInformation({super.key, this.isEditMode = false});

  @override
  State<BasicInformation> createState() => _BasicInformationState();
}

class _BasicInformationState extends State<BasicInformation> {
  static const List<String> _donateOptions = ['Yes', 'No'];

  String? _selectedOption;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _lastDonationController = TextEditingController();
  DateTime? _lastDonationDate;
  bool _neverDonated = false;
  final Set<String> _conditions = {};
  bool _loadingExisting = true;

  @override
  void initState() {
    super.initState();
    _prefillExisting();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _aboutController.dispose();
    _lastDonationController.dispose();
    super.dispose();
  }

  void _syncDonationDateText() {
    _lastDonationController.text = _neverDonated
        ? 'Never donated'
        : _lastDonationDate == null
            ? ''
            : DateFormat('d MMM yyyy').format(_lastDonationDate!);
  }

  Future<void> _prefillExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingExisting = false);
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        final user = UserModel.fromMap(doc.id, data);
        _selectedOption = user.isDonor ? 'Yes' : 'No';
        _aboutController.text = user.about ?? '';
        if (user.weightKg != null) {
          _weightController.text = user.weightKg!.toStringAsFixed(
            user.weightKg! % 1 == 0 ? 0 : 1,
          );
        }
        _lastDonationDate = user.lastDonationDate;
        _neverDonated = user.isDonor && user.lastDonationDate == null &&
            user.weightKg != null;
        _conditions.addAll(user.healthConditions);
        _syncDonationDateText();
      }
    } catch (_) {
      // Non-fatal: fall back to an empty form.
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  /// Builds a throwaway model from the current form values to preview eligibility.
  UserModel _draftUser() {
    return UserModel(
      uid: '',
      email: '',
      createdAt: DateTime.now(),
      isDonor: _selectedOption == 'Yes',
      weightKg: double.tryParse(_weightController.text.trim()),
      lastDonationDate: _neverDonated ? null : _lastDonationDate,
      healthConditions: _conditions.toList(),
    );
  }

  Future<void> _pickLastDonationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonationDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Last donation date',
    );
    if (picked != null) {
      setState(() {
        _lastDonationDate = picked;
        _neverDonated = false;
        _syncDonationDateText();
      });
    }
  }

  void _toggleCondition(String condition, bool selected) {
    setState(() {
      if (condition == 'None') {
        _conditions
          ..clear()
          ..add('None');
        return;
      }
      _conditions.remove('None');
      if (selected) {
        _conditions.add(condition);
      } else {
        _conditions.remove(condition);
      }
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedOption == null) {
      AppSnackbar.error(context, 'Please select a donation preference');
      return;
    }

    final isDonor = _selectedOption == 'Yes';
    final weight = double.tryParse(_weightController.text.trim());

    // Weight is required for donors so eligibility can be evaluated.
    if (isDonor && (weight == null || weight <= 0)) {
      AppSnackbar.error(context, 'Please enter a valid weight in kg');
      return;
    }

    final provider = context.read<UserProvider>();
    final ok = await provider.updateHealthInfo(
      uid: user.uid,
      isDonor: isDonor,
      about: _aboutController.text.trim(),
      weightKg: weight,
      lastDonationDate: _neverDonated ? null : _lastDonationDate,
      healthConditions: _conditions.toList(),
    );

    if (!mounted) return;
    if (ok) {
      await provider.loadCurrentUser();
      if (!mounted) return;
      if (widget.isEditMode) {
        AppSnackbar.success(context, 'Health details updated');
        Navigator.pop(context);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImageScreen()),
        );
      }
    } else {
      final isNetwork = (provider.error ?? '').toLowerCase().contains('network') ||
          (provider.error ?? '').toLowerCase().contains('unavailable');
      AppSnackbar.error(
        context,
        isNetwork
            ? 'No internet connection. Check your network and try again.'
            : 'Could not save your details. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          widget.isEditMode ? 'Update Health Details' : 'Profile Setup',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _loadingExisting
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(theme),
                  Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(theme, 'Donation Preference'),
                        SizedBox(height: 12.h),
                        CustomDropdownFormField(
                          hintText: 'I want to donate blood',
                          value: _selectedOption,
                          items: _donateOptions,
                          itemToString: (item) => item,
                          borderRadius: 12,
                          focusedBorderColor: theme.colorScheme.primary,
                          prefixIcon: Icon(Icons.volunteer_activism_outlined,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                          onChanged: (val) =>
                              setState(() => _selectedOption = val),
                        ),
                        SizedBox(height: 24.h),
                        _sectionTitle(theme, 'Weight'),
                        SizedBox(height: 12.h),
                        CustomTextField(
                          hintText: 'e.g. 65',
                          labelText: 'Weight (kg)',
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d{0,3}(\.\d{0,1})?')),
                          ],
                          suffixText: 'kg',
                          borderRadius: 12,
                          prefixIcon: Icons.monitor_weight_outlined,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: 24.h),
                        _sectionTitle(theme, 'Last Donation'),
                        SizedBox(height: 12.h),
                        _buildLastDonationField(theme),
                        SizedBox(height: 8.h),
                        _buildNeverDonatedToggle(theme),
                        SizedBox(height: 24.h),
                        _sectionTitle(theme, 'Health Conditions'),
                        SizedBox(height: 4.h),
                        Text(
                          'Select any that apply. This helps confirm donation safety.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildConditionChips(theme),
                        SizedBox(height: 24.h),
                        _buildEligibilityBanner(theme),
                        SizedBox(height: 24.h),
                        _sectionTitle(theme, 'About You (Optional)'),
                        SizedBox(height: 12.h),
                        CustomTextField(
                          hintText: 'Tell us a bit about yourself...',
                          maxLines: 4,
                          borderRadius: 12,
                          controller: _aboutController,
                        ),
                        SizedBox(height: 32.h),
                        Consumer<UserProvider>(
                          builder: (context, users, _) => ReusableButton(
                            label: widget.isEditMode ? 'Save' : 'Next',
                            isLoading: users.isLoading,
                            onPressed: _save,
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
      ),
      child: Column(
        children: [
          Icon(Icons.health_and_safety_outlined,
              size: 72.sp, color: theme.colorScheme.primary),
          SizedBox(height: 12.h),
          if (!widget.isEditMode) ...[
            Text(
              'Step 2 of 3',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
          ],
          Text(
            'Health Screening',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      );

  Widget _buildLastDonationField(ThemeData theme) {
    return CustomTextField(
      readOnly: true,
      controller: _lastDonationController,
      hintText: 'Select date',
      labelText: 'Last donation date',
      borderRadius: 12,
      prefixIcon: Icons.calendar_today_outlined,
      onTap: _neverDonated ? null : _pickLastDonationDate,
    );
  }

  Widget _buildNeverDonatedToggle(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() {
        _neverDonated = !_neverDonated;
        if (_neverDonated) _lastDonationDate = null;
        _syncDonationDateText();
      }),
      borderRadius: BorderRadius.circular(8.r),
      child: Row(
        children: [
          Checkbox(
            value: _neverDonated,
            onChanged: (v) => setState(() {
              _neverDonated = v ?? false;
              if (_neverDonated) _lastDonationDate = null;
              _syncDonationDateText();
            }),
          ),
          Text("I haven't donated before",
              style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildConditionChips(ThemeData theme) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: DonationEligibility.selectableConditions.map((c) {
        final selected = _conditions.contains(c);
        return FilterChip(
          label: Text(c),
          selected: selected,
          onSelected: (val) => _toggleCondition(c, val),
          showCheckmark: false,
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12.sp,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEligibilityBanner(ThemeData theme) {
    // Only meaningful once the user opts in to donating.
    if (_selectedOption != 'Yes') return const SizedBox.shrink();

    final result = _draftUser().evaluateEligibility();
    final color = result.isEligible
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final icon = result.isEligible
        ? Icons.check_circle_rounded
        : Icons.info_rounded;

    String message = result.reason;
    if (!result.isEligible && result.nextEligibleDate != null) {
      message =
          '$message Next eligible: ${DateFormat('d MMM yyyy').format(result.nextEligibleDate!)}.';
    }

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
