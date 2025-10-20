# Simple Example - Go Router Guards

A comprehensive yet simple example showcasing the main use cases of the `go_router_guards` package with type-safe routing.

## Overview

This example demonstrates:

1. **Type-Safe Routes** - Using `GoRouteData` with `@TypedGoRoute` annotations
2. **Authentication Guards** - Protecting routes that require user login
3. **Role-Based Access Control** - Restricting routes based on user roles
4. **Permission-Based Guards** - Fine-grained access control with permissions
5. **Guard Combinations** - Using `.all()`, `.anyOf()` for complex logic
6. **Async Guards** - Handling asynchronous authentication checks
7. **Conditional Guards** - Applying guards to specific paths only

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code

The example uses code generation for type-safe routes:

```bash
dart run build_runner build
```

Or watch for changes:

```bash
dart run build_runner watch
```

### 3. Run the Example

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart           # App entry point
├── app_state.dart      # Simple state management for auth/roles/permissions
├── guards.dart         # Guard implementations
├── router.dart         # Type-safe route definitions with guards
└── screens.dart        # UI screens
```

## Guard Use Cases

### 1. Single Guard - Authentication

**Profile Route**: Requires user to be logged in

```dart
class ProfileRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => const AuthGuard();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProfileScreen();
  }
}
```

### 2. Multiple Guards - Authentication + Role

**Admin Route**: Requires authentication AND admin role

```dart
class AdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => [
    const AuthGuard(),
    const RoleGuard(['admin']),
  ].all();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}
```

### 3. Guard with OR Logic

**Premium Route**: Requires authentication AND (premium OR vip role)

```dart
class PremiumRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => [
    const AuthGuard(),
    [
      const RoleGuard(['premium']),
      const RoleGuard(['vip']),
    ].anyOf(),
  ].all();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PremiumScreen();
  }
}
```

### 4. Permission-Based Guard

**Settings Route**: Requires authentication AND view_settings permission

```dart
class SettingsRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => [
    const AuthGuard(),
    const PermissionGuard('view_settings'),
  ].all();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}
```

### 5. Complex Guard Combination

**Reports Route**: Requires authentication AND (admin role OR view_reports permission)

```dart
class ReportsRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => [
    const AuthGuard(),
    [
      const RoleGuard(['admin']),
      const PermissionGuard('view_reports'),
    ].anyOf(fallbackRedirect: '/unauthorized'),
  ].all();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ReportsScreen();
  }
}
```

### 6. Async Guard

**Dashboard Route**: Uses async authentication check (e.g., validating token with server)

```dart
class DashboardRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => const AsyncAuthGuard();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DashboardScreen();
  }
}
```

### 7. Conditional Guard

**Secret Info Route**: Only specific paths require authentication

```dart
class SecretInfoRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => ConditionalGuard.including(
    guard: const AuthGuard(),
    paths: ['/info/secret'],
  );
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SecretInfoScreen();
  }
}
```

## Guard Behaviors

### Navigation Results

Guards can produce three outcomes:

1. **Allow** (`resolver.next()`) - Continue to the requested route
2. **Redirect** (`resolver.redirect('/path')`) - Navigate to a different route
3. **Block** (`resolver.block()`) - Stay on the current page (navigation is cancelled)

### Example Guard Implementation

```dart
class AuthGuard extends RouteGuard {
  const AuthGuard();

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    final appState = _getAppState(context);

    if (!appState.isAuthenticated) {
      resolver.redirect('/login');  // Redirect to login
    } else {
      resolver.next();  // Allow navigation
    }
  }
}
```

## Interactive Testing

The home screen provides controls to test all guard scenarios:

1. **Toggle Authentication** - Log in/out to test auth guards
2. **Toggle Roles** - Add/remove admin, premium, and vip roles
3. **Toggle Permissions** - Grant/revoke view_settings and view_reports permissions

Try navigating to different routes with various combinations to see guards in action!

## Key Concepts

### Type-Safe Routes with Guards

Use the `GuardedRoute` mixin with `GoRouteData`:

```dart
class MyRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => MyGuard();
  
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MyScreen();
  }
}
```

### Guard Composition

Combine multiple guards using extension methods:

- `.all()` - All guards must pass
- `.anyOf()` - At least one guard must pass
- `.oneOf()` - Exactly one guard must pass

```dart
// All guards must pass
[GuardA(), GuardB()].all()

// At least one must pass
[GuardA(), GuardB()].anyOf()

// Exactly one must pass
[GuardA(), GuardB()].oneOf()
```

### Navigation Methods

Type-safe routes provide convenient navigation:

```dart
// Navigate to a route
const ProfileRoute().go(context);

// Push a route
const ProfileRoute().push(context);

// Replace current route
const ProfileRoute().replace(context);
```

## Learn More

For detailed documentation, visit:
- [Official Documentation](https://guards.aquiles.dev)
- [API Reference](https://pub.dev/documentation/go_router_guards/latest/)
- [GitHub Repository](https://github.com/tomassasovsky/go_router_guards)

## License

MIT License - see the [LICENSE](../LICENSE) file for details.

