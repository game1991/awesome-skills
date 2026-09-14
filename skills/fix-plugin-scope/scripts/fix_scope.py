#!/usr/bin/env python3
"""Fix kscc installed_plugins.json scope bug.

Custom marketplace plugins are incorrectly marked as "scope": "project"
with a "projectPath" field, causing "not cached at (not recorded)" errors
in user-level sessions. This script corrects all project-scoped entries
to user scope and removes the projectPath field.
"""
import json
import os
import sys
import tempfile

def get_config_path():
    if sys.platform == "win32":
        base = os.environ.get("USERPROFILE", os.path.expanduser("~"))
    else:
        base = os.path.expanduser("~")
    return os.path.join(base, ".claude", "plugins", "installed_plugins.json")

def main():
    path = get_config_path()

    if not os.path.exists(path):
        print(f"ERROR [FIX_PLUGIN_SCOPE]: File not found: {path}")
        print("HINT: Check if kscc is installed and has plugins configured.")
        sys.exit(1)

    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        print(f"ERROR [FIX_PLUGIN_SCOPE]: Failed to parse JSON: {path}")
        print(f"DETAIL: {e}")
        print("HINT: The file may be corrupted. Consider backing up and reinstalling plugins.")
        sys.exit(1)

    if "plugins" not in data or not isinstance(data["plugins"], dict):
        print(f"ERROR [FIX_PLUGIN_SCOPE]: Unexpected JSON structure in {path}")
        print("HINT: Expected a top-level 'plugins' object. The file may be from an incompatible kscc version.")
        sys.exit(1)

    fixed = 0
    for market, entries in data["plugins"].items():
        if not isinstance(entries, list):
            print(f"WARN [FIX_PLUGIN_SCOPE]: Skipping non-array entry '{market}'")
            continue
        for entry in entries:
            if entry.get("scope") == "project":
                entry["scope"] = "user"
                entry.pop("projectPath", None)
                fixed += 1

    if fixed == 0:
        print("OK [FIX_PLUGIN_SCOPE]: No project-scoped plugins found. Everything looks good!")
        sys.exit(0)

    try:
        tmp_fd, tmp_path = tempfile.mkstemp(dir=os.path.dirname(path), suffix=".tmp")
        with os.fdopen(tmp_fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        os.replace(tmp_path, path)
    except (OSError, PermissionError) as e:
        print(f"ERROR [FIX_PLUGIN_SCOPE]: Failed to write file: {path}")
        print(f"DETAIL: {e}")
        print("HINT: kscc may be running and locking the file. Close kscc and retry.")
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        sys.exit(1)

    try:
        with open(path, "r", encoding="utf-8") as f:
            json.load(f)
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        print(f"ERROR [FIX_PLUGIN_SCOPE]: File verification failed after write: {path}")
        print(f"DETAIL: {e}")
        print("HINT: The write may have been interrupted. Re-run this script.")
        sys.exit(1)

    print(f"OK [FIX_PLUGIN_SCOPE]: Fixed {fixed} plugin entries (project -> user scope)")
    print("NEXT: Restart kscc session and run /plugins to verify the fix.")
    sys.exit(0)

if __name__ == "__main__":
    main()
