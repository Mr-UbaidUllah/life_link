import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:blood_donation/provider/ambulance_provider.dart';
import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/bloodGroup_provider.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/provider/organization_provider.dart';
import 'package:blood_donation/provider/organization_storage_provider.dart';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/theme_provider.dart';
import 'package:blood_donation/provider/userPost_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/provider/volunteer_provider.dart';
import 'package:blood_donation/provider/volunteer_storagar_provider.dart';
import 'package:blood_donation/provider/ambulance_storage_provider.dart';

class AppProviders {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthProviders()),
    ChangeNotifierProvider(create: (_) => StorageProvider()),
    ChangeNotifierProvider(create: (_) => BloodrequestProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => UserPostsProvider()),
    ChangeNotifierProvider(create: (_) => BloodGroupRequestProvider()),
    ChangeNotifierProvider(create: (_) => OrganizationProvider()),
    ChangeNotifierProvider(create: (_) => OrganizationStorageProvider()),
    ChangeNotifierProvider(create: (_) => AmbulanceProvider()),
    ChangeNotifierProvider(create: (_) => AmbulanceStorageProvider()),
    ChangeNotifierProvider(create: (_) => VolunteerProvider()),
    ChangeNotifierProvider(create: (_) => volunteerStorageProvider()),
    ChangeNotifierProvider(create: (_) => MessageProvider()),
  ];
}
