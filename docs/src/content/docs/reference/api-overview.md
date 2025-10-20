---
title: API Reference
description: Authoritative source for all public APIs
---

## Exports

```text
package:go_router_guards/go_router_guards.dart
  ├─ RouteGuard
  ├─ NavigationResolver
  ├─ GuardResult
  ├─ guardAll(List<RouteGuard>) → RouteGuard
  ├─ guardAnyOf(List<RouteGuard>, {String? fallbackRedirect}) → RouteGuard
  ├─ guardOneOf(List<RouteGuard>, {String? fallbackRedirect}) → RouteGuard
  ├─ GuardedRoute (mixin)
  ├─ GuardedShellRoute (mixin)
  ├─ ConditionalGuard
```

## RouteGuard

```dart
abstract class RouteGuard {
  const RouteGuard();
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  );
  GoRouterRedirect toRedirect();
}
```

## NavigationResolver

```dart
class NavigationResolver {
  void next();
  void redirect(String path);
  void block();
  Future<GuardResult> get future;
}
```

## Composition helpers

```dart
RouteGuard guardAll(List<RouteGuard> guards);
RouteGuard guardAnyOf(List<RouteGuard> guards, {String? fallbackRedirect});
RouteGuard guardOneOf(List<RouteGuard> guards, {String? fallbackRedirect});
```

## Mixins

```dart
mixin GuardedRoute on GoRouteData {
  RouteGuard get guard;
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

mixin GuardedShellRoute on ShellRouteData {
  RouteGuard get guard;
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}
```

## ConditionalGuard

```dart
class ConditionalGuard extends RouteGuard { /* include/exclude paths */ }
```

## Types

```dart
typedef GoRouterRedirect = FutureOr<String?> Function(
  BuildContext context,
  GoRouterState state,
);
```

Note: See Tutorials and How-to guides for usage and patterns.

## Error Handling

All guard methods should handle errors gracefully:

```dart
@override
FutureOr<void> onGoRouterNavigation(
  NavigationResolver resolver,
  BuildContext context,
  GoRouterState state,
) async {
  try {
    final result = await riskyOperation();
    if (result.isValid) {
      resolver.next();
    } else {
      resolver.redirect('/error');
    }
  } catch (error) {
    // Log error and gracefully degrade
    logger.error('Guard failed: $error');
    resolver.next(); // or resolver.redirect('/fallback');
  }
}
```

