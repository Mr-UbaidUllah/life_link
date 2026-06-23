import 'dart:io';
import 'package:blood_donation/core/constants/app_constants.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/widgets/app_snackbar.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _aboutController;

  // Country/city are pickers (not free text) so an edited profile keeps the
  // exact canonical values the notification matching compares against. See
  // app_constants.kCountryCities — the single source shared with create-request.
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedBloodGroup;
  bool _isDonor = false;
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _aboutController = TextEditingController(text: widget.user.about);

    // Only restore a saved value if it's still a valid picker option, otherwise
    // the dropdown would assert on an item that isn't in its list (e.g. a city
    // saved under the old free-text field or a since-removed value). A dropped
    // value just shows as unselected and the validator makes the user re-pick.
    if (widget.user.bloodGroup != null &&
        kBloodGroups.contains(widget.user.bloodGroup)) {
      _selectedBloodGroup = widget.user.bloodGroup;
    }
    if (widget.user.country != null &&
        kCountryCities.containsKey(widget.user.country)) {
      _selectedCountry = widget.user.country;
      if (widget.user.city != null &&
          (kCountryCities[_selectedCountry] ?? const [])
              .contains(widget.user.city)) {
        _selectedCity = widget.user.city;
      }
    }
    _isDonor = widget.user.isDonor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    // The picker foregrounds another activity; guard against returning to a
    // disposed widget (setState-after-dispose).
    if (!mounted) return;
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    // Re-entrancy guard: _isLoading only disables the button on the next
    // rebuild, so a same-frame double-tap could otherwise upload + save twice.
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final storageProvider =
        Provider.of<StorageProvider>(context, listen: false);

    try {
      if (_image != null) {
        final uploaded =
            await storageProvider.uploadImage(widget.user.uid, _image!);
        if (!uploaded) {
          throw Exception('Failed to upload profile image');
        }
      }

      // Update the donor flag if it changed. toggleDonate is the ONLY thing
      // that persists isDonor here (updatePersonalInfo doesn't touch it), so a
      // failure must abort — otherwise we'd report "updated" with the donor
      // toggle silently un-saved.
      if (_isDonor != widget.user.isDonor) {
        final donorOk = await userProvider.toggleDonate(_isDonor);
        if (!donorOk) {
          throw Exception(
              userProvider.error ?? 'Could not update your donor status');
        }
      }

      final success = await userProvider.updatePersonalInfo(
        uid: widget.user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bloodGroup: _selectedBloodGroup ?? '',
        country: _selectedCountry ?? '',
        city: _selectedCity ?? '',
        about: _aboutController.text.trim(),
      );

      if (success) {
        await userProvider.loadCurrentUser();
        if (mounted) {
          AppSnackbar.success(context, 'Profile updated successfully');
          Navigator.pop(context);
        }
      } else {
        throw Exception(userProvider.error ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
            context, e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
        ),
        title: Text('Edit Profile', style: theme.textTheme.titleLarge),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildAvatarHeader(theme),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 32.h),
              child: Column(
                children: Stagger.children([
                  _buildPersonalSection(theme),
                  SizedBox(height: 16.h),
                  _buildMedicalSection(theme),
                  SizedBox(height: 16.h),
                  _buildLocationSection(theme),
                  SizedBox(height: 28.h),
                  _buildSaveButton(theme),
                ], step: const Duration(milliseconds: 55)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------- Avatar header

  Widget _buildAvatarHeader(ThemeData theme) {
    final hasNetwork = widget.user.profileImage != null &&
        widget.user.profileImage!.isNotEmpty;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.hero),
      padding: EdgeInsets.only(top: 8.h, bottom: 26.h),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5), width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 52.r,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (hasNetwork
                          ? NetworkImage(widget.user.profileImage!)
                          : null) as ImageProvider?,
                  child: _image == null && !hasNetwork
                      ? Icon(Icons.person_rounded,
                          size: 52.r, color: Colors.white)
                      : null,
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: EdgeInsets.all(9.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 18.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Tap the camera to change photo',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Sections

  Widget _buildPersonalSection(ThemeData theme) {
    return _FormSection(
      icon: Icons.person_outline_rounded,
      color: AppColors.primary,
      title: 'Personal Details',
      children: [
        CustomTextField(
          controller: _nameController,
          labelText: 'Full Name',
          hintText: 'Enter your name',
          prefixIcon: Icons.person_outline_rounded,
          focusedBorderColor: theme.colorScheme.primary,
          borderRadius: AppRadii.md.r,
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.isEmpty) return 'Please enter your name';
            if (name.length < 3) return 'Name must be at least 3 characters';
            return null;
          },
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _phoneController,
          labelText: 'Phone Number',
          hintText: 'Enter your phone number',
          prefixIcon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          focusedBorderColor: theme.colorScheme.primary,
          borderRadius: AppRadii.md.r,
          // Match the setup screen: digits only, 10–11 chars, so a saved
          // profile can't end up with an empty/garbage number that breaks the
          // Call button on the profile screen.
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          validator: (value) {
            final phone = value?.trim() ?? '';
            if (phone.isEmpty) return 'Please enter your phone number';
            if (phone.length < 10) return 'Enter a valid phone number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMedicalSection(ThemeData theme) {
    return _FormSection(
      icon: Icons.bloodtype_rounded,
      color: AppColors.danger,
      title: 'Medical Information',
      children: [
        CustomDropdownFormField<String>(
          value: _selectedBloodGroup,
          items: kBloodGroups,
          itemToString: (value) => value,
          labelText: 'Blood Group',
          hintText: 'Select your blood group',
          onChanged: (val) => setState(() => _selectedBloodGroup = val),
          validator: (value) =>
              value == null ? 'Please select your blood group' : null,
          prefixIcon: Icon(Icons.bloodtype_rounded,
              color: AppColors.danger, size: 22.sp),
          borderRadius: AppRadii.md.r,
        ),
        SizedBox(height: 16.h),
        // Donor opt-in as a prominent switch row.
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: _isDonor
                ? AppColors.green.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.md.r),
            border: Border.all(
                color: _isDonor
                    ? AppColors.green.withValues(alpha: 0.3)
                    : theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Icon(Icons.volunteer_activism_rounded,
                  size: 20.sp,
                  color: _isDonor
                      ? AppColors.green
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available to donate',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14.sp)),
                    Text(
                        _isDonor
                            ? 'You\'ll appear in donor searches'
                            : 'Opt in to help others',
                        style: TextStyle(
                            fontSize: 11.5.sp,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isDonor,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.green,
                onChanged: (val) => setState(() => _isDonor = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return _FormSection(
      icon: Icons.location_on_outlined,
      color: AppColors.info,
      title: 'Location & Bio',
      children: [
        CustomDropdownFormField<String>(
          value: _selectedCountry,
          items: kCountryCities.keys.toList(),
          itemToString: (value) => value,
          labelText: 'Country',
          hintText: 'Select your country',
          prefixIcon: Icon(Icons.public_rounded,
              color: AppColors.info, size: 22.sp),
          borderRadius: AppRadii.md.r,
          validator: (value) =>
              value == null ? 'Please select your country' : null,
          // Changing country invalidates the previously-picked city.
          onChanged: (val) => setState(() {
            _selectedCountry = val;
            _selectedCity = null;
          }),
        ),
        SizedBox(height: 16.h),
        CustomDropdownFormField<String>(
          value: _selectedCity,
          items: kCountryCities[_selectedCountry] ?? const [],
          itemToString: (value) => value,
          labelText: 'City',
          hintText: 'Select your city',
          prefixIcon: Icon(Icons.location_city_rounded,
              color: AppColors.info, size: 22.sp),
          borderRadius: AppRadii.md.r,
          enabled: _selectedCountry != null,
          validator: (value) =>
              value == null ? 'Please select your city' : null,
          onChanged: (val) => setState(() => _selectedCity = val),
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _aboutController,
          labelText: 'About Me',
          hintText: 'Write a short bio...',
          prefixIcon: Icons.info_outline_rounded,
          maxLines: 4,
          borderRadius: AppRadii.md.r,
        ),
      ],
    );
  }

  // ------------------------------------------------------------- Save button

  Widget _buildSaveButton(ThemeData theme) {
    return TapScale(
      onTap: _isLoading ? null : _updateProfile,
      child: Container(
        width: double.infinity,
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppGradients.hero,
          borderRadius: BorderRadius.circular(AppRadii.md.r),
          boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.3),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24.h,
                width: 24.h,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text('Save Changes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800)),
      ),
    );
  }
}

/// A titled form group: colored icon chip + section title above a bordered
/// card holding the fields.
class _FormSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;

  const _FormSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm.r),
              ),
              child: Icon(icon, size: 17.sp, color: color),
            ),
            SizedBox(width: 10.w),
            Text(title,
                style: TextStyle(
                    fontSize: 15.sp, fontWeight: FontWeight.w800)),
          ],
        ),
        SizedBox(height: 14.h),
        AppCard(
          padding: EdgeInsets.all(16.r),
          child: Column(children: children),
        ),
      ],
    );
  }
}
