---
title: Architecture
description: Concepts and design rationale
---

## Overview

go_router_guards implements a middleware pattern around Go Router’s redirects.

- Route code defines guard(s) via `GuardedRoute`/`GuardedShellRoute` or traditional `redirect`.
- A `RouteGuard` receives `NavigationResolver`, `BuildContext`, and `GoRouterState`.
- The guard resolves by calling `next()`, `redirect(path)`, or `block()`.

## Why a resolver pattern?

It makes asynchronous and branching flows straightforward and testable. Guards compose cleanly using `guardAll`, `guardAnyOf`, and `guardOneOf`.

## Router vs route‑level

- Router‑level (via `ConditionalGuard`) is great for cross‑cutting checks (e.g., auth).
- Route‑level focuses on local authorization (e.g., role/permission).


