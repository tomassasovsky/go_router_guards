---
title: Installation
description: How to install and set up Go Router Guards in your Flutter project
---

import { Tabs, TabItem } from '@astrojs/starlight/components';

## Requirements

Before installing Go Router Guards, ensure you have:

- **Dart SDK**: `^3.5.0`
- **Flutter**: `>=3.19.0`
- **go_router**: Latest version

## Package Installation

Go Router Guards consists of two packages that you can install based on your needs:

<Tabs>
  <TabItem label="Both Packages (Recommended)">
    Install both packages for full functionality:

    ```bash
    flutter pub add go_router_guards route_guards
    ```

    This gives you both the core guard system and Go Router integration.
  </TabItem>
  
  <TabItem label="Go Router Integration Only">
    If you only need Go Router integration:

    ```bash
    flutter pub add go_router_guards
    ```

    This automatically includes `route_guards` as a dependency.
  </TabItem>
  
  <TabItem label="Core Guards Only">
    For framework-agnostic usage:

    ```bash
    flutter pub add route_guards
    ```

    Use this if you're building your own router integration.
  </TabItem>
</Tabs>

## Import Statements

After installation, add the appropriate imports to your Dart files:

```dart
// For Go Router integration
import 'package:go_router_guards/go_router_guards.dart';

// For core guard functionality (if using separately)
import 'package:route_guards/route_guards.dart';

// For Go Router (required)
import 'package:go_router/go_router.dart';
```

## Verify Installation

Create a simple test to verify the installation:

```dart
import 'package:flutter/material.dart';
import 'package:go_router_guards/go_router_guards.dart';

class TestGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    print('Guard executed successfully!');
    resolver.next();
  }
}
```

If this compiles without errors, you're ready to go!

## Development Dependencies

For development and testing, you might want to add:

```yaml
dev_dependencies:
  # For type-safe routes (optional)
  go_router_builder: ^3.0.1
  
  # For testing guards
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  
  # For code quality
  very_good_analysis: ^10.0.0
```

## IDE Setup

### VS Code Extensions

For the best development experience, install:

- **Dart**: Official Dart support
- **Flutter**: Official Flutter support
- **Dart Data Class Generator**: For generating boilerplate

### Android Studio/IntelliJ

Install the following plugins:

- **Dart**
- **Flutter**

## Next Steps

Now that you have Go Router Guards installed:

1. 📚 Check out the [Quick Start](/quick-start/) guide
2. 🔍 Explore the [route_guards](/packages/route-guards/) package documentation
3. ⚡ Learn about [go_router_guards](/packages/go-router-guards/) integration
4. 🎯 Follow the [Creating Guards](/guides/creating-guards/) guide

## Troubleshooting

### Common Issues

**Package not found**
```bash
# Clear pub cache and retry
flutter pub cache clean
flutter pub get
```

**Import errors**
```dart
// Make sure you're importing the correct package
import 'package:go_router_guards/go_router_guards.dart'; // ✅ Correct
import 'package:go_router_guards/guards.dart';           // ❌ Wrong
```

**Version conflicts**
```yaml
# Use dependency overrides if needed
dependency_overrides:
  meta: ^1.16.0
```

**Build errors with go_router_builder**
```bash
# Regenerate type-safe routes
dart run build_runner build --delete-conflicting-outputs
```

### Getting Help

If you encounter issues:

1. Check the [GitHub Issues](https://github.com/tomassasovsky/go_router_guards/issues)
2. Review the [example app](https://github.com/tomassasovsky/go_router_guards/tree/main/example)
3. Ask in [GitHub Discussions](https://github.com/tomassasovsky/go_router_guards/discussions)

## Keeping Updated

To update to the latest version:

```bash
flutter pub upgrade go_router_guards
```

Or specify a version constraint in your `pubspec.yaml`:

```yaml
dependencies:
  go_router_guards: ^1.0.0
  route_guards: ^1.0.0
```
