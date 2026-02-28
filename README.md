# Vibecoding Stream Deck XL Profile

A 32-button prompt palette for multi-agent vibecoding workflows on the Elgato Stream Deck XL.

## Installation

1. Install the [Elgato Stream Deck software](https://www.elgato.com/downloads)
2. Double-click `vibecoding_profile.streamDeckProfile` to import

## File Format (v3.0 — Stream Deck app 7.2+)

The `.streamDeckProfile` file is a **ZIP archive** containing:

```
package.json                                    # App version, device model, required plugins
Profiles/
  <PROFILE_UUID>.sdProfile/
    manifest.json                               # Top-level profile metadata (device, pages)
    Images/                                     # (empty at top level)
    Profiles/
      <PAGE_UUID>/                              # Main page (UPPERCASE dir name)
        manifest.json                           # Button layout and actions
        Images/
          <IMAGE_ID>.png                        # Button icon images (144x144 PNG)
      <FOLDER_UUID>/                            # Folder sub-profile (UPPERCASE dir name)
        manifest.json                           # Folder button layout
        Images/
          <IMAGE_ID>.png
```

> **UUID Case Convention:** Directory names on disk are **UPPERCASE** (e.g., `D81BA1C7-8793-42DF-8A14-1E65A3B4FEEC/`), but JSON references use **lowercase** (e.g., `"d81ba1c7-8793-42df-8a14-1e65a3b4feec"`). This is critical for programmatic creation.

## How to Edit Programmatically

### 1. Extract

```bash
mkdir /tmp/sd-edit
cp vibecoding_profile.streamDeckProfile /tmp/sd-edit/profile.zip
cd /tmp/sd-edit
unzip profile.zip
```

### 2. Locate Key Files

```
package.json                                                          # Root metadata
Profiles/<PROFILE_UUID>.sdProfile/manifest.json                       # Profile config
Profiles/<PROFILE_UUID>.sdProfile/Profiles/<PAGE_UUID>/manifest.json  # Button actions
```

For this profile specifically:
```
Profiles/0B033AA6-23B9-4FEF-AEEB-712C1C7B7EB4.sdProfile/Profiles/AB4EE207-144A-4F32-A93B-73A3EA0F157F/manifest.json
```

### 3. Understand the JSON Structure

#### package.json (ZIP root)

Required metadata for Stream Deck app 7.2+:

```json
{
  "AppVersion": "7.2.1.22472",
  "DeviceModel": "20GAT9902",
  "DeviceSettings": null,
  "FormatVersion": 1,
  "OSType": "macOS",
  "OSVersion": "14.5.0",
  "RequiredPlugins": [
    "com.elgato.streamdeck.system.hotkey",
    "com.elgato.streamdeck.profile.openchild",
    "com.elgato.streamdeck.profile.backtoparent",
    "com.elgato.streamdeck.system.text"
  ]
}
```

Key fields:
- `DeviceModel` — `"20GAT9902"` for Stream Deck XL
- `RequiredPlugins` — list all plugin UUIDs used by buttons in the profile (including folder/back plugins if folders exist)

#### Top-level manifest.json

```json
{
  "Device": { "Model": "20GAT9902", "UUID": "<device-uuid>" },
  "Name": "Profile Name",
  "Pages": {
    "Current": "00000000-0000-0000-0000-000000000000",
    "Default": "<default-page-uuid>",
    "Pages": ["<main-page-uuid>"]
  },
  "Version": "3.0"
}
```

Key fields:
- `Pages.Pages` — array of page UUIDs (lowercase). **Folders are NOT listed here** — only actual pages.
- `Pages.Default` — can point to an empty fallback page
- `Pages.Current` — `"00000000-0000-0000-0000-000000000000"` is a special "current page" value
- `Version` — must be `"3.0"`

#### Page/Folder manifest.json (button layout)

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
  "Resources": null,
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
Add a new entry under `Actions` with a unique `ActionID` (any UUID v4). Use `com.elgato.streamdeck.system.text` for text-paste buttons. Include `"Resources": null`.

**Change button position:**
Move the action object to a different `"row,col"` key.

**Make a button send Enter after pasting:**
Set `Settings.isSendingEnter` to `true`.

### 5. Repackage

```bash
cd /tmp/sd-edit
rm profile.zip
# ZIP from the directory containing package.json and Profiles/
zip -r vibecoding_profile.streamDeckProfile package.json Profiles/
cp vibecoding_profile.streamDeckProfile /path/to/repo/
```

**Important:** The ZIP must contain `package.json` and `Profiles/` at root level. Use `unzip -l` to verify structure before replacing the original.

### 6. Validate

```bash
# Verify ZIP structure is correct
unzip -l vibecoding_profile.streamDeckProfile | head -5
# Should show: package.json and Profiles/ at root

# Verify package.json is valid JSON
unzip -p vibecoding_profile.streamDeckProfile "package.json" | python3 -m json.tool > /dev/null && echo "Valid package.json"

# Verify main manifest is valid JSON
unzip -p vibecoding_profile.streamDeckProfile \
  "Profiles/0B033AA6-23B9-4FEF-AEEB-712C1C7B7EB4.sdProfile/Profiles/AB4EE207-144A-4F32-A93B-73A3EA0F157F/manifest.json" \
  | python3 -m json.tool > /dev/null && echo "Valid manifest JSON"

# Or run the included validator
bash validate-profile.sh
```

## Button Action Types

| Plugin UUID | Name | Purpose |
|---|---|---|
| `com.elgato.streamdeck.system.text` | Text | Pastes text into the focused application |
| `com.elgato.streamdeck.system.hotkey` | Hotkey | Sends a keyboard shortcut |
| `com.elgato.streamdeck.page.next` | Next Page | Navigate to the next page |
| `com.elgato.streamdeck.page.previous` | Previous Page | Navigate to the previous page |
| `com.elgato.streamdeck.page.pop` | Go to Page | Jump to a specific page |
| `com.elgato.streamdeck.profile.openchild` | Create Folder | Opens a nested group of buttons |
| `com.elgato.streamdeck.profile.backtoparent` | Back to Parent | Returns from folder to parent view |

Most buttons in this profile are **Text** actions that paste prompts into a terminal running Claude Code or similar AI coding tools.

### Text Button

Pastes text into the focused application when pressed. The workhorse of this profile.

```json
{
  "ActionID": "864aa3cc-a354-46cd-9a88-9125442795ce",
  "LinkedTitle": true,
  "Name": "Text",
  "Plugin": {
    "Name": "Text",
    "UUID": "com.elgato.streamdeck.system.text",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {
    "Hotkey": {
      "KeyModifiers": 0,
      "QTKeyCode": 33554431,
      "VKeyCode": -1
    },
    "isSendingEnter": false,
    "isTypingMode": false,
    "pastedText": "YOUR PROMPT TEXT HERE"
  },
  "State": 0,
  "States": [
    {
      "FontFamily": "Verdana",
      "FontSize": 10,
      "FontStyle": "Regular",
      "FontUnderline": false,
      "Image": "Images/YOUR_IMAGE_ID.png",
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

Key fields:
- `Settings.pastedText` — the text that gets pasted
- `Settings.isSendingEnter` — set `true` to press Enter after pasting (auto-submit)
- `Settings.isTypingMode` — `true` types character-by-character (slower, more compatible); `false` pastes from clipboard (faster)
- `Resources` — always `null` for v3.0
- `States[0].Image` — path to the button icon PNG (omit for no icon)
- `States[0].Title` — text label shown on the button
- `States[0].ShowTitle` — `false` to hide the label and show only the icon

### Hotkey Button

Sends a keyboard shortcut. The `Hotkeys` array supports up to 4 simultaneous key combos.

```json
{
  "ActionID": "8a2ee19c-77f1-4128-bf9b-050be956f866",
  "LinkedTitle": true,
  "Name": "Hotkey",
  "Plugin": {
    "Name": "Activate a Key Command",
    "UUID": "com.elgato.streamdeck.system.hotkey",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {
    "Coalesce": true,
    "Hotkeys": [
      {
        "KeyCmd": false,
        "KeyCtrl": true,
        "KeyModifiers": 3,
        "KeyOption": false,
        "KeyShift": true,
        "NativeCode": 53,
        "QTKeyCode": 53,
        "VKeyCode": 53
      }
    ]
  },
  "State": 0,
  "States": [
    {
      "FontFamily": "",
      "FontSize": 9,
      "FontStyle": "",
      "FontUnderline": false,
      "OutlineThickness": 2,
      "ShowTitle": true,
      "Title": "New Term",
      "TitleAlignment": "top",
      "TitleColor": "#ffffff"
    }
  ],
  "UUID": "com.elgato.streamdeck.system.hotkey"
}
```

Key fields:
- `Settings.Hotkeys[]` — array of key combos (unused slots have `VKeyCode: -1`)
- `KeyCmd` / `KeyCtrl` / `KeyShift` / `KeyOption` — modifier keys (boolean)
- `KeyModifiers` — bitmask: 1=Shift, 2=Ctrl, 4=Option, 8=Cmd (sum for combos, e.g. Ctrl+Shift = 3)
- `NativeCode` — platform-specific key code
- `VKeyCode` — virtual key code (`-1` means unused/empty slot)
- `Settings.Coalesce` — `true` to send all hotkeys as one action

### Next Page / Previous Page

Navigation buttons for multi-page profiles. No settings required.

```json
{
  "ActionID": "<generate-uuid-v4>",
  "LinkedTitle": true,
  "Name": "Next Page",
  "Plugin": {
    "Name": "Next Page",
    "UUID": "com.elgato.streamdeck.page.next",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {},
  "State": 0,
  "States": [
    {
      "FontFamily": "",
      "FontSize": 12,
      "FontStyle": "",
      "FontUnderline": false,
      "OutlineThickness": 2,
      "ShowTitle": true,
      "Title": "Next \u2192",
      "TitleAlignment": "middle",
      "TitleColor": "#ffffff"
    }
  ],
  "UUID": "com.elgato.streamdeck.page.next"
}
```

For Previous Page, replace:
- `Plugin.Name` → `"Previous Page"`
- `Plugin.UUID` → `"com.elgato.streamdeck.page.previous"`
- `UUID` → `"com.elgato.streamdeck.page.previous"`
- `Title` → `"\u2190 Prev"`

To add a second page, update the **top-level** `manifest.json`:

```json
{
  "Device": { "Model": "20GAT9902", "UUID": "" },
  "Name": "Default Profile",
  "Pages": {
    "Current": "00000000-0000-0000-0000-000000000000",
    "Default": "<default-page-uuid>",
    "Pages": [
      "<page-1-uuid>",
      "<page-2-uuid>"
    ]
  },
  "Version": "3.0"
}
```

Then create a new directory under `Profiles/` named `<PAGE_2_UUID>/` (UPPERCASE) with its own `manifest.json` and `Images/` folder, following the same structure as the existing page. Add the page's UUID (lowercase) to the `Pages.Pages` array. Also add `com.elgato.streamdeck.page.next` and/or `.previous` to `RequiredPlugins` in `package.json`.

### Go to Page

Jumps directly to a specific page number.

```json
{
  "ActionID": "<generate-uuid-v4>",
  "LinkedTitle": true,
  "Name": "Go To Page",
  "Plugin": {
    "Name": "Go To Page",
    "UUID": "com.elgato.streamdeck.page.pop",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {
    "ProfileUUID": "<target-page-uuid-lowercase>"
  },
  "State": 0,
  "States": [
    {
      "FontFamily": "",
      "FontSize": 12,
      "FontStyle": "",
      "FontUnderline": false,
      "OutlineThickness": 2,
      "ShowTitle": true,
      "Title": "Page 2",
      "TitleAlignment": "middle",
      "TitleColor": "#ffffff"
    }
  ],
  "UUID": "com.elgato.streamdeck.page.pop"
}
```

Key fields:
- `Settings.ProfileUUID` — the UUID of the target page (**lowercase**, must match an entry in the top-level manifest's `Pages.Pages` array)

### Create Folder

A folder button opens a nested sub-layout. When pressed, the Stream Deck displays the folder's buttons. Folders are **not** listed in the `Pages.Pages` array — they are separate sub-profiles linked by `Settings.ProfileUUID`.

Folder opener button (on the main page):

```json
{
  "ActionID": "<generate-uuid-v4>",
  "LinkedTitle": true,
  "Name": "Create Folder",
  "Plugin": {
    "Name": "Create Folder",
    "UUID": "com.elgato.streamdeck.profile.openchild",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {
    "ProfileUUID": "<folder-sub-profile-uuid-lowercase>"
  },
  "State": 0,
  "States": [
    {
      "FontFamily": "Verdana",
      "FontSize": 10,
      "FontStyle": "Regular",
      "FontUnderline": false,
      "OutlineThickness": 2,
      "ShowTitle": true,
      "Title": "My Folder",
      "TitleAlignment": "top",
      "TitleColor": "#ffffff"
    }
  ],
  "UUID": "com.elgato.streamdeck.profile.openchild"
}
```

Back button (inside the folder at position `0,0`):

```json
{
  "ActionID": "<generate-uuid-v4>",
  "LinkedTitle": true,
  "Name": "Parent Folder",
  "Plugin": {
    "Name": "Open Parent Folder",
    "UUID": "com.elgato.streamdeck.profile.backtoparent",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {},
  "State": 0,
  "States": [{}],
  "UUID": "com.elgato.streamdeck.profile.backtoparent"
}
```

The folder's contents are stored as a separate sub-profile directory under `Profiles/`, following the same manifest structure as a page. The `Settings.ProfileUUID` (lowercase) links to that sub-profile's directory name (UPPERCASE).

```
Profiles/
  <PAGE_UUID>/           # Main page
    manifest.json
    Images/
  <FOLDER_UUID>/         # Folder contents (UPPERCASE dir name)
    manifest.json        # Same structure as a page manifest — has its own Actions grid
    Images/
```

The folder's `manifest.json` uses the same `Controllers[0].Actions` structure with `"row,col"` keys. Position `0,0` **must** contain an explicit back button (UUID `com.elgato.streamdeck.profile.backtoparent`). Place folder contents starting from `0,1` onward.

**When creating folders programmatically:**
1. Generate a UUID v4 for the folder
2. Create directory `Profiles/<UPPERCASE-UUID>/` with `manifest.json` and `Images/`
3. Add back button at `0,0` in the folder manifest
4. Add folder opener button on the main page with `Settings.ProfileUUID` set to the **lowercase** UUID
5. Add `com.elgato.streamdeck.profile.openchild` and `com.elgato.streamdeck.profile.backtoparent` to `RequiredPlugins` in `package.json`
6. Do **NOT** add the folder UUID to `Pages.Pages` — folders are separate from pages

**Nesting:** Folders can contain other folder buttons, allowing multi-level nesting.

## Current Layout

### Main Page (8x4 Grid)

| | Col 0 | Col 1 | Col 2 | Col 3 |
|---|---|---|---|---|
| **Row 0** | New Term (hotkey) | Code Review | Default New Agent | Read & Continue |
| **Row 1** | Execute Beads | Reread AGENTS | Next Bead | Use BV |
| **Row 2** | Create Beads | Ultrathink | Scrutinize UX | Fresh Eyes Review |
| **Row 3** | Expand README | Check Mail & Work | Revise README | Improve UX |
| **Row 4** | Run UBS | Read AGENTS+README | Review Beads | Expand README |
| **Row 5** | BV Insights | Register Agent Mail | PROCEED | Compare LLM Plans |
| **Row 6** | Check Agent Mail | Dueling Wizards (folder) | Commit & Push | Build UX |
| **Row 7** | Optimize Backend | DO IT w/ TODO | Test Coverage | Random Inspect |

### Dueling Wizards Folder

| | Col 0 | Col 1 | Col 2 | Col 3 |
|---|---|---|---|---|
| **Row 0** | Back (auto) | Idea Wizard | Score Rivals | Counter-Score |
