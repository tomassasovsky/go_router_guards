---
title: Authentication Example
description: Complete authentication flow implementation with Go Router Guards
---

import { Steps, Tabs, TabItem } from '@astrojs/starlight/components';

This example demonstrates a complete authentication system using Go Router Guards with state management, protected routes, and user flows.

## Project Setup

<Steps>

1. **Dependencies**

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     go_router: ^14.0.0
     go_router_guards: ^1.0.0
     flutter_bloc: ^8.1.3
     
   dev_dependencies:
     go_router_builder: ^3.0.1
     build_runner: ^2.4.8
   ```

2. **State Management**

   ```dart
   // lib/auth/auth_bloc.dart
   import 'package:flutter_bloc/flutter_bloc.dart';
   import 'package:equatable/equatable.dart';

   // Events
   abstract class AuthEvent extends Equatable {
     @override
     List<Object?> get props => [];
   }

   class AuthLogin extends AuthEvent {
     final String email;
     final String password;
     
     AuthLogin({required this.email, required this.password});
     
     @override
     List<Object?> get props => [email, password];
   }

   class AuthLogout extends AuthEvent {}

   class AuthCheckStatus extends AuthEvent {}

   // States
   abstract class AuthState extends Equatable {
     @override
     List<Object?> get props => [];
   }

   class AuthInitial extends AuthState {}

   class AuthLoading extends AuthState {}

   class AuthAuthenticated extends AuthState {
     final User user;
     
     AuthAuthenticated({required this.user});
     
     @override
     List<Object?> get props => [user];
   }

   class AuthUnauthenticated extends AuthState {}

   class AuthError extends AuthState {
     final String message;
     
     AuthError({required this.message});
     
     @override
     List<Object?> get props => [message];
   }

   // BLoC
   class AuthBloc extends Bloc<AuthEvent, AuthState> {
     final AuthService _authService;

     AuthBloc({required AuthService authService})
         : _authService = authService,
           super(AuthInitial()) {
       on<AuthLogin>(_onLogin);
       on<AuthLogout>(_onLogout);
       on<AuthCheckStatus>(_onCheckStatus);
     }

     Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
       emit(AuthLoading());
       try {
         final user = await _authService.login(event.email, event.password);
         emit(AuthAuthenticated(user: user));
       } catch (error) {
         emit(AuthError(message: error.toString()));
       }
     }

     Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
       await _authService.logout();
       emit(AuthUnauthenticated());
     }

     Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
       emit(AuthLoading());
       try {
         final user = await _authService.getCurrentUser();
         if (user != null) {
           emit(AuthAuthenticated(user: user));
         } else {
           emit(AuthUnauthenticated());
         }
       } catch (error) {
         emit(AuthUnauthenticated());
       }
     }
   }
   ```

3. **User Model**

   ```dart
   // lib/models/user.dart
   import 'package:equatable/equatable.dart';

   class User extends Equatable {
     final String id;
     final String email;
     final String name;
     final List<String> roles;
     final DateTime? lastLogin;

     const User({
       required this.id,
       required this.email,
       required this.name,
       this.roles = const ['user'],
       this.lastLogin,
     });

     bool hasRole(String role) => roles.contains(role);
     bool hasAnyRole(List<String> requiredRoles) => 
         requiredRoles.any(roles.contains);

     @override
     List<Object?> get props => [id, email, name, roles, lastLogin];
   }
   ```

</Steps>

## Authentication Service

```dart
// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  final SharedPreferences _prefs;
  
  AuthService({required SharedPreferences prefs}) : _prefs = prefs;

  /// Login with email and password
  Future<User> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock authentication logic
    if (email == 'admin@example.com' && password == 'admin123') {
      final user = User(
        id: '1',
        email: email,
        name: 'Admin User',
        roles: ['admin', 'user'],
        lastLogin: DateTime.now(),
      );
      
      // Store token and user data
      await _prefs.setString(_tokenKey, 'mock_token_${user.id}');
      await _prefs.setString(_userKey, jsonEncode(user.toJson()));
      
      return user;
    } else if (email == 'user@example.com' && password == 'user123') {
      final user = User(
        id: '2',
        email: email,
        name: 'Regular User',
        roles: ['user'],
        lastLogin: DateTime.now(),
      );
      
      await _prefs.setString(_tokenKey, 'mock_token_${user.id}');
      await _prefs.setString(_userKey, jsonEncode(user.toJson()));
      
      return user;
    }
    
    throw Exception('Invalid credentials');
  }

  /// Get current authenticated user
  Future<User?> getCurrentUser() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null) return null;
    
    final userData = _prefs.getString(_userKey);
    if (userData == null) return null;
    
    try {
      final userMap = jsonDecode(userData) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (error) {
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Logout user
  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  /// Check if token is valid (simulate API call)
  Future<bool> validateToken() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final token = _prefs.getString(_tokenKey);
    return token != null && token.startsWith('mock_token_');
  }
}
```

## Authentication Guards

```dart
// lib/guards/auth_guard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_guards/go_router_guards.dart';
import '../auth/auth_bloc.dart';
import '../routes/app_routes.dart';

class AuthGuard extends GoRouterGuard {
  const AuthGuard();

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final authState = context.read<AuthBloc>().state;
    
    switch (authState) {
      case AuthAuthenticated():
        resolver.next();
        
      case AuthUnauthenticated():
        resolver.redirect(LoginRoute().location);
        
      case AuthLoading():
        // Wait a moment for auth to complete or redirect to loading page
        resolver.redirect(LoadingRoute().location);
        
      case AuthError():
        resolver.redirect(LoginRoute().location);
        
      case AuthInitial():
        // Check auth status first
        context.read<AuthBloc>().add(AuthCheckStatus());
        resolver.redirect(LoadingRoute().location);
    }
  }
}

// Role-based guard
class RoleGuard extends GoRouterGuard {
  const RoleGuard(this.requiredRoles);
  
  final List<String> requiredRoles;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is AuthAuthenticated) {
      final hasRequiredRole = authState.user.hasAnyRole(requiredRoles);
      if (hasRequiredRole) {
        resolver.next();
      } else {
        resolver.redirect(UnauthorizedRoute().location);
      }
    } else {
      resolver.redirect(LoginRoute().location);
    }
  }
}

// Guest guard (redirects authenticated users)
class GuestGuard extends GoRouterGuard {
  const GuestGuard();

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is AuthAuthenticated) {
      resolver.redirect(DashboardRoute().location);
    } else {
      resolver.next();
    }
  }
}
```

## Route Definitions

<Tabs>
  <TabItem label="Type-Safe Routes">
    ```dart
    // lib/routes/app_routes.dart
    import 'package:flutter/material.dart';
    import 'package:go_router/go_router.dart';
    import 'package:go_router_guards/go_router_guards.dart';
    import '../guards/auth_guard.dart';
    import '../screens/screens.dart';

    part 'app_routes.g.dart';

    // Public routes
    @TypedGoRoute<HomeRoute>(
      path: '/',
      routes: [
        TypedGoRoute<LoginRoute>(path: '/login'),
        TypedGoRoute<RegisterRoute>(path: '/register'),
        TypedGoRoute<LoadingRoute>(path: '/loading'),
        TypedGoRoute<UnauthorizedRoute>(path: '/unauthorized'),
      ],
    )
    class HomeRoute extends GoRouteData {
      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const HomeScreen();
      }
    }

    // Login route (guests only)
    class LoginRoute extends GoRouteData with GuardedRoute {
      @override
      RouteGuard get guards => const GuestGuard();

      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const LoginScreen();
      }
    }

    // Register route (guests only)
    class RegisterRoute extends GoRouteData with GuardedRoute {
      @override
      RouteGuard get guards => const GuestGuard();

      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      }
    }

    // Loading route (no guards)
    class LoadingRoute extends GoRouteData with UnguardedRoute {
      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const LoadingScreen();
      }
    }

    // Unauthorized route (no guards)
    class UnauthorizedRoute extends GoRouteData with UnguardedRoute {
      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const UnauthorizedScreen();
      }
    }

    // Protected routes
    @TypedGoRoute<DashboardRoute>(
      path: '/dashboard',
      routes: [
        TypedGoRoute<ProfileRoute>(path: '/profile'),
        TypedGoRoute<SettingsRoute>(path: '/settings'),
        TypedGoRoute<AdminRoute>(path: '/admin'),
      ],
    )
    class DashboardRoute extends GoRouteData with GuardedRoute {
      @override
      RouteGuard get guards => const AuthGuard();

      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const DashboardScreen();
      }
    }

    // User profile (authenticated users)
    class ProfileRoute extends GoRouteData with GuardedRoute {
      @override
      RouteGuard get guards => const AuthGuard();

      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      }
    }

    // Settings (authenticated users)
    class SettingsRoute extends GoRouteData with GuardedRoute {
      @override
      RouteGuard get guards => const AuthGuard();

      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      }
    }

    // Admin panel (admin users only)
    class AdminRoute extends GoRouteData with GuardedRoute {
      @override
      RouteGuard get guards => Guards.all([
        const AuthGuard(),
        const RoleGuard(['admin']),
      ]);

      @override
      Widget build(BuildContext context, GoRouterState state) {
        return const AdminScreen();
      }
    }
    ```
  </TabItem>
  
  <TabItem label="Traditional Routes">
    ```dart
    // lib/routes/traditional_routes.dart
    import 'package:flutter/material.dart';
    import 'package:go_router/go_router.dart';
    import 'package:go_router_guards/go_router_guards.dart';
    import '../guards/auth_guard.dart';
    import '../screens/screens.dart';

    final appRouter = GoRouter(
      initialLocation: '/',
      routes: [
        // Public routes
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        
        // Guest-only routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
          redirect: RouteGuardUtils.createGuardRedirect(
            const GuestGuard(),
          ),
        ),
        
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
          redirect: RouteGuardUtils.createGuardRedirect(
            const GuestGuard(),
          ),
        ),
        
        // Unguarded utility routes
        GoRoute(
          path: '/loading',
          builder: (context, state) => const LoadingScreen(),
        ),
        
        GoRoute(
          path: '/unauthorized',
          builder: (context, state) => const UnauthorizedScreen(),
        ),
        
        // Protected routes
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
          redirect: RouteGuardUtils.createGuardRedirect(
            const AuthGuard(),
          ),
        ),
        
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          redirect: RouteGuardUtils.createGuardRedirect(
            const AuthGuard(),
          ),
        ),
        
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
          redirect: RouteGuardUtils.createGuardRedirect(
            const AuthGuard(),
          ),
        ),
        
        // Admin-only route
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminScreen(),
          redirect: RouteGuardUtils.createGuardRedirect(
            Guards.all([
              const AuthGuard(),
              const RoleGuard(['admin']),
            ]),
          ),
        ),
      ],
    );
    ```
  </TabItem>
</Tabs>

## Screen Implementations

```dart
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            DashboardRoute().go(context);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<AuthBloc>().add(
                          AuthLogin(
                            email: _emailController.text,
                            password: _passwordController.text,
                          ),
                        );
                      }
                    },
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => RegisterRoute().go(context),
                    child: const Text('Don\'t have an account? Register'),
                  ),
                  const SizedBox(height: 32),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Demo Credentials:'),
                          Text('Admin: admin@example.com / admin123'),
                          Text('User: user@example.com / user123'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

```dart
// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';
import '../routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogout());
              HomeRoute().go(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${state.user.name}!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Email: ${state.user.email}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Roles: ${state.user.roles.join(', ')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _DashboardCard(
                          title: 'Profile',
                          icon: Icons.person,
                          onTap: () => ProfileRoute().go(context),
                        ),
                        _DashboardCard(
                          title: 'Settings',
                          icon: Icons.settings,
                          onTap: () => SettingsRoute().go(context),
                        ),
                        if (state.user.hasRole('admin'))
                          _DashboardCard(
                            title: 'Admin Panel',
                            icon: Icons.admin_panel_settings,
                            onTap: () => AdminRoute().go(context),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
```

## App Setup

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/auth_bloc.dart';
import 'services/auth_service.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService(prefs: prefs);
  
  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authService});
  
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(authService: authService)
        ..add(AuthCheckStatus()), // Check auth status on app start
      child: MaterialApp.router(
        title: 'Auth Demo',
        routerConfig: GoRouter(
          routes: $appRoutes, // Generated routes
          // Optional: Add global redirect for router-level protection
          // redirect: RouteGuardUtils.createGuardRedirect(
          //   ConditionalGuard(
          //     guard: AuthGuard(),
          //     excludedPaths: ['/', '/login', '/register', '/loading', '/unauthorized'],
          //   ),
          // ),
        ),
      ),
    );
  }
}
```

## Testing the Authentication Flow

```dart
// test/auth_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import '../lib/auth/auth_bloc.dart';
import '../lib/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('Authentication Flow', () {
    late MockAuthService mockAuthService;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthService = MockAuthService();
      authBloc = AuthBloc(authService: mockAuthService);
    });

    testWidgets('login flow redirects to dashboard on success', (tester) async {
      // Arrange
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) async => const User(
            id: '1',
            email: 'test@example.com',
            name: 'Test User',
          ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const LoginScreen(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Assert
      verify(() => mockAuthService.login('test@example.com', 'password123')).called(1);
    });

    testWidgets('protected route redirects unauthenticated users', (tester) async {
      // Test implementation for protected routes
    });
  });
}
```

## Key Features Demonstrated

1. **Complete Authentication Flow**: Login, logout, and session management
2. **Role-Based Access Control**: Different guards for different user types
3. **Guest Protection**: Prevent authenticated users from accessing login/register
4. **State Management Integration**: Works seamlessly with BLoC
5. **Error Handling**: Proper error states and user feedback
6. **Type-Safe Routes**: Compile-time route safety with guards
7. **Flexible Guard Combinations**: Multiple protection layers

## Next Steps

- 🛡️ Explore [Role-Based Access](/examples/role-based-access/)
- 🔒 Learn about [Permission Guards](/examples/permission-guards/)
- 🏗️ See [Multi-Layer Protection](/examples/multi-layer-protection/)
- 📋 Review [Best Practices](/guides/best-practices/)
