#!/usr/bin/env bash
# Validate a .streamDeckProfile file structure and contents
set -uo pipefail

PROFILE="${1:-vibecoding_profile.streamDeckProfile}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ERRORS=0
WARNS=0

err()  { echo "❌ ERROR: $1"; ((ERRORS++)) || true; }
warn() { echo "⚠️  WARN:  $1"; ((WARNS++)) || true; }
ok()   { echo "✅ $1"; }

echo "=== Stream Deck Profile Validator ==="
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

# 3. Root structure
ROOT_DIR=$(unzip -l "$PROFILE" | awk '{print $4}' | grep '\.sdProfile/$' | head -1)
if [[ -n "$ROOT_DIR" ]]; then
  ok "Root .sdProfile directory: $ROOT_DIR"
else
  err "No .sdProfile directory at ZIP root"; exit 1
fi

# Extract
cp "$(cd "$(dirname "$PROFILE")" && pwd)/$(basename "$PROFILE")" "$TMPDIR/archive.zip"
cd "$TMPDIR"
unzip -q archive.zip
SD_DIR="${ROOT_DIR%/}"

# 4. Top-level manifest
TOP_MANIFEST="$SD_DIR/manifest.json"
if [[ -f "$TOP_MANIFEST" ]]; then
  if python3 -m json.tool "$TOP_MANIFEST" >/dev/null 2>&1; then
    ok "Top-level manifest.json is valid JSON"
  else
    err "Top-level manifest.json is invalid JSON"
  fi
else
  err "Missing top-level manifest.json"
fi

# 5. Validate all profile directories
PROFILE_COUNT=0
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

for pos, btn in actions.items():
    parts = pos.split(",")
    if len(parts) != 2:
        print(f"  ❌ Invalid position key '{pos}'")
        errors += 1
        continue
    try:
        row, col = int(parts[0]), int(parts[1])
        if not (0 <= row <= 7 and 0 <= col <= 3):
            print(f"  ❌ Position {pos} out of bounds (0-7, 0-3)")
            errors += 1
    except ValueError:
        print(f"  ❌ Non-numeric position '{pos}'")
        errors += 1

    aid = btn.get("ActionID", "")
    if not aid:
        print(f"  ❌ Missing ActionID at {pos}")
        errors += 1
    elif aid in action_ids:
        print(f"  ❌ Duplicate ActionID '{aid}' at {pos}")
        errors += 1
    else:
        action_ids.append(aid)

    if "UUID" not in btn:
        print(f"  ❌ Missing UUID at {pos}")
        errors += 1

    states = btn.get("States", [])
    for s in states:
        img = s.get("Image", "")
        if img:
            img_path = os.path.join("$PAGE_DIR", img)
            if not os.path.isfile(img_path):
                print(f"  ❌ Missing image '{img}' at {pos}")
                errors += 1

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
[[ $ERRORS -eq 0 ]] && echo "🎉 Profile is valid!" || echo "💥 Profile has errors — fix before importing"
exit $ERRORS
