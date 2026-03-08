# GuildBoard

At-a-glance guild roster dashboard with grouping, item level parsing, alt detection, and powerful filters.

## Features

- **5 Group Modes** — group by Class, Role, Rank, Level Range, or Online Status via dropdown menu
- **Item Level Column** — extracts iLvl from guild notes using configurable patterns
- **Alt Detection** — identifies alts by note patterns (e.g. notes starting with "ALT")
- **Powerful Filters** — Show Offline, Hide Alts, Min Level, Min iLvl — all in the toolbar
- **Search** — instantly filter by name, class, zone, rank, or note content
- **Collapsible Groups** — click headers to collapse/expand, each showing online count
- **Raid Ready Counter** — status bar tracks max-level characters (respects alt filter)
- **Class Colors** — color bar, icon, and class-tinted name on every row
- **Member Tooltips** — hover for full details: level, class, rank, zone, notes, alt info, raid readiness
- **Context Menu** — right-click to whisper or invite online members
- **Click to Whisper** — left-click any online member to start a whisper
- **Resizable Window** — drag the bottom-right grip; size persists across sessions
- **LDB Minimap Button** — quick access with guild stats in the tooltip
- **Dark Polished UI** — clean dark theme with gold accents matching the MM addon suite

## Usage

### Slash Commands

| Command | Action |
|---------|--------|
| `/gb` | Toggle the main window |
| `/gb config` | Open the options panel |
| `/gb refresh` | Force a guild roster refresh |

### Main Window

- **Search bar** — type to filter the roster in real-time
- **Group Mode** — click the dropdown to switch between Class, Role, Rank, Level, or Status grouping
- **Show Offline** — checkbox to include offline members
- **Hide Alts** — checkbox to filter out characters detected as alts
- **Min Level / Min iLvl** — type a number to set a floor filter
- **Group headers** — click to collapse or expand; shows member count and online count
- **Left-click** a member to whisper them
- **Right-click** a member for whisper/invite options

### LDB / Minimap Button

- **Left-click** — toggle the main window
- **Right-click** — open options
- **Tooltip** — shows total members, online count, and raid-ready count

## Configuration

Open `/gb config` to customize:

### Alt Detection

Lua patterns checked case-insensitively against public and officer notes. One pattern per line.

| Pattern | Matches |
|---------|---------|
| `^alt` | Notes starting with "ALT" (e.g. `ALT Ikoris - 340 ilvl`) |
| `^twink` | Notes starting with "TWINK" |
| `alt of` | Notes containing "alt of" |

### Item Level Extraction

Lua patterns with a `(%d+)` capture group to extract item level from notes. First match wins.

| Pattern | Matches |
|---------|---------|
| `(%d+)%s*ilvl` | `230 ilvl` |
| `ilvl%s*(%d+)` | `ilvl 230` |
| `(%d+)%s*-%s*ilvl` | `251 - ilvl` |

### Other Settings

- **Raid Ready Level** — level threshold for the raid-ready counter
- **Default Group Mode** — which grouping to use when opening the window
- **Show/Hide Minimap Button**

## Requirements

- World of Warcraft Anniversary Edition or Retail (Midnight)
- Ace3 libraries (included via CurseForge packaging)

## Installation

Install via [CurseForge](https://www.curseforge.com/wow/addons) or copy the `GuildBoard` folder into your `Interface\AddOns\` directory.
