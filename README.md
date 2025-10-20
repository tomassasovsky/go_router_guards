<div align="center">
  <img src="https://guards.aquiles.dev/icon.png" alt="go_router_guards" width="200"/>
</div>

# go_router_guards

[![ci][ci_badge]][ci_link]
[![coverage][coverage_badge]][ci_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A flexible and powerful guard system for Go Router with middleware-style navigation control, enabling elegant route protection with expressive guard composition.

**Learn more at [guards.aquiles.dev](https://guards.aquiles.dev)!**

This package is built to work with:

- [go_router](https://pub.dev/packages/go_router)
- [go_router_builder](https://pub.dev/packages/go_router_builder)

---

[ci_badge]: https://github.com/tomassasovsky/go_router_guards/workflows/ci/badge.svg
[ci_link]: https://github.com/tomassasovsky/go_router_guards/actions/workflows/main.yaml
[coverage_badge]: https://codecov.io/gh/tomassasovsky/go_router_guards/master/graph/badge.svg
[pub_badge]: https://img.shields.io/pub/v/go_router_guards.svg
[pub_link]: https://pub.dev/packages/go_router_guards
[license_badge]: https://img.shields.io/badge/License-MIT-yellow.svg
[license_link]: LICENSE
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis

## Overview

The goal of this package is to make it easy to implement navigation guards with Go Router. Navigation guards allow you to protect routes based on custom logic, such as authentication status, user roles, or permissions. Following the guard pattern facilitates testability and reusability of navigation logic.

This package provides a middleware-style approach to route protection, allowing developers to compose multiple guards together and focus on writing clear, declarative navigation rules.

## Quick Start

### Installation

```yaml
dependencies:
  go_router_guards: ^2.0.0+2
```

### Creating a Guard

```dart
class AuthGuard extends RouteGuard {
  @override
  void onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final isAuthenticated = await checkAuth();
    if (isAuthenticated) {
      resolver.next();
    } else {
      resolver.redirect('/login');
    }
  }
}
```

### Using with Type-Safe Routes

```dart
@TypedGoRoute<AdminRoute>(path: '/admin')
class AdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guard => [
    AuthGuard(),
    RoleGuard(['admin']),
  ].all();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}
```

### Using with Traditional GoRouter

```dart
GoRoute(
  path: '/admin',
  redirect: [AuthGuard(), RoleGuard(['admin'])].redirectAll(),
  builder: (context, state) => const AdminScreen(),
)
```

---

## Documentation

📚 **Full documentation available at [guards.aquiles.dev](https://guards.aquiles.dev)**

- [Getting Started Guide](https://guards.aquiles.dev/tutorials/get-started/)
- [Core Concepts](https://guards.aquiles.dev/explanation/core-concepts/)
- [API Reference](https://guards.aquiles.dev/reference/api-overview/)
- [Migration Guide](https://guards.aquiles.dev/guides/migration/)
- [How-To Guides](https://guards.aquiles.dev/how-to/compose-guards/)

---

## Migrating from v1.x

See the [Migration Guide](https://guards.aquiles.dev/guides/migration/) for detailed instructions on upgrading from v1.x to v2.x.

### Quick summary of breaking changes

```dart
// Before (v1.x)
class MyGuard implements RouteGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (condition) return '/redirect';
    return null;
  }
}

// After (v2.x)
class MyGuard extends RouteGuard {
  @override
  void onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    if (condition) {
      resolver.redirect('/redirect');
    } else {
      resolver.next();
    }
  }
}
```

---

## Examples

- [Simple Example](https://github.com/tomassasovsky/go_router_guards/tree/master/example) - A minimal example of using guards with authentication

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## Maintainers

- [Tomás Sasovsky](https://github.com/tomassasovsky)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
