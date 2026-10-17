// import 'package:field_survey/screens/profile/EditProfilePage.dart';
import 'package:field_survey/screens/profile/ProfilPage.dart';
import 'package:field_survey/screens/survey/DaftarSurvey.dart';
import 'package:field_survey/screens/survey/SurveyForm.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login.dart';
import '../screens/dashboard/dashboard.dart';
import '../screens/auth/register.dart';
import 'app_routes.dart';

class AppPages {
  static final router = GoRouter(
    initialLocation: AppRoutes.splash,

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashScreen(),
      ),

      GoRoute(
        path: AppRoutes.Login,
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegisterPage(),
      ),

      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => DashboardPage(user: const {}),
      ),

      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) {
          // Aman dari crash jika state.extra null
          final user = (state.extra as Map<String, dynamic>?) ?? {};

          return ProfilePage(user: user);
        },
      ),

      GoRoute(
        path: AppRoutes.SurveyForm,
        builder: (context, state) => SurveyFormPage(),
      ),

      GoRoute(
        path: AppRoutes.surveyDaftar,
        builder: (context, state) => SurveyPage(),
      ),
    ],
  );
}
