# Contributing to go_router_guards

Thank you for your interest in contributing to `go_router_guards`! This document provides guidelines and information for contributors.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Issue Reporting](#issue-reporting)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Release Process](#release-process)

## Getting Started

### Prerequisites

- **Dart SDK**: ^3.5.0 or higher
- **Flutter**: >=3.19.0
- **Git**: Latest version
- **IDE**: VS Code, Android Studio, or IntelliJ IDEA with Dart/Flutter plugins

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/go_router_guards.git
   cd go_router_guards
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/tomassasovsky/go_router_guards.git
   ```

## Development Setup

### Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get
```

### Run Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run tests in watch mode
flutter test --watch
```

### Code Generation

This project uses code generation. Run the following commands when needed:

```bash
# Generate code
dart run build_runner build

# Watch for changes and regenerate
dart run build_runner watch

# Clean generated files
dart run build_runner clean
```

### Static Analysis

```bash
# Run static analysis
flutter analyze

# Run with very_good_analysis
dart run very_good_analysis:analyze
```

## Code Style

### Dart/Flutter Conventions

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use [very_good_analysis](https://pub.dev/packages/very_good_analysis) for linting
- Maximum line length: 80 characters
- Use trailing commas for multi-line collections
- Prefer `const` constructors when possible

### Documentation

- All public APIs must be documented with dartdoc comments
- Include usage examples in documentation
- Follow the [Dart Documentation Guide](https://dart.dev/guides/language/effective-dart/documentation)

### Example Documentation

```dart
/// A flexible and extensible guard system for Go Router.
///
/// This package provides a powerful expression-based guard system that allows
/// you to create custom route guards and combine them using logical operators.
///
/// ## Example
///
/// ```dart
/// class AuthenticationGuard implements RouteGuard {
///   @override
///   FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
///     final authState = context.read<AuthCubit>().state;
///     if (!authState.isAuthenticated) {
///       return '/login';
///     }
///     return null;
///   }
/// }
/// ```
```

## Testing

### Writing Tests

- Write tests for all new functionality
- Aim for high test coverage (target: 100%)
- Use descriptive test names
- Group related tests using `group()`
- Use `setUp()` and `tearDown()` for test setup

### Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  group('AuthenticationGuard', () {
    late MockAuthCubit mockAuthCubit;
    late AuthenticationGuard guard;

    setUp(() {
      mockAuthCubit = MockAuthCubit();
      guard = AuthenticationGuard();
    });

    test('redirects to login when not authenticated', () async {
      when(() => mockAuthCubit.state).thenReturn(UnauthenticatedState());
      
      final result = await guard.redirect(mockContext, mockState);
      
      expect(result, equals('/login'));
    });

    test('allows access when authenticated', () async {
      when(() => mockAuthCubit.state).thenReturn(AuthenticatedState());
      
      final result = await guard.redirect(mockContext, mockState);
      
      expect(result, isNull);
    });
  });
}
```

### Integration Tests

For complex guard expressions, write integration tests:

```dart
testWidgets('complex guard expression works correctly', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Test navigation with guards
  await tester.tap(find.text('Protected Route'));
  await tester.pumpAndSettle();
  
  expect(find.text('Login'), findsOneWidget);
});
```

## Submitting Changes

### Creating a Feature Branch

```bash
# Update your local main branch
git checkout main
git pull upstream main

# Create a feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/your-bug-description
```

### Commit Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

### Example Commits

```bash
feat: add support for parallel guard execution
fix: resolve issue with guard expression evaluation
docs: update README with new examples
test: add tests for complex guard expressions
```

### Before Submitting

1. **Run tests**: `flutter test`
2. **Check static analysis**: `flutter analyze`
3. **Update documentation**: Add/update docs for new features
4. **Update CHANGELOG.md**: Add entry for your changes
5. **Rebase if needed**: `git rebase upstream/main`

## Issue Reporting

### Before Creating an Issue

1. Check existing issues for duplicates
2. Search the documentation and README
3. Try to reproduce the issue in a minimal example

### Issue Template

When creating an issue, include:

- **Description**: Clear description of the problem
- **Steps to reproduce**: Detailed steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: Flutter/Dart versions, OS
- **Code example**: Minimal code to reproduce

### Example Issue

```markdown
## Description
The `Guards.all()` expression doesn't work correctly with async guards.

## Steps to Reproduce
1. Create a route with `Guards.all([asyncGuard1, asyncGuard2])`
2. Navigate to the route
3. Observe incorrect behavior

## Expected Behavior
Both guards should execute and all must pass for access.

## Actual Behavior
Only the first guard executes.

## Environment
- Flutter: 3.19.0
- Dart: 3.5.0
- OS: macOS 14.0

## Code Example
```dart
@override
RouteGuard get guards => Guards.all([
  AsyncGuard1(),
  AsyncGuard2(),
]);
```
```

## Pull Request Guidelines

### PR Checklist

- [ ] Tests pass (`flutter test`)
- [ ] Static analysis passes (`flutter analyze`)
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Code follows style guidelines
- [ ] PR description is clear and complete

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] All tests pass

## Documentation
- [ ] API documentation updated
- [ ] README updated (if needed)
- [ ] CHANGELOG.md updated

## Breaking Changes
If this is a breaking change, describe the changes and migration guide.

## Additional Notes
Any additional information or context.
```

### Review Process

1. **Automated Checks**: CI/CD will run tests and analysis
2. **Code Review**: At least one maintainer must approve
3. **Discussion**: Address any feedback or concerns
4. **Merge**: Once approved, maintainers will merge

## Release Process

### Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Steps

1. **Update version** in `pubspec.yaml`
2. **Update CHANGELOG.md** with release notes
3. **Create release tag** on GitHub
4. **Publish to pub.dev** (maintainers only)

### Example Release

```bash
# Update version
# pubspec.yaml: version: 1.1.0

# Update CHANGELOG.md
# Add release notes

# Create tag
git tag v1.1.0
git push origin v1.1.0

# Publish to pub.dev
dart pub publish
```

## Getting Help

- **Documentation**: Check the [README.md](README.md)
- **Issues**: Search existing issues or create new ones
- **Discussions**: Use GitHub Discussions for questions

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to `go_router_guards`! 🚀
