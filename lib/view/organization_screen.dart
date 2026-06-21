import 'package:blood_donation/models/organization_model.dart';
import 'package:blood_donation/provider/organization_provider.dart';
import 'package:blood_donation/view/add_organization_screen.dart';
import 'package:blood_donation/widgets/organization_card.dart';
import 'package:blood_donation/widgets/refresh_helpers.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  late Stream<List<OrganizationModel>> _orgStream;
  String _searchQuery = '';
  OrganizationType? _selectedType;

  @override
  void initState() {
    super.initState();
    _orgStream = context.read<OrganizationProvider>().requests;
  }

  Future<void> _refresh() async {
    setState(() {
      _orgStream = context.read<OrganizationProvider>().requests;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          'Healthcare Partners',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20.sp,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 15.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search partners...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                  ),
                ),
                SizedBox(height: 12.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(null, 'All'),
                      SizedBox(width: 8.w),
                      ...OrganizationType.values.map((type) => Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: _buildFilterChip(type, type.name.toUpperCase()),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: theme.colorScheme.primary,
              child: StreamBuilder<List<OrganizationModel>>(
                stream: _orgStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ShimmerList(
                      itemCount: 5,
                      itemBuilder: (_, __) => const ContactCardSkeleton(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return RefreshableFill(child: _buildEmptyState(theme));
                  }

                  final organizations = snapshot.data!.where((org) {
                    final matchesSearch = org.name.toLowerCase().contains(_searchQuery) ||
                                         org.city.toLowerCase().contains(_searchQuery);
                    final matchesType = _selectedType == null || org.type == _selectedType;
                    return matchesSearch && matchesType;
                  }).toList();

                  if (organizations.isEmpty) {
                    return RefreshableFill(child: _buildEmptyState(theme, message: "No partners match your filters"));
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.all(20.w),
                    itemCount: organizations.length,
                    itemBuilder: (context, index) {
                      return OrganizationCard(
                        organization: organizations[index],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOrganizationScreen()),
          );
        },
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: Text('Become a Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
      ),
    );
  }

  Widget _buildFilterChip(OrganizationType? type, String label) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedType = selected ? type : null);
      },
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: 11.sp,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState(ThemeData theme, {String message = "No partners found"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 80.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
