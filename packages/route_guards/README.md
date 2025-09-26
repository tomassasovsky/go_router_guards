# Route Guards

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

A flexible and extensible core guard system for navigation that provides middleware-style route protection with guard composition capabilities.

This is the base package that provides framework-agnostic guard functionality. For Go Router specific integration, use the `go_router_guards` package.

## Features

- **Route Guards**: Create custom guards with middleware-style control
- **Guard Combinations**: Combine multiple guards with `Guards.all()`, `Guards.anyOf()`, `Guards.oneOf()`
- **Framework Agnostic**: Core guard logic that can work with any router
- **Navigation Resolver**: Powerful resolver pattern for guard decisions

## Quick Start

### Creating a Guard

```dart
class AuthGuard extends RouteGuard {
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    Object context,
    Object state,
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

### Combining Guards

```dart
final combinedGuard = Guards.all([
  AuthGuard(),
  RoleGuard(['admin']),
]);
```

## Architecture

This package provides the core abstractions that can be used with any routing system:

- `RouteGuard` - Base class for creating guards
- `NavigationResolver` - Controls navigation flow
- `GuardResult` - Result of guard execution
- `Guards` - Utility for combining guards

For router-specific implementations, see:
- `go_router_guards` - Go Router integration

## Installation 💻

**❗ In order to start using Route Guards you must have the [Dart SDK][dart_install_link] installed on your machine.**

Install via `dart pub add`:

```sh
dart pub add route_guards
```

---

## Continuous Integration 🤖

Route Guards comes with a built-in [GitHub Actions workflow][github_actions_link] powered by [Very Good Workflows][very_good_workflows_link] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Workflows][very_good_coverage_link].

---

## Running Tests 🧪

To run all unit tests:

```sh
dart pub global activate coverage 1.15.0
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

[dart_install_link]: https://dart.dev/get-dart
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
