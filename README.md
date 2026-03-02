# Vibecoding Stream Deck XL Profile

A 32-button prompt palette for multi-agent vibecoding workflows on the Elgato Stream Deck XL, with multi-page support and folder-based button grouping.

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
      <PAGE_1_UUID>/                            # Page 1 — main page (UPPERCASE dir name)
        manifest.json                           # Button layout and actions
        Images/
          <IMAGE_ID>.png                        # Button icon images (144x144 PNG)
      <PAGE_2_UUID>/                            # Page 2 (optional additional pages)
        manifest.json
        Images/
      <FOLDER_UUID>/                            # Folder sub-profile (UPPERCASE dir name)
        manifest.json                           # Folder button layout
        Images/
          <IMAGE_ID>.png
      <DEFAULT_UUID>/                           # Empty fallback page
        manifest.json                           # {"Controllers":[{"Actions":null,"Type":"Keypad"}],...}
        Images/
```

All sub-profiles (pages, folders, default) live as sibling directories under `Profiles/`. There is **no structural difference** between a page directory and a folder directory on disk — the distinction is made in the top-level `manifest.json`:
- **Pages** are listed in the `Pages.Pages` array (ordered)
- **Folders** are referenced by `Settings.ProfileUUID` on folder-opener buttons
- **Default page** is referenced by `Pages.Default`

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
Profiles/268CEC16-E96D-45BB-B272-71BF8C5AB763.sdProfile/manifest.json                                          # Top-level
Profiles/268CEC16-E96D-45BB-B272-71BF8C5AB763.sdProfile/Profiles/69504FFB-41E2-410D-A4E3-A35D76040128/manifest.json  # Page 1
Profiles/268CEC16-E96D-45BB-B272-71BF8C5AB763.sdProfile/Profiles/AC1E1595-5240-46C5-8FEF-A7FE83A80058/manifest.json  # Page 2
Profiles/268CEC16-E96D-45BB-B272-71BF8C5AB763.sdProfile/Profiles/2EEB9127-1957-4BA5-A04B-F65584EFC1FE/manifest.json  # Dueling Wizards folder
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
    "com.elgato.streamdeck.profile.backtoparent",
    "com.elgato.streamdeck.system.text",
    "com.elgato.streamdeck.profile.openchild",
    "com.elgato.streamdeck.page"
  ]
}
```

Key fields:
- `DeviceModel` — `"20GAT9902"` for Stream Deck XL
- `RequiredPlugins` — list **all** plugin UUIDs used by buttons in the profile. This includes:
  - `com.elgato.streamdeck.system.text` — text/paste buttons
  - `com.elgato.streamdeck.system.hotkey` — keyboard shortcut buttons
  - `com.elgato.streamdeck.page` — page navigation buttons (Next/Previous/Go to Page)
  - `com.elgato.streamdeck.profile.openchild` — folder opener buttons
  - `com.elgato.streamdeck.profile.backtoparent` — folder back buttons

> **Important:** For page navigation, add `com.elgato.streamdeck.page` to RequiredPlugins — NOT the variant-specific UUIDs like `.page.next` or `.page.previous`. The page plugin is a single plugin with multiple action variants.

#### Top-level manifest.json

```json
{
  "Device": { "Model": "20GAT9902", "UUID": "<device-uuid>" },
  "Name": "Default Profile copy",
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

Key fields:
- `Pages.Pages` — ordered array of page UUIDs (lowercase). **Only actual pages go here.** Folders are NOT listed — they are linked via `Settings.ProfileUUID` on folder buttons.
- `Pages.Default` — points to an empty fallback page (its manifest has `"Actions": null`)
- `Pages.Current` — `"00000000-0000-0000-0000-000000000000"` is a special "current page" value
- `Version` — must be `"3.0"`
- The order of UUIDs in `Pages.Pages` determines page navigation order (Next Page goes from index 0 to 1 to 2, etc.)

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

# Or run the included validator
bash validate-profile.sh
```

## Button Action Types

Every button has two UUID fields that serve different purposes:

| Field | Purpose |
|---|---|
| `Plugin.UUID` | Identifies the **plugin** that powers the button |
| `UUID` (top-level) | Identifies the specific **action variant** within that plugin |

For most button types, these are identical. The exception is **page navigation** — a single plugin (`com.elgato.streamdeck.page`) provides three action variants (`.next`, `.previous`, `.pop`).

### Reference Table

| Plugin UUID | Action UUID | Name | Purpose |
|---|---|---|---|
| `com.elgato.streamdeck.system.text` | (same) | Text | Pastes text into the focused application |
| `com.elgato.streamdeck.system.hotkey` | (same) | Hotkey | Sends a keyboard shortcut |
| `com.elgato.streamdeck.page` | `.page.next` | Next Page | Navigate to the next page in sequence |
| `com.elgato.streamdeck.page` | `.page.previous` | Previous Page | Navigate to the previous page in sequence |
| `com.elgato.streamdeck.page` | `.page.pop` | Go to Page | Jump directly to a specific page |
| `com.elgato.streamdeck.profile.openchild` | (same) | Create Folder | Opens a nested group of buttons |
| `com.elgato.streamdeck.profile.backtoparent` | (same) | Back to Parent | Returns from folder to parent view |

> **RequiredPlugins:** Add `Plugin.UUID` values (not action UUIDs) to `RequiredPlugins` in `package.json`. For page navigation, this means adding `com.elgato.streamdeck.page` once — not each variant separately.

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

## Configuring Pages & Folders

Pages and folders both create additional button grids, but they work very differently. Understanding the distinction is critical for programmatic profile creation.

### Pages vs Folders

| | Pages | Folders |
|---|---|---|
| **Metaphor** | Browser tabs (horizontal) | Drill-down menu (vertical) |
| **Navigation** | Next/Previous/Go to Page buttons | Folder opener + Back button |
| **Listed in manifest** | Yes — `Pages.Pages` array (ordered) | No — linked via `Settings.ProfileUUID` |
| **Can contain** | Any buttons, including folder openers | Any buttons (must have Back button at 0,0) |
| **Nesting** | Flat — all pages at same level | Can nest folders inside folders |
| **Plugin UUID** | `com.elgato.streamdeck.page` | `com.elgato.streamdeck.profile.openchild` |
| **RequiredPlugins entry** | `com.elgato.streamdeck.page` | `com.elgato.streamdeck.profile.openchild` + `...backtoparent` |
| **When to use** | Need more than 32 buttons | Group related buttons with a labeled entry point |

### Page Navigation Buttons

All page navigation buttons share the same plugin (`com.elgato.streamdeck.page`) but use different action UUIDs. They all have `"Settings": {}` and `"States": [{}]` — the Stream Deck app renders their icons automatically.

#### Next Page

Navigates to the next page in the `Pages.Pages` array. Wraps around from the last page to the first.

```json
{
  "ActionID": "c14ed479-5c83-4d08-b6b6-7302d8070313",
  "LinkedTitle": true,
  "Name": "Next Page",
  "Plugin": {
    "Name": "Pages",
    "UUID": "com.elgato.streamdeck.page",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {},
  "State": 0,
  "States": [{}],
  "UUID": "com.elgato.streamdeck.page.next"
}
```

> **Verified from export.** Note: `Plugin.Name` is `"Pages"` and `Plugin.UUID` is the plugin-level `com.elgato.streamdeck.page`. The action-specific UUID `com.elgato.streamdeck.page.next` goes in the top-level `UUID` field only.

#### Previous Page

Navigates to the previous page. Wraps around from the first page to the last.

```json
{
  "ActionID": "3215bf59-0cfe-48b8-b2cc-d2d546555047",
  "LinkedTitle": true,
  "Name": "Previous Page",
  "Plugin": {
    "Name": "Pages",
    "UUID": "com.elgato.streamdeck.page",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {},
  "State": 0,
  "States": [{}],
  "UUID": "com.elgato.streamdeck.page.previous"
}
```

#### Go to Page

Jumps directly to a specific page by UUID. **Not yet verified from a real export** — extrapolated from the Next/Previous pattern. Use with caution.

```json
{
  "ActionID": "<generate-uuid-v4>",
  "LinkedTitle": true,
  "Name": "Go To Page",
  "Plugin": {
    "Name": "Pages",
    "UUID": "com.elgato.streamdeck.page",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {
    "ProfileUUID": "<target-page-uuid-lowercase>"
  },
  "State": 0,
  "States": [{}],
  "UUID": "com.elgato.streamdeck.page.pop"
}
```

Key fields:
- `Settings.ProfileUUID` — the UUID of the target page (**lowercase**, must match an entry in the top-level manifest's `Pages.Pages` array)

### How to Add a Second Page (Step-by-Step)

This walkthrough adds a Page 2 to an existing single-page profile.

#### Step 1: Generate a UUID for the new page

```bash
uuidgen  # e.g., AC1E1595-5240-46C5-8FEF-A7FE83A80058
```

#### Step 2: Create the page directory

Inside the `.sdProfile/Profiles/` directory, create a new directory with the **UPPERCASE** UUID:

```bash
mkdir -p Profiles/<PROFILE>.sdProfile/Profiles/AC1E1595-5240-46C5-8FEF-A7FE83A80058/Images
```

#### Step 3: Create the page manifest

Write a `manifest.json` for Page 2. This follows the exact same structure as any page manifest:

```json
{
  "Controllers": [
    {
      "Actions": {
        "0,0": {
          "ActionID": "21f219ee-7227-41f2-b3cc-3b5e5934035d",
          "LinkedTitle": true,
          "Name": "Text",
          "Plugin": {
            "Name": "Text",
            "UUID": "com.elgato.streamdeck.system.text",
            "Version": "1.0"
          },
          "Resources": null,
          "Settings": {
            "Hotkey": { "KeyModifiers": 0, "QTKeyCode": 33554431, "VKeyCode": -1 },
            "isSendingEnter": false,
            "isTypingMode": false,
            "pastedText": "Your prompt text here"
          },
          "State": 0,
          "States": [{ "Title": "My Button" }],
          "UUID": "com.elgato.streamdeck.system.text"
        },
        "0,3": {
          "ActionID": "3215bf59-0cfe-48b8-b2cc-d2d546555047",
          "LinkedTitle": true,
          "Name": "Previous Page",
          "Plugin": {
            "Name": "Pages",
            "UUID": "com.elgato.streamdeck.page",
            "Version": "1.0"
          },
          "Resources": null,
          "Settings": {},
          "State": 0,
          "States": [{}],
          "UUID": "com.elgato.streamdeck.page.previous"
        }
      },
      "Type": "Keypad"
    }
  ],
  "Icon": "",
  "Name": ""
}
```

> **Tip:** Always include a Previous Page button on Page 2+ so users can navigate back. Position `0,3` (top-right) is a natural choice.

#### Step 4: Add a Next Page button on Page 1

Add this button to Page 1's manifest at any available position (e.g., `7,3` bottom-right):

```json
"7,3": {
  "ActionID": "c14ed479-5c83-4d08-b6b6-7302d8070313",
  "LinkedTitle": true,
  "Name": "Next Page",
  "Plugin": {
    "Name": "Pages",
    "UUID": "com.elgato.streamdeck.page",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {},
  "State": 0,
  "States": [{}],
  "UUID": "com.elgato.streamdeck.page.next"
}
```

#### Step 5: Register the page in the top-level manifest

Add the new page UUID (**lowercase**) to the `Pages.Pages` array:

```json
{
  "Device": { "Model": "20GAT9902", "UUID": "<device-uuid>" },
  "Name": "Default Profile copy",
  "Pages": {
    "Current": "00000000-0000-0000-0000-000000000000",
    "Default": "<default-page-uuid>",
    "Pages": [
      "69504ffb-41e2-410d-a4e3-a35d76040128",
      "ac1e1595-5240-46c5-8fef-a7fe83a80058"
    ]
  },
  "Version": "3.0"
}
```

The order of UUIDs in `Pages.Pages` determines navigation order — Next Page goes from index 0 to 1 to 2, etc.

#### Step 6: Update RequiredPlugins

Add `"com.elgato.streamdeck.page"` to the `RequiredPlugins` array in `package.json`:

```json
"RequiredPlugins": [
  "com.elgato.streamdeck.system.text",
  "com.elgato.streamdeck.page"
]
```

#### Step 7: Repackage and validate

```bash
rm -f vibecoding_profile.streamDeckProfile
zip -r vibecoding_profile.streamDeckProfile package.json Profiles/
bash validate-profile.sh vibecoding_profile.streamDeckProfile
```

### How to Add a Folder (Step-by-Step)

Folders create a nested button group that opens when pressed and has a Back button to return.

#### Step 1: Generate a UUID for the folder

```bash
uuidgen  # e.g., 2EEB9127-1957-4BA5-A04B-F65584EFC1FE
```

#### Step 2: Create the folder directory

```bash
mkdir -p Profiles/<PROFILE>.sdProfile/Profiles/2EEB9127-1957-4BA5-A04B-F65584EFC1FE/Images
```

#### Step 3: Create the folder manifest

The folder manifest follows the same structure as a page manifest. Position `0,0` **must** contain a Back to Parent button. Place folder content buttons starting from `0,1` onward.

```json
{
  "Controllers": [
    {
      "Actions": {
        "0,0": {
          "ActionID": "18be553e-55e6-4fee-9294-205d13308874",
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
        },
        "0,1": {
          "ActionID": "96bfc65d-a985-4e47-b661-f79221d3413a",
          "LinkedTitle": true,
          "Name": "Text",
          "Plugin": {
            "Name": "Text",
            "UUID": "com.elgato.streamdeck.system.text",
            "Version": "1.0"
          },
          "Resources": null,
          "Settings": {
            "Hotkey": { "KeyModifiers": 0, "QTKeyCode": 33554431, "VKeyCode": -1 },
            "isSendingEnter": false,
            "isTypingMode": false,
            "pastedText": "Your folder button prompt here"
          },
          "State": 0,
          "States": [
            {
              "FontFamily": "Verdana",
              "FontSize": 7,
              "FontStyle": "Regular",
              "FontUnderline": false,
              "Image": "Images/MY_BUTTON_ICON.png",
              "OutlineThickness": 2,
              "ShowTitle": true,
              "Title": "Button Title",
              "TitleAlignment": "top",
              "TitleColor": "#ffffff"
            }
          ],
          "UUID": "com.elgato.streamdeck.system.text"
        }
      },
      "Type": "Keypad"
    }
  ],
  "Icon": "",
  "Name": "My Folder Name"
}
```

Key details for the Back button:
- `Name` must be `"Parent Folder"` (not "Back" or "Open Folder")
- `Plugin.Name` must be `"Open Parent Folder"`
- `Settings` must be `{}` (empty object, not `null`)
- `States` must be `[{}]` (the Stream Deck renders the back icon automatically)

#### Step 4: Add a folder opener button on the parent page

On the page where you want the folder entry point, add:

```json
"6,1": {
  "ActionID": "d4ed992b-3fa0-4954-86c9-26ffe7528810",
  "LinkedTitle": true,
  "Name": "Create Folder",
  "Plugin": {
    "Name": "Create Folder",
    "UUID": "com.elgato.streamdeck.profile.openchild",
    "Version": "1.0"
  },
  "Resources": null,
  "Settings": {
    "ProfileUUID": "2eeb9127-1957-4ba5-a04b-f65584efc1fe"
  },
  "State": 0,
  "States": [
    {
      "FontFamily": "Verdana",
      "FontSize": 7,
      "FontStyle": "Regular",
      "FontUnderline": false,
      "Image": "Images/FOLDER_ICON.png",
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

The critical link: `Settings.ProfileUUID` must be the **lowercase** version of the folder directory name.

#### Step 5: Update RequiredPlugins

Add both folder-related plugins to `package.json`:

```json
"RequiredPlugins": [
  "com.elgato.streamdeck.system.text",
  "com.elgato.streamdeck.profile.openchild",
  "com.elgato.streamdeck.profile.backtoparent"
]
```

#### Step 6: Do NOT add to Pages.Pages

This is the most common mistake. Folder UUIDs must **never** appear in the `Pages.Pages` array. Only actual pages go there. The folder is linked solely through `Settings.ProfileUUID` on the opener button.

### Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Using `com.elgato.streamdeck.page.next` as `Plugin.UUID` | Button doesn't work | Use `com.elgato.streamdeck.page` for Plugin.UUID |
| Adding folder UUID to `Pages.Pages` | Folder appears as a page | Remove from `Pages.Pages`; link via `Settings.ProfileUUID` only |
| UPPERCASE UUID in JSON references | Profile doesn't load | Use lowercase in all JSON fields; UPPERCASE for directory names only |
| Missing `"Resources": null` on buttons | May not import correctly | Always include `"Resources": null` on every button |
| `Settings: null` on Back button | Back button broken | Use `"Settings": {}` (empty object) |
| Wrong `Plugin.Name` on Back button | May not render correctly | Must be `"Open Parent Folder"`, not "Back" or "Open Folder" |
| Adding variant UUIDs to RequiredPlugins | May not import correctly | Use plugin-level UUIDs (e.g., `com.elgato.streamdeck.page`, not `.page.next`) |
| `Pages.Pages` in wrong order | Pages navigate in wrong sequence | Order determines Next/Previous navigation sequence |

## Current Layout

### Page 1 — Main Page (8x4 Grid)

| | Col 0 | Col 1 | Col 2 | Col 3 |
|---|---|---|---|---|
| **Row 0** | New Term (hotkey) | Code Review | Default New Agent | Read & Continue |
| **Row 1** | Execute Beads | Reread AGENTS | Next Bead | Use BV |
| **Row 2** | Create Beads | Ultrathink | Scrutinize UX | Fresh Eyes Review |
| **Row 3** | Expand README | Check Mail & Work | Revise README | Random Inspect |
| **Row 4** | Run UBS | Read AGENTS+README | Review Beads | Expand README |
| **Row 5** | BV Insights | Register Agent Mail | PROCEED | Compare LLM Plans |
| **Row 6** | Check Agent Mail | Dueling Wizards (folder) | Commit & Push | Build UX |
| **Row 7** | Optimize Backend | DO IT w/ TODO | Test Coverage | Next Page |

### Page 2

| | Col 0 | Col 1 | Col 2 | Col 3 |
|---|---|---|---|---|
| **Row 0** | Test Button | | | Previous Page |

### Dueling Wizards Folder

| | Col 0 | Col 1 | Col 2 | Col 3 |
|---|---|---|---|---|
| **Row 0** | Back (auto) | Idea Wizard | Score Rivals | Counter-Score |
