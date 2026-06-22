import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// Services (registered once as app-wide singletons)
import 'package:blood_donation/services/ambulance_service.dart';
import 'package:blood_donation/services/auth_service.dart';
import 'package:blood_donation/services/blood_group_service.dart';
import 'package:blood_donation/services/blood_request_service.dart';
import 'package:blood_donation/services/chat_service.dart';
import 'package:blood_donation/services/organization_service.dart';
import 'package:blood_donation/services/storage_service.dart';
import 'package:blood_donation/services/user_service.dart';
import 'package:blood_donation/services/user_post_service.dart';
import 'package:blood_donation/services/volunteer_service.dart';

// Providers
import 'package:blood_donation/provider/ambulance_provider.dart';
import 'package:blood_donation/provider/ambulance_storage_provider.dart';
import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/blood_group_provider.dart';
import 'package:blood_donation/provider/blood_request_provider.dart';
import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/provider/network_provider.dart';
import 'package:blood_donation/provider/organization_provider.dart';
import 'package:blood_donation/provider/organization_storage_provider.dart';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/theme_provider.dart';
import 'package:blood_donation/provider/user_post_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/provider/volunteer_provider.dart';
import 'package:blood_donation/provider/volunteer_storagar_provider.dart';

/// App-wide dependency graph.
///
/// Services are registered once (single instance shared across the whole app)
/// and injected into the ChangeNotifier providers that depend on them, so
/// nothing instantiates Firebase wrappers ad-hoc and everything is mockable.
class AppProviders {
  static List<SingleChildWidget> providers = [
    // ---- Services: app-wide singletons ----
    Provider<AuthService>(create: (_) => AuthService()),
    Provider<UserFirestoreService>(create: (_) => UserFirestoreService()),
    Provider<StorageService>(create: (_) => StorageService()),
    Provider<BloodRequestService>(create: (_) => BloodRequestService()),
    Provider<BloodgroupService>(create: (_) => BloodgroupService()),
    Provider<UserPostsService>(create: (_) => UserPostsService()),
    Provider<OrganizationService>(create: (_) => OrganizationService()),
    Provider<AmbulanceService>(create: (_) => AmbulanceService()),
    Provider<VolunteerService>(create: (_) => VolunteerService()),
    Provider<ChatService>(create: (_) => ChatService()),

    // ---- UI/app-state providers ----
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => NetworkProvider()),

    ChangeNotifierProxyProvider<AuthService, AuthProviders>(
      create: (context) =>
          AuthProviders(authService: context.read<AuthService>()),
      update: (context, authService, previous) =>
          previous ?? AuthProviders(authService: authService),
    ),

    ChangeNotifierProvider(
      create: (c) => StorageProvider(
        storageService: c.read<StorageService>(),
        userService: c.read<UserFirestoreService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) =>
          BloodrequestProvider(service: c.read<BloodRequestService>()),
    ),
    ChangeNotifierProvider(
      create: (c) => UserProvider(service: c.read<UserFirestoreService>()),
    ),
    ChangeNotifierProvider(
      create: (c) => UserPostsProvider(service: c.read<UserPostsService>()),
    ),
    ChangeNotifierProvider(
      create: (c) =>
          BloodGroupRequestProvider(service: c.read<BloodgroupService>()),
    ),
    ChangeNotifierProvider(
      create: (c) =>
          OrganizationProvider(service: c.read<OrganizationService>()),
    ),
    ChangeNotifierProvider(
      create: (c) => OrganizationStorageProvider(
        storageService: c.read<StorageService>(),
        organizationService: c.read<OrganizationService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => AmbulanceProvider(service: c.read<AmbulanceService>()),
    ),
    ChangeNotifierProvider(
      create: (c) => AmbulanceStorageProvider(
        storageService: c.read<StorageService>(),
        ambulanceService: c.read<AmbulanceService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => VolunteerProvider(service: c.read<VolunteerService>()),
    ),
    ChangeNotifierProvider(
      create: (c) => volunteerStorageProvider(
        storageService: c.read<StorageService>(),
        volunteerService: c.read<VolunteerService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => MessageProvider(service: c.read<ChatService>()),
    ),
  ];
}
