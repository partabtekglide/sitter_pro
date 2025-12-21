import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/client_list/client_list.dart';
import '../presentation/sitter_profile_setup/sitter_profile_setup.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/client_profile/client_profile.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/new_booking/new_booking.dart';
import '../presentation/calendar_view/calendar_view.dart';
import '../presentation/communication_hub/communication_hub.dart';
import '../presentation/financial_dashboard/financial_dashboard.dart';
import '../presentation/job_check_in/job_check_in.dart';
import '../presentation/settings/settings.dart';
import '../presentation/signup_screen/signup_screen.dart';
import '../presentation/notifications/notifications_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String clientList = '/client-list';
  static const String sitterProfileSetup = '/sitter-profile-setup';
  static const String login = '/login-screen';
  static const String clientProfile = '/client-profile';
  static const String dashboard = '/dashboard';
  static const String newBooking = '/new-booking';
  static const String calendarView = '/calendar-view';
  static const String communicationHub = '/communication-hub';
  static const String financialDashboard = '/financial-dashboard';
  static const String jobCheckIn = '/job-check-in';
  static const String settings = '/settings';
  static const String signupScreen = '/signup-screen';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    clientList: (context) => const ClientList(),
    sitterProfileSetup: (context) => const SitterProfileSetup(),
    login: (context) => const LoginScreen(),
    clientProfile: (context) => const ClientProfile(),
    dashboard: (context) => const Dashboard(),
    newBooking: (context) => const NewBooking(),
    calendarView: (context) => const CalendarView(),
    communicationHub: (context) => const CommunicationHub(),
    financialDashboard: (context) => const FinancialDashboard(),
    jobCheckIn: (context) => const JobCheckIn(),
    settings: (context) => const Settings(),
    signupScreen: (context) => const SignupScreen(),
    notifications: (context) => const NotificationsScreen(),
    // TODO: Add your other routes here
  };
}
