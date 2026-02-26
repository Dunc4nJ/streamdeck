# Vibecoding Stream Deck XL Profile

A 32-button prompt palette for multi-agent vibecoding workflows on the Elgato Stream Deck XL.

## Installation

1. Install the [Elgato Stream Deck software](https://www.elgato.com/downloads)
2. Double-click `vibecoding_profile.streamDeckProfile` to import

## File Format

The `.streamDeckProfile` file is a **ZIP archive** containing:

```
<UUID>.sdProfile/
  manifest.json              # Top-level profile metadata (device model, pages)
  Images/                    # (empty at top level)
  Profiles/
    <PAGE_ID>/
      manifest.json          # Button layout and actions for this page
      Images/
        <IMAGE_ID>.png       # Button icon images (144x144 PNG)
```

## How to Edit Programmatically

### 1. Extract

```bash
mkdir /tmp/sd-edit
cp vibecoding_profile.streamDeckProfile /tmp/sd-edit/profile.zip
cd /tmp/sd-edit
unzip profile.zip
```

### 2. Locate the Button Manifest

The main button config is at:
```
AFBA0E43-48AA-48AC-958A-81E928D63A81.sdProfile/Profiles/BRMVM6VC1P1AP3DRJG6D7SSB2KZ/manifest.json
```

### 3. Understand the JSON Structure

The manifest contains a `Controllers` array with one entry of type `Keypad`. Inside `Actions`, each button is keyed by grid position `"row,col"` (e.g., `"0,0"` is top-left, `"7,3"` is bottom-right).

The grid is **8 rows x 4 columns** (positions `0,0` through `7,3`).

Each button action looks like:

```json
{
  "ActionID": "<unique-uuid>",
  "LinkedTitle": true,
  "Name": "Text",
  "Plugin": {
    "Name": "Text",
    "UUID": "com.elgato.streamdeck.system.text",
    "Version": "1.0"
  },
  "Settings": {
    "Hotkey": {
      "KeyModifiers": 0,
      "QTKeyCode": 33554431,
      "VKeyCode": -1
    },
    "isSendingEnter": false,
    "isTypingMode": false,
    "pastedText": "THE PROMPT TEXT THAT GETS PASTED"
  },
  "State": 0,
  "States": [
    {
      "FontFamily": "Verdana",
      "FontSize": 6,
      "FontStyle": "Regular",
      "FontUnderline": false,
      "Image": "Images/SOME_IMAGE_ID.png",
      "OutlineThickness": 2,
      "ShowTitle": true,
      "Title": "Button Label",
      "TitleAlignment": "top",
      "TitleColor": "#ffffff"
    }
  ],
  "UUID": "com.elgato.streamdeck.system.text"
}
```

### 4. Common Edits

**Change a button's prompt:**
Edit `Settings.pastedText` for the target grid position.

**Change a button's display label:**
Edit `States[0].Title`.

**Change a button's icon:**
Place a 144x144 PNG in the `Images/` directory and update `States[0].Image` to `"Images/<filename>.png"`.

**Add a new button:**
Add a new entry under `Actions` with a unique `ActionID` (any UUID v4). Use `com.elgato.streamdeck.system.text` for text-paste buttons.

**Change button position:**
Move the action object to a different `"row,col"` key.

**Make a button send Enter after pasting:**
Set `Settings.isSendingEnter` to `true`.

### 5. Repackage

```bash
cd /tmp/sd-edit
rm profile.zip
zip -r vibecoding_profile.streamDeckProfile AFBA0E43-48AA-48AC-958A-81E928D63A81.sdProfile/
cp vibecoding_profile.streamDeckProfile /path/to/repo/
```

**Important:** The ZIP must contain the `.sdProfile` directory at root level (not nested in extra directories). Use `unzip -l` to verify structure before replacing the original.

### 6. Validate

```bash
# Verify ZIP structure is correct
unzip -l vibecoding_profile.streamDeckProfile | head -5
# Should show: AFBA0E43-48AA-48AC-958A-81E928D63A81.sdProfile/ at root

# Verify manifest is valid JSON
unzip -p vibecoding_profile.streamDeckProfile "AFBA0E43-48AA-48AC-958A-81E928D63A81.sdProfile/Profiles/BRMVM6VC1P1AP3DRJG6D7SSB2KZ/manifest.json" | python3 -m json.tool > /dev/null && echo "Valid JSON"
```

## Button Action Types

| Plugin UUID | Name | Purpose |
|---|---|---|
| `com.elgato.streamdeck.system.text` | Text | Pastes text into the focused application |
| `com.elgato.streamdeck.system.hotkey` | Hotkey | Sends a keyboard shortcut |

Most buttons in this profile are **Text** actions that paste prompts into a terminal running Claude Code or similar AI coding tools.

## Current Layout

| | Col 0 | Col 1 | Col 2 | Col 3 |
|---|---|---|---|---|
| **Row 0** | New Term (hotkey) | Code Review | Default New Agent | Read & Continue |
| **Row 1** | Execute Beads | Reread AGENTS | Next Bead | Use BV |
| **Row 2** | Create Beads | Ultrathink | Scrutinize UX | Fresh Eyes Review |
| **Row 3** | Expand README | Check Mail & Work | Revise README | Improve UX |
| **Row 4** | Run UBS | Read AGENTS+README | Review Beads | Expand README |
| **Row 5** | BV Insights | Register Agent Mail | PROCEED | Compare LLM Plans |
| **Row 6** | Check Agent Mail | Vercel Deploy | Commit & Push | Build UX |
| **Row 7** | Optimize Backend | DO IT w/ TODO | Test Coverage | Random Inspect |
