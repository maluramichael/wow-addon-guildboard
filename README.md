# GuildBoard

Visual guild roster dashboard with grouping, search, and deep filtering.

## Summary

At-a-glance guild overview with class/role/rank grouping, item level extraction from notes, alt detection, and powerful filters — all in a clean, resizable dark UI.

## Description

GuildBoard turns your guild roster into a rich, searchable dashboard. Members are displayed in a compact table with class icons, color-coded names, level, item level (parsed from guild notes), rank, zone, and notes. Group them by class, role, rank, level range, or online status with a single click.

Filters let you instantly narrow down the roster: toggle offline visibility, hide alts, set a minimum level, or set a minimum item level. Alt detection and iLvl extraction patterns are fully configurable via Lua patterns, so they adapt to any guild's note conventions.

The raid-ready counter in the status bar shows how many members meet the level threshold (excluding alts when hidden). Right-click any member for quick whisper or invite. The window is resizable and remembers its size between sessions.

## Features

- **5 Group Modes** — By Class, Role, Rank, Level, or Online Status via dropdown
- **Item Level Column** — Extracts iLvl from guild notes with configurable patterns
- **Alt Detection** — Identifies alts via note patterns (e.g. notes starting with "ALT")
- **Powerful Filters** — Show Offline checkbox, Hide Alts checkbox, Min Level input, Min iLvl input
- **Search** — Filter by name, class, zone, rank, or note content
- **Collapsible Groups** — Click headers to collapse/expand, with online counts per group
- **Raid Ready Counter** — Status bar shows max-level count (respects alt filter)
- **Class Colors** — Color bar, icon, and name tinted per class throughout
- **Member Tooltips** — Full details on hover: level, class, rank, zone, notes, alt info
- **Context Menu** — Right-click to whisper or invite online members
- **Click to Whisper** — Left-click any online member to open whisper
- **Resizable Window** — Drag the bottom-right grip, size persists across sessions
- **LDB Minimap Button** — Quick access with guild stats tooltip
- **Dark Polished UI** — Clean dark theme with gold accents matching the MM addon suite
- **Dual Client** — Works on both Anniversary and Retail (Midnight)

## Configuration

All patterns and defaults are configurable in `/gb config`:

- **Alt Patterns** — Lua patterns checked against notes (default: `^alt`)
- **iLvl Patterns** — Lua patterns with `(%d+)` capture to extract item level
- **Raid Ready Level** — Threshold for the raid-ready counter
- **Default filters** — Show Offline, Hide Alts, Min Level

### Default iLvl Patterns

| Pattern | Matches |
|---------|---------|
| `(%d+)%s*ilvl` | "230 ilvl" |
| `ilvl%s*(%d+)` | "ilvl 230" |
| `(%d+)%s*-%s*ilvl` | "251 - ilvl" |

## Slash Commands

- `/gb` — Toggle window
- `/gb config` — Open options
- `/gb refresh` — Refresh guild roster
