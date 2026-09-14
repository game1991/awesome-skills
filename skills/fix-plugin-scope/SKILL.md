---
name: fix-plugin-scope
description: Use when kscc plugins show "not cached at (not recorded)" errors, plugin loading fails after an upgrade, or user mentions "not cached", "plugin errors", or "plugins broken". Fixes bug in installed_plugins.json that prevents custom marketplace plugins from loading in user-level sessions.
license: MIT
compatibility: Node.js 12+ (all platforms, included with kscc). Python 3.6+ alternative for non-kscc environments.
metadata:
  author: game1991
  version: "1.2"
---

# Fix Plugin Scope

## Overview

kscc incorrectly marks custom marketplace plugins as `"scope": "project"` with a `projectPath` field in `installed_plugins.json`. User-level sessions only match `"scope": "user"` entries, causing all affected plugins to fail with "not cached at (not recorded)".

## When to Use

- `/plugins` shows multiple "not cached at (not recorded)" errors
- User says "not cached", "plugin errors", "plugins broken"
- Plugins stop working after a kscc upgrade or auto-update

## Root Cause

kscc's sync logic marks extraKnownMarketplaces plugin entries as project-scoped. Official marketplace plugins are unaffected because they're correctly marked as user-scoped.

## Fix

### All platforms (Node.js) — recommended

Node.js is included with kscc, no extra dependencies needed.

```bash
# Linux / macOS / WSL
node ~/.claude/skills/fix-plugin-scope/scripts/fix_scope.js

# Windows CMD
node "%USERPROFILE%\.claude\skills\fix-plugin-scope\scripts\fix_scope.js"

# Windows PowerShell
node "$env:USERPROFILE\.claude\skills\fix-plugin-scope\scripts\fix_scope.js"
```

### Linux / macOS / WSL — Python alternative

If Node.js is unavailable:

```bash
python3 ~/.claude/skills/fix-plugin-scope/scripts/fix_scope.py
```

## Verification

- `Fixed N plugin entries` — success, N entries corrected
- `No project-scoped plugins found` — nothing to fix
- `ERROR: File not found` — check that kscc is installed with plugins

After fixing, run `/plugins` to confirm errors are gone.

## Recurrence

This bug may recur after each kscc upgrade or plugin auto-update. Re-run the script when it does.

## Additional Cleanup Steps

If errors persist after running the script:

1. **Orphaned caches**: Check for `.orphaned_at` files in `~/.claude/plugins/cache/` and delete those directories
2. **Ghost enabledPlugins**: Remove keys in `settings.json` `enabledPlugins` that have no matching entry in `installed_plugins.json`
3. **Missing marketplace**: If using local-source plugins, ensure they're registered in `known_marketplaces.json`

## Common Mistakes

- Don't edit JSON entries manually — easy to miss some or break formatting
- Don't delete `installed_plugins.json` — all plugins will be lost
- Don't fix only specific plugins — correct all project-scoped entries at once
