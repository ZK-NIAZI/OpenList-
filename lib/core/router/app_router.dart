import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/features/auth/presentation/login_screen.dart';
import 'package:openlist/features/auth/presentation/signup_screen.dart';
import 'package:openlist/features/navigation/presentation/main_navigation.dart';
import 'package:openlist/features/splash/presentation/splash_screen.dart';
import 'package:openlist/features/task/presentation/task_detail_screen.dart';
import 'package:openlist/features/settings/presentation/settings_screen.dart';
import 'package:openlist/features/search/presentation/search_screen.dart';
import 'package:openlist/features/upcoming/presentation/upcoming_screen.dart';

// Providers
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final String location = state.matchedLocation;
      
      print('📍 Redirect check - Location: $location, isLoggedIn: $isLoggedIn');
      
      // Allow splash screen
      if (location == '/') {
        return null;
      }
      
      // If not logged in, only allow access to login and signup
      if (!isLoggedIn) {
        if (location == '/login' || location == '/signup') {
          return null; // Allow access
        }
        return '/login'; // Redirect to login
      }
      
      // If logged in, don't allow access to auth pages
      if (isLoggedIn && (location == '/login' || location == '/signup')) {
        return '/dashboard';
      }
      
      // Allow access to all other routes
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Public routes (no auth needed)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Protected routes (auth needed)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const MainNavigation(),
      ),
      
      // Task detail routes
      GoRoute(
        path: '/task/:id',
        name: 'taskDetail',
        builder: (context, state) {
          final taskId = state.pathParameters['id'];
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/task/:id/section/:sectionId',
        name: 'sectionDetail',
        builder: (context, state) {
          final taskId = state.pathParameters['id'] ?? '';
          final sectionId = state.pathParameters['sectionId'] ?? '';
          return Scaffold(
            body: Center(child: Text('Section Detail: $taskId / $sectionId - To be implemented')),
          );
        },
      ),
      
      // Note detail
      GoRoute(
        path: '/note/:id',
        name: 'noteDetail',
        builder: (context, state) {
          final noteId = state.pathParameters['id'] ?? '';
          return Scaffold(
            body: Center(child: Text('Note Detail: $noteId - To be implemented')),
          );
        },
      ),
      
      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Search
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      
      // Upcoming
      GoRoute(
        path: '/upcoming',
        name: 'upcoming',
        builder: (context, state) => const UpcomingScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404 - Page Not Found'),
            Text('Location: ${state.matchedLocation}'),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});