#!/usr/bin/env bash
# Validate a .streamDeckProfile file structure and contents (v3.0 format)
set -uo pipefail

PROFILE="${1:-vibecoding_profile.streamDeckProfile}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ERRORS=0
WARNS=0

err()  { echo "  ERROR: $1"; ((ERRORS++)) || true; }
warn() { echo "  WARN:  $1"; ((WARNS++)) || true; }
ok()   { echo "  OK: $1"; }

echo "=== Stream Deck Profile Validator (v3.0) ==="
echo "File: $PROFILE"
echo ""

# 1. File exists
[[ -f "$PROFILE" ]] || { err "File not found: $PROFILE"; exit 1; }

# 2. Valid ZIP
if unzip -tq "$PROFILE" >/dev/null 2>&1; then
  ok "Valid ZIP archive"
else
  err "Not a valid ZIP archive"; exit 1
fi

# 3. Check for package.json at root
if unzip -l "$PROFILE" | awk '{print $4}' | grep -q '^package\.json$'; then
  ok "package.json found at ZIP root"

  # Extract and validate package.json
  cp "$(cd "$(dirname "$PROFILE")" && pwd)/$(basename "$PROFILE")" "$TMPDIR/archive.zip"
  cd "$TMPDIR"
  unzip -q archive.zip

  if python3 -m json.tool package.json >/dev/null 2>&1; then
    ok "package.json is valid JSON"

    # Check required fields
    RESULT=$(python3 << 'PYEOF' || true
import json, sys
with open("package.json") as f:
    data = json.load(f)
errors = 0
for field in ["AppVersion", "DeviceModel", "FormatVersion", "RequiredPlugins"]:
    if field not in data:
        print(f"  ERROR: package.json missing field: {field}")
        errors += 1
if "RequiredPlugins" in data and not isinstance(data["RequiredPlugins"], list):
    print("  ERROR: RequiredPlugins must be an array")
    errors += 1
print(f"package.json fields: {errors} errors")
sys.exit(errors)
PYEOF
    )
    PKG_ERRORS=$?
    echo "$RESULT" | grep -v "^$"
    if [[ $PKG_ERRORS -gt 0 ]]; then
      ((ERRORS += PKG_ERRORS)) || true
    fi
  else
    err "package.json is invalid JSON"
  fi
else
  warn "No package.json at ZIP root (may be v2.0 format)"
  cp "$(cd "$(dirname "$PROFILE")" && pwd)/$(basename "$PROFILE")" "$TMPDIR/archive.zip"
  cd "$TMPDIR"
  unzip -q archive.zip
fi

# 4. Find .sdProfile directory
SD_DIR=$(find . -maxdepth 3 -name "*.sdProfile" -type d | head -1)
if [[ -n "$SD_DIR" ]]; then
  ok "Found .sdProfile directory: $SD_DIR"
else
  err "No .sdProfile directory found"; exit 1
fi

# 5. Top-level manifest
TOP_MANIFEST="$SD_DIR/manifest.json"
if [[ -f "$TOP_MANIFEST" ]]; then
  if python3 -m json.tool "$TOP_MANIFEST" >/dev/null 2>&1; then
    ok "Top-level manifest.json is valid JSON"

    # Check version
    VERSION=$(python3 -c "import json; print(json.load(open('$TOP_MANIFEST')).get('Version', 'unknown'))")
    ok "Profile version: $VERSION"
  else
    err "Top-level manifest.json is invalid JSON"
  fi
else
  err "Missing top-level manifest.json"
fi

# 6. Validate all profile directories (pages + folders)
PROFILE_COUNT=0
FOLDER_UUIDS=()

for PAGE_DIR in "$SD_DIR/Profiles"/*/; do
  [[ -d "$PAGE_DIR" ]] || continue
  ((PROFILE_COUNT++))
  DIR_NAME=$(basename "$PAGE_DIR")
  PAGE_MANIFEST="$PAGE_DIR/manifest.json"

  if [[ ! -f "$PAGE_MANIFEST" ]]; then
    err "Manifest missing: Profiles/$DIR_NAME/manifest.json"; continue
  fi

  if ! python3 -m json.tool "$PAGE_MANIFEST" >/dev/null 2>&1; then
    err "Invalid JSON in Profiles/$DIR_NAME/manifest.json"; continue
  fi

  # Validate buttons
  RESULT=$(python3 << PYEOF || true
import json, sys, os

with open("$PAGE_MANIFEST") as f:
    data = json.load(f)

controllers = data.get("Controllers", [])
if not controllers:
    print("0 buttons, 0 errors (no Controllers)")
    sys.exit(0)

actions = controllers[0].get("Actions") or {}
action_ids = []
errors = 0
folder_refs = []

for pos, btn in actions.items():
    parts = pos.split(",")
    if len(parts) != 2:
        print(f"  ERROR: Invalid position key '{pos}'")
        errors += 1
        continue
    try:
        row, col = int(parts[0]), int(parts[1])
        if not (0 <= row <= 7 and 0 <= col <= 3):
            print(f"  ERROR: Position {pos} out of bounds (0-7, 0-3)")
            errors += 1
    except ValueError:
        print(f"  ERROR: Non-numeric position '{pos}'")
        errors += 1

    aid = btn.get("ActionID", "")
    if not aid:
        print(f"  ERROR: Missing ActionID at {pos}")
        errors += 1
    elif aid in action_ids:
        print(f"  ERROR: Duplicate ActionID '{aid}' at {pos}")
        errors += 1
    else:
        action_ids.append(aid)

    if "UUID" not in btn:
        print(f"  ERROR: Missing UUID at {pos}")
        errors += 1

    states = btn.get("States", [])
    for s in states:
        img = s.get("Image", "")
        if img:
            img_path = os.path.join("$PAGE_DIR", img)
            if not os.path.isfile(img_path):
                print(f"  ERROR: Missing image '{img}' at {pos}")
                errors += 1

    # Track folder references
    if btn.get("UUID") == "com.elgato.streamdeck.profile.openchild":
        profile_uuid = btn.get("Settings", {}).get("ProfileUUID", "")
        if profile_uuid:
            folder_refs.append((pos, profile_uuid))

for pos, uuid in folder_refs:
    print(f"  INFO: Folder at {pos} -> {uuid}")

print(f"{len(actions)} buttons, {errors} errors")
sys.exit(errors)
PYEOF
  )
  BTN_ERRORS=$?
  echo "$RESULT" | grep -v "^$" | sed 's/^/  /'

  if [[ $BTN_ERRORS -eq 0 ]]; then
    ok "Profiles/$DIR_NAME: valid"
  else
    err "Profiles/$DIR_NAME: $BTN_ERRORS button error(s)"
  fi
done

ok "Total profile directories: $PROFILE_COUNT"

echo ""
echo "=== Results ==="
echo "Errors: $ERRORS"
echo "Warnings: $WARNS"
[[ $ERRORS -eq 0 ]] && echo "Profile is valid!" || echo "Profile has errors -- fix before importing"
exit $ERRORS
