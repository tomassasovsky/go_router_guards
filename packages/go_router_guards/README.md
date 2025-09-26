# Go Router Guards

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

A flexible and extensible guard system for Go Router that allows you to create middleware-style navigation guards with inclusion and exclusion capabilities.

This package provides Go Router specific integration for the core `route_guards` package. It includes type-safe route mixins, utilities for traditional GoRoute usage, and enhanced Go Router specific functionality.

## Features

- **Route Guards**: Create custom guards that can redirect, block, or allow navigation
- **Guard Combinations**: Combine multiple guards with `Guards.all()`, `Guards.anyOf()`, `Guards.oneOf()`
- **Conditional Guards**: Apply guards with fine-grained control over which routes are affected
- **Type-Safe Integration**: Full support for Go Router's type-safe routing with `GuardedRoute` and `UnguardedRoute` mixins
- **Backward Compatibility**: Works with both traditional and type-safe GoRouter configurations

## Quick Start

### Creating a Guard

```dart
class AuthGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final isAuthenticated = await checkAuth();
    if (isAuthenticated) {
      resolver.next(); // Allow navigation
    } else {
      resolver.redirect('/login'); // Redirect to login
    }
  }
}
```

### Type-Safe Routes with Guards

```dart
@TypedGoRoute<AdminRoute>(path: '/admin')
class AdminRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    AuthGuard(),
    RoleGuard(['admin']),
  ]);

  @override
  Widget build(context, state) => AdminScreen();
}
```

### Traditional Routes with Guards

```dart
GoRoute(
  path: '/admin',
  builder: (context, state) => AdminScreen(),
  redirect: RouteGuardUtils.createGuardRedirect(
    Guards.all([AuthGuard(), RoleGuard(['admin'])]),
  ),
)
```

## Installation 💻

**❗ In order to start using Go Router Guards you must have the [Flutter SDK][flutter_install_link] installed on your machine.**

Install via `flutter pub add`:

```sh
dart pub add go_router_guards
```

---

## Continuous Integration 🤖

Go Router Guards comes with a built-in [GitHub Actions workflow][github_actions_link] powered by [Very Good Workflows][very_good_workflows_link] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Workflows][very_good_coverage_link].

---

## Running Tests 🧪

For first time users, install the [very_good_cli][very_good_cli_link]:

```sh
dart pub global activate very_good_cli
```

To run all unit tests:

```sh
very_good test --coverage
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
