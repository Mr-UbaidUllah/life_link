import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/provider/ambulance_provider.dart';
import 'package:blood_donation/view/add_ambulance.dart';
import 'package:blood_donation/widgets/ambulence_card.dart';
import 'package:blood_donation/widgets/refresh_helpers.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  late Stream<List<AmbulanceModel>> _ambulanceStream;
  AmbulanceType? selectedFilter;

  @override
  void initState() {
    super.initState();
    _ambulanceStream = context.read<AmbulanceProvider>().ambulanceRequest;
  }

  // Re-subscribe to the directory so a pull forces a fresh Firestore query.
  Future<void> _refresh() async {
    setState(() {
      _ambulanceStream = context.read<AmbulanceProvider>().ambulanceRequest;
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
          'Emergency Ambulance',
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
          // Info Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
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
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.emergency_rounded, color: theme.colorScheme.primary, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Quickly find and contact nearby ambulance services for emergencies.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: selectedFilter == null,
                  onSelected: (val) => setState(() => selectedFilter = null),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: theme.colorScheme.primary,
                ),
                SizedBox(width: 8.w),
                ...AmbulanceType.values.map((type) => Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    label: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                    selected: selectedFilter == type,
                    onSelected: (val) => setState(() => selectedFilter = val ? type : null),
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                )),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: theme.colorScheme.primary,
              child: Consumer<AmbulanceProvider>(
                builder: (context, _, __) {
                  return StreamBuilder<List<AmbulanceModel>>(
                    stream: _ambulanceStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ShimmerList(
                          itemCount: 5,
                          itemBuilder: (_, __) => const ContactCardSkeleton(),
                        );
                      }

                      if (snapshot.hasError) {
                        return RefreshableFill(
                          child: Center(
                            child: Text('Something went wrong', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                          ),
                        );
                      }

                      var requests = snapshot.data ?? [];
                      if (selectedFilter != null) {
                        requests = requests.where((element) => element.type == selectedFilter).toList();
                      }

                      if (requests.isEmpty) {
                        return RefreshableFill(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bus_alert_rounded, size: 80.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                SizedBox(height: 16.h),
                                Text(
                                  "No ambulances found",
                                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          return AmbulenceCard(ambulance: requests[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAmbulance()),
          );
        },
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
    );
  }
}
