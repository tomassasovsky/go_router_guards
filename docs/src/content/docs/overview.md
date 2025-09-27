---
title: Overview
description: A comprehensive introduction to Route Guards - a flexible and extensible guard system for navigation protection
---

import { Card, CardGrid } from '@astrojs/starlight/components';

<div class="hero-section">
  <h1>Route Guards System</h1>
  <p>A flexible and extensible guard system that provides middleware-style navigation protection for modern applications.</p>
</div>

## What are Route Guards?

Route Guards is a powerful navigation protection system that provides a middleware-style approach to route protection. It allows you to create reusable guards that can authenticate, authorize, and control navigation flow throughout your application, regardless of the underlying routing framework.

## Key Features

<CardGrid>
  <Card title="🔐 Route Protection" icon="lock">
    Create custom guards for authentication, authorization, and access control with flexible middleware-style patterns.
  </Card>
  
  <Card title="🔧 Type-Safe Integration" icon="puzzle">
    Full support for Go Router's type-safe routing with GuardedRoute and UnguardedRoute mixins.
  </Card>
  
  <Card title="⚡ Guard Combinations" icon="lightning">
    Combine multiple guards with Guards.all(), Guards.anyOf(), and Guards.oneOf() for complex protection scenarios.
  </Card>
  
  <Card title="🎯 Conditional Protection" icon="target">
    Apply guards with fine-grained control over which routes are affected using inclusion and exclusion patterns.
  </Card>
  
  <Card title="🔄 Framework Agnostic Core" icon="recycle">
    Core guard logic works with any router, with specialized Go Router integration.
  </Card>
  
  <Card title="📚 Backward Compatibility" icon="books">
    Works with both traditional and type-safe GoRouter configurations.
  </Card>
</CardGrid>

## Architecture

The Route Guards system consists of a core package and framework integrations:

### route_guards
The core, framework-agnostic package that provides:
- Base `RouteGuard` class for creating guards
- `NavigationResolver` for controlling navigation flow
- `Guards` utility for combining guards
- Guard composition and execution logic

### Framework Integrations
Specialized packages for popular frameworks:

**go_router_guards** - Flutter Go Router integration:
- `GoRouterGuard` specialized for Go Router
- `GuardedRoute` and `UnguardedRoute` mixins for type-safe routes  
- `RouteGuardUtils` for traditional GoRoute usage
- `ConditionalGuard` for path-based protection

**Future integrations** may include other routing systems.

## How It Works

Guards operate using a middleware pattern where each guard can:

1. **Allow** navigation by calling `resolver.next()`
2. **Redirect** navigation by calling `resolver.redirect('/path')`
3. **Block** navigation by calling `resolver.block()`

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

## Quick Navigation

<div class="quick-links">
  <a href="/installation/" class="quick-link">
    <h4>Installation</h4>
    <p>Get started with adding Go Router Guards to your project</p>
  </a>
  
  <a href="/quick-start/" class="quick-link">
    <h4>Quick Start</h4>
    <p>Create your first guard in 5 minutes</p>
  </a>
  
  <a href="/packages/route-guards/" class="quick-link">
    <h4>route_guards</h4>
    <p>Core framework-agnostic guard system</p>
  </a>
  
  <a href="/packages/go-router-guards/" class="quick-link">
    <h4>go_router_guards</h4>
    <p>Go Router specific integration</p>
  </a>
  
  <a href="/guides/creating-guards/" class="quick-link">
    <h4>Creating Guards</h4>
    <p>Learn how to build custom protection logic</p>
  </a>
  
  <a href="/examples/authentication/" class="quick-link">
    <h4>Examples</h4>
    <p>Real-world guard implementations</p>
  </a>
</div>

## Use Cases

Go Router Guards is perfect for:

- **Authentication flows** - Protect routes that require user login
- **Role-based access control** - Restrict access based on user roles
- **Permission systems** - Fine-grained access control
- **Feature flags** - Control access to experimental features
- **A/B testing** - Route users to different experiences
- **Multi-tenant applications** - Tenant-specific route protection
- **Premium features** - Subscription-based access control

## Community and Support

- 📖 **Documentation**: Comprehensive guides and API reference
- 🐛 **Issues**: Report bugs on GitHub
- 💬 **Discussions**: Join the community discussions
- 🎯 **Examples**: Working example app included

Get started by checking out the [Installation](/installation/) guide or jump straight into the [Quick Start](/quick-start/) tutorial to see guards in action.
