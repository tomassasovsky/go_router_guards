---
title: Type-Safe Routes
description: Learn how to use GuardedRoute and UnguardedRoute mixins with Go Router's type-safe routing
---

import { Steps, Tabs, TabItem } from '@astrojs/starlight/components';

Type-safe routes with Go Router provide compile-time safety and better development experience. Go Router Guards seamlessly integrates with this system through specialized mixins.

## Prerequisites

Before using type-safe routes with guards, ensure you have:

- `go_router_builder` added to your `dev_dependencies`
- Build runner set up for code generation
- Basic understanding of Go Router's type-safe routing

```yaml
dev_dependencies:
  go_router_builder: ^3.0.1
  build_runner: ^2.4.8
```

## GuardedRoute Mixin

The `GuardedRoute` mixin adds automatic guard execution to your type-safe routes.

### Basic Usage

<Steps>

1. **Define Your Route**

   ```dart
   @TypedGoRoute<ProfileRoute>(path: '/profile')
   class ProfileRoute extends GoRouteData with GuardedRoute {
     const ProfileRoute();
   }
   ```

2. **Add Guard Logic**

   ```dart
   @TypedGoRoute<ProfileRoute>(path: '/profile')
   class ProfileRoute extends GoRouteData with GuardedRoute {
     const ProfileRoute();

     @override
     RouteGuard get guards => AuthGuard();

     @override
     Widget build(BuildContext context, GoRouterState state) {
       return const ProfileScreen();
     }
   }
   ```

3. **Generate Routes**

   ```bash
   dart run build_runner build
   ```

</Steps>

### Multiple Guards

Combine multiple guards using the `Guards` utility:

```dart
@TypedGoRoute<AdminRoute>(path: '/admin')
class AdminRoute extends GoRouteData with GuardedRoute {
  const AdminRoute();

  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    RoleGuard(['admin']),
    PermissionGuard(['admin_access']),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}
```

### Conditional Guards

Apply guards based on route parameters or other conditions:

```dart
@TypedGoRoute<UserProfileRoute>(path: '/user/:userId')
class UserProfileRoute extends GoRouteData with GuardedRoute {
  const UserProfileRoute({required this.userId});
  
  final String userId;

  @override
  RouteGuard get guards {
    // Different guards based on the user ID
    if (userId == 'me') {
      return AuthGuard(); // Only auth required for own profile
    } else {
      return Guards.all([
        AuthGuard(),
        RoleGuard(['admin', 'moderator']), // Admin required for other profiles
      ]);
    }
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return UserProfileScreen(userId: userId);
  }
}
```

## UnguardedRoute Mixin

Use `UnguardedRoute` to explicitly opt-out of router-level guards:

```dart
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with UnguardedRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

@TypedGoRoute<PublicRoute>(path: '/public')
class PublicRoute extends GoRouteData with UnguardedRoute {
  const PublicRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PublicScreen();
  }
}
```

## Nested Routes with Guards

### Parent Route Protection

```dart
@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<DashboardRoute>(path: '/dashboard'),
    TypedGoRoute<SettingsRoute>(path: '/settings'),
    TypedGoRoute<ProfileRoute>(path: '/profile'),
  ],
)
class AppShellRoute extends ShellRouteData with GuardedShellRoute {
  const AppShellRoute();

  @override
  RouteGuard get guards => AuthGuard(); // Protects all child routes

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget child) {
    return AppLayout(child: child);
  }
}

// Child routes automatically inherit parent protection
class DashboardRoute extends GoRouteData {
  const DashboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DashboardScreen();
  }
}
```

### Additional Child Protection

```dart
// Parent provides basic auth, child adds role check
class SettingsRoute extends GoRouteData with GuardedRoute {
  const SettingsRoute();

  @override
  RouteGuard get guards => RoleGuard(['admin']); // Additional protection

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}
```

## Advanced Patterns

### Parameter-Dependent Guards

```dart
@TypedGoRoute<DocumentRoute>(path: '/document/:id')
class DocumentRoute extends GoRouteData with GuardedRoute {
  const DocumentRoute({required this.id});
  
  final String id;

  @override
  RouteGuard get guards => DocumentAccessGuard(documentId: id);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DocumentScreen(documentId: id);
  }
}

class DocumentAccessGuard extends GoRouterGuard {
  const DocumentAccessGuard({required this.documentId});
  
  final String documentId;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final hasAccess = await documentService.hasAccess(
      documentId, 
      getCurrentUserId(),
    );
    
    if (hasAccess) {
      resolver.next();
    } else {
      resolver.redirect('/unauthorized');
    }
  }
}
```

### Query Parameter Guards

```dart
@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData with GuardedRoute {
  const SearchRoute({this.query, this.category});
  
  final String? query;
  final String? category;

  @override
  RouteGuard get guards {
    // Require premium subscription for advanced search
    if (category == 'advanced') {
      return Guards.all([
        AuthGuard(),
        SubscriptionGuard(tier: 'premium'),
      ]);
    }
    return const _AllowGuard(); // Public search
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SearchScreen(query: query, category: category);
  }
}
```

### Lazy Guard Loading

```dart
@TypedGoRoute<ExperimentalRoute>(path: '/experimental')
class ExperimentalRoute extends GoRouteData with GuardedRoute {
  const ExperimentalRoute();

  @override
  RouteGuard get guards => _LazyFeatureFlagGuard('experimental_features');

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ExperimentalScreen();
  }
}

class _LazyFeatureFlagGuard extends GoRouterGuard {
  const _LazyFeatureFlagGuard(this.flagName);
  
  final String flagName;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Lazy load feature flag service
    final featureFlags = GetIt.instance.get<FeatureFlagService>();
    final isEnabled = await featureFlags.isEnabled(flagName);
    
    if (isEnabled) {
      resolver.next();
    } else {
      resolver.redirect('/feature-not-available');
    }
  }
}
```

## Error Handling

### Guard Error Boundaries

```dart
@TypedGoRoute<RiskyRoute>(path: '/risky')
class RiskyRoute extends GoRouteData with GuardedRoute {
  const RiskyRoute();

  @override
  RouteGuard get guards => SafeGuard(
    guard: UnstableGuard(),
    fallbackPath: '/safe-fallback',
  );

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RiskyScreen();
  }
}

class SafeGuard extends GoRouterGuard {
  const SafeGuard({
    required this.guard,
    required this.fallbackPath,
  });
  
  final RouteGuard guard;
  final String fallbackPath;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      await guard.onNavigation(resolver, context, state);
    } catch (error) {
      logger.error('Guard failed, redirecting to fallback', error: error);
      resolver.redirect(fallbackPath);
    }
  }
}
```

### Validation Errors

```dart
@TypedGoRoute<FormRoute>(path: '/form/:formId')
class FormRoute extends GoRouteData with GuardedRoute {
  const FormRoute({required this.formId});
  
  final String formId;

  @override
  RouteGuard get guards => FormValidationGuard(formId: formId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FormScreen(formId: formId);
  }
}

class FormValidationGuard extends GoRouterGuard {
  const FormValidationGuard({required this.formId});
  
  final String formId;

  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    if (!isValidFormId(formId)) {
      resolver.redirect('/forms');
      return;
    }
    
    final formExists = await formService.exists(formId);
    if (!formExists) {
      resolver.redirect('/form-not-found');
      return;
    }
    
    resolver.next();
  }
  
  bool isValidFormId(String id) {
    return RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(id) && id.length <= 50;
  }
}
```

## Testing Type-Safe Routes

### Route-Level Testing

```dart
void main() {
  group('AdminRoute', () {
    testWidgets('requires authentication and admin role', (tester) async {
      final mockAuthBloc = MockAuthBloc();
      final mockUserCubit = MockUserCubit();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<UserCubit>.value(value: mockUserCubit),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [...AdminRoute().routes],
            ),
          ),
        ),
      );

      // Test navigation is blocked when not admin
      when(() => mockAuthBloc.state)
          .thenReturn(const AuthAuthenticated());
      when(() => mockUserCubit.state)
          .thenReturn(const UserState(roles: ['user']));

      AdminRoute().go(tester.element(find.byType(MaterialApp)));
      await tester.pumpAndSettle();

      expect(find.byType(AdminScreen), findsNothing);
    });
  });
}
```

### Guard-Specific Testing

```dart
void main() {
  group('GuardedRoute integration', () {
    testWidgets('executes guards before navigation', (tester) async {
      var guardExecuted = false;
      
      final testGuard = TestGuard(() => guardExecuted = true);
      
      final route = TestRoute(guard: testGuard);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(routes: [route]),
        ),
      );

      route.go(tester.element(find.byType(MaterialApp)));
      await tester.pump();

      expect(guardExecuted, isTrue);
    });
  });
}

class TestRoute extends GoRouteData with GuardedRoute {
  const TestRoute({required this.guard});
  
  final RouteGuard guard;

  @override
  RouteGuard get guards => guard;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Scaffold(body: Text('Test Screen'));
  }
}
```

## Best Practices

### 1. Consistent Guard Patterns

```dart
// ✅ Good - consistent pattern across routes
abstract class BaseProtectedRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    baseProtectionGuard,
  ]);
  
  RouteGuard get baseProtectionGuard;
}

class AdminRoute extends BaseProtectedRoute {
  @override
  RouteGuard get baseProtectionGuard => RoleGuard(['admin']);
}

class ModeratorRoute extends BaseProtectedRoute {
  @override
  RouteGuard get baseProtectionGuard => RoleGuard(['moderator']);
}
```

### 2. Route Organization

```dart
// ✅ Good - organized route structure
// lib/routes/auth/
class LoginRoute extends GoRouteData with UnguardedRoute { /* ... */ }
class RegisterRoute extends GoRouteData with UnguardedRoute { /* ... */ }

// lib/routes/user/
class ProfileRoute extends GoRouteData with GuardedRoute { /* ... */ }
class SettingsRoute extends GoRouteData with GuardedRoute { /* ... */ }

// lib/routes/admin/
class AdminDashboardRoute extends GoRouteData with GuardedRoute { /* ... */ }
class UserManagementRoute extends GoRouteData with GuardedRoute { /* ... */ }
```

### 3. Guard Reusability

```dart
// ✅ Good - reusable guard configurations
class AppGuards {
  static RouteGuard get authenticated => AuthGuard();
  
  static RouteGuard get admin => Guards.all([
    authenticated,
    RoleGuard(['admin']),
  ]);
  
  static RouteGuard get moderator => Guards.all([
    authenticated,
    RoleGuard(['moderator', 'admin']),
  ]);
  
  static RouteGuard premium({required String feature}) => Guards.all([
    authenticated,
    SubscriptionGuard(),
    FeatureFlagGuard(feature),
  ]);
}

// Usage
class PremiumRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => AppGuards.premium(feature: 'advanced_analytics');
}
```

### 4. Documentation

```dart
/// Route for managing user accounts.
/// 
/// Requires:
/// - Authentication
/// - Admin role
/// - User management permission
@TypedGoRoute<UserManagementRoute>(path: '/admin/users')
class UserManagementRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    RoleGuard(['admin']),
    PermissionGuard(['manage_users']),
  ]);
}
```

## Common Patterns

### Role-Based Route Hierarchies

```dart
// Base authenticated route
abstract class AuthenticatedRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => AuthGuard();
}

// User routes (authenticated users)
abstract class UserRoute extends AuthenticatedRoute {
  @override
  RouteGuard get guards => Guards.all([
    super.guards,
    RoleGuard(['user', 'moderator', 'admin']),
  ]);
}

// Admin routes (admin users only)
abstract class AdminRoute extends AuthenticatedRoute {
  @override
  RouteGuard get guards => Guards.all([
    super.guards,
    RoleGuard(['admin']),
  ]);
}
```

### Feature Flag Routes

```dart
mixin FeatureRoute on GoRouteData {
  String get featureName;
  
  RouteGuard get featureGuard => FeatureFlagGuard(featureName);
}

class BetaFeatureRoute extends GoRouteData 
    with GuardedRoute, FeatureRoute {
  @override
  String get featureName => 'beta_features';
  
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    featureGuard,
  ]);
}
```

### Progressive Enhancement

```dart
class EnhancedRoute extends GoRouteData with GuardedRoute {
  const EnhancedRoute({this.enhanced = false});
  
  final bool enhanced;

  @override
  RouteGuard get guards {
    if (enhanced) {
      return Guards.all([
        AuthGuard(),
        SubscriptionGuard(),
        FeatureFlagGuard('enhanced_ui'),
      ]);
    }
    return AuthGuard();
  }
}
```

## Next Steps

Now that you understand type-safe routes with guards:

1. 🔄 Learn about [Traditional Routes](/guides/traditional-routes/)
2. 🧩 Explore [Guard Combinations](/guides/guard-combinations/)
3. ⚙️ Check out [Conditional Guards](/guides/conditional-guards/)
4. 📚 Review [Best Practices](/guides/best-practices/)
