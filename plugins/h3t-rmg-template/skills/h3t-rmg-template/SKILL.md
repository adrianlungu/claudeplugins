---
name: h3t-rmg-template
description: Use when creating, editing, or analyzing Heroes 3 HotA RMG template (.h3t) files - guides zone design, connection topology, treasure balancing, and produces valid TSV-format h3t output
---

# Heroes 3 HotA RMG Template Builder

## Overview

Creates valid `.h3t` files for Heroes of Might and Magic 3: Horn of the Abyss Random Map Generator. The h3t format is **tab-separated values (TSV)**, not binary. Each file defines a template pack containing one or more templates, each with zones and connections.

## Generator Script

**IMPORTANT**: A Python generator library exists alongside this skill at `h3t_generator.py`.

When asked to create an h3t template:
1. **Copy** `h3t_generator.py` from this skill's directory to the user's working directory
2. **Write a Python build script** that imports from it:
   ```python
   from h3t_generator import H3tBuilder, make_zone, make_connection, ALL_TOWNS, MINES_BASIC

   pack = H3tBuilder("Pack Name", "Template Name", min_size="L+UG", max_size="L+UG")
   pack.set_description("Description here")
   pack.max_battle_rounds = "100"
   pack.special_weeks_disabled = True
   pack.spell_research = True

   # Single template (add zones/connections directly to pack)
   pack.add_zone(make_zone(1, "human", size=10, placement="ground",
                            ownership=1, min_castles=1, ...))
   pack.add_connection(make_connection(1, 2, value=5000))
   pack.write("output.h3t")

   # Multi-template pack (difficulty variants etc)
   casual = pack.add_template("My Map - Casual", min_size="L+UG", max_size="L+UG")
   casual.add_zone(make_zone(...))
   casual.add_connection(make_connection(...))

   hard = pack.add_template("My Map - Hard", min_size="L+UG", max_size="L+UG")
   hard.add_zone(make_zone(...))
   hard.add_connection(make_connection(...))

   pack.write("output.h3t")
   ```
3. **Run the script** to produce the .h3t file
4. **Clean up** the copied generator and build script (keep only the .h3t output)

### Builder API

**`H3tBuilder(pack_name, template_name, min_size, max_size)`**
- Sizes: int or string: "S", "S+UG", "M", "M+UG", "L", "L+UG", "XL", "XL+UG", "H", "H+UG", "XH", "XH+UG", "G", "G+UG"
- `.set_description(text)` — multiline OK, auto-quoted
- `.max_battle_rounds = "100"` — **always set to "100"** (required by HotA)
- `.special_weeks_disabled = True` — **always True** for competitive templates
- `.spell_research = True` — standard for competitive
- `.add_zone(fields)` / `.add_connection(fields)` — for single-template packs
- `.add_template(name, min_size, max_size)` -> `TemplateVariant` — for multi-template packs
- `.write(path)` — writes the .h3t file

**`make_zone(zone_id, zone_type, size, placement, ...)`** — see docstring in `h3t_generator.py`

**`make_connection(z1, z2, value, ...)`** — see docstring in `h3t_generator.py`

### Constants
- `ALL_TOWNS = [True]*12` — all 12 town types (Castle..Cove + Factory + Bulwark)
- `MINES_BASIC = [1, 0, 1, 0, 0, 0, 1]` — wood + ore + gold
- `MINES_ALL = [1, 1, 1, 1, 1, 1, 1]` — all mine types
- `TERRAIN_GRASS`, `TERRAIN_SUBTERRANEAN`, `TERRAIN_MIXED_SURFACE`, `TERRAIN_HOSTILE`

## Critical Rules (Learned from Real Templates)

These are non-negotiable. Violating any will produce broken or unplayable templates.

### Format Rules
- **140 columns per data row**: 15 pack + 13 template + 99 zone + 13 connection
- **Field counts MUST be `12, 10, 4, 8, 10, 18, 4`** — wrong values = template rejected
- **`\r\n` line endings** (Windows CRLF), `\t` field separator
- **Max Battle Rounds must be "100"** — every working template has this
- **Special Weeks Disabled must be `x`** — every working template has this

### Zone Rules
- **Restrictions MUST be non-zero** on every zone AND connection — `(0,0,0,0)` = unplayable
- **Ownership is 1-indexed**: player 1 = `1`, player 2 = `2`, etc. (NOT 0-indexed)
- **HumanStart does NOT auto-give a castle** — you MUST set `min_castles=1`
- **12 town types** in allowed towns and monster towns: Castle..Cove + Factory + Bulwark

### Neutral Town Rules (CRITICAL for balance)
- **Use exact minimum counts** (`neutral_min_towns=2`) — NEVER use density for castles
- **Density causes random clustering** — 3-4 castles next to each other = game-breaking
- Working templates (Jebus Cross, Diamond) ONLY use `minT=N` and `minC=N`, never density

### Road Rules
- **Roads should mostly be random** (empty string, not `"+"`) — prevents "follow road to castle"
- Only force roads (`"+"`) on start-to-expansion connections (so players find their way out)
- Everything else: random or no road — makes exploration unpredictable

### Treasure Density Rules
- Density values in working templates are **5-10** (not 1-3 like you'd expect)
- Firewalk uses densities up to 20-100 for packed zones
- **Always populate all 3 treasure ranges** — range 3 with low values creates many small pickups
- Empty zones = boring games; density 5+ = packed, interesting zones

## File Structure

An h3t file has:
1. **3 header rows** (field names and section counts)
2. **Data rows** (one per zone/connection, tab-separated)

Each data row has **4 sections** (140 columns total):
- Pack fields (15 columns) — written only on first row, rest are empty tabs
- Template fields (13 columns) — written only on first row of each template
- Zone fields (99 columns) — one zone per row
- Connection fields (13 columns) — one connection link per row

A pack can contain **multiple templates** (e.g., difficulty variants). Each template has its own zones and connections. The pack fields are written only once (row 0); each template starts with its template fields on a new row.

## Pack Fields (15 columns)

| # | Field | Type | Notes |
|---|-------|------|-------|
| 1-7 | Field counts | int | **Must be `12, 10, 4, 8, 10, 18, 4`** |
| 8 | Name | string | Pack name |
| 9 | Description | multiline | Quoted if contains newlines |
| 10 | Town selection | override list | Disabled towns: `-0 -3` |
| 11 | Heroes | override list | Hero overrides |
| 12 | Mirror | bool | Mirror template flag |
| 13 | Tags | string | (empty) |
| 14 | Max Battle Rounds | string | **"100"** |
| 15 | Forbid Hiring Heroes | bool | HotA 1.7+ |

## Template Fields (13 columns)

| # | Field | Type |
|---|-------|------|
| 1 | Name | string |
| 2 | Minimum Size | int (MapSize) |
| 3 | Maximum Size | int (MapSize) |
| 4 | Artifacts | override list |
| 5 | Combo Arts | (empty) |
| 6 | Spells | override list |
| 7 | Secondary skills | override list |
| 8 | Objects | override list |
| 9 | Rock blocks | string |
| 10 | Zone sparseness | string |
| 11 | Special weeks disabled | bool — **always `x`** |
| 12 | Spell Research | bool |
| 13 | Anarchy | bool |

### MapSize Values
```
S=1  S+UG=2  M=4  M+UG=8  L=9  L+UG=18  XL=16  XL+UG=32
H=25  H+UG=50  XH=36  XH+UG=72  G=49  G+UG=99
```

## Zone Fields (99 columns)

### Identity (5): Id, HumanStart, ComputerStart, Treasure, Junction
### Size (1): Base size (smaller = more packed content per tile)
### Restrictions (4): MinHuman, MaxHuman, MinTotal, MaxTotal — **MUST be non-zero**
### Player Towns (5): Ownership(1-8), MinTowns, MinCastles, TownDensity, CastleDensity
### Neutral Towns (5): MinTowns, MinCastles, TownDensity, CastleDensity, SameType
### Allowed Towns (12): Castle..Cove + Factory + Bulwark
### Min Mines (7): Wood, Mercury, Ore, Sulfur, Crystal, Gems, Gold
### Mine Density (7): Same order
### Terrain (11): MatchToTown, Dirt, Sand, Grass, Snow, Swamp, Rough, Cave, Lava, Highlands, Wasteland
### Monsters (15): Strength(none/weak/avg/strong), MatchToTown, Neutral, + 12 faction bools
### Treasure (9): 3 ranges x (Low, High, Density) — use ALL 3 ranges, density 5-10
### Options (4): Placement, Objects, MinObjects, ImageSettings
### Advanced (4): ForceNeutral, NonCoherentRoad, ZoneRepulsion, TownHint
### Disposition (3): Standard(0-5), Custom(1-9), JoinPercent(0-3)
### JoinForMoney (1): bool
### HotA 1.7+ (6): AirshipMin, AirshipDens, TerrainHint, AllowedFactions, FactionHint, MaxBlockValue

## Connection Fields (13 columns)

| # | Field | Type | Notes |
|---|-------|------|-------|
| 1-2 | Zone 1, Zone 2 | int | |
| 3 | Value | NonZeroInt | Guard strength |
| 4 | Wide | bool | |
| 5 | Border Guard | string | |
| 6 | Road | string | `"+"` yes, `"-"` no, empty=random (**prefer random**) |
| 7 | Type | string | empty, "ground", "underground", "teleport", "random" |
| 8 | Fictive | bool | |
| 9 | Portal repulsion | bool | |
| 10-13 | Restrictions | int | **MUST be non-zero** |

## Design Guidelines

### Zone Sizing (smaller = more packed)
- Start: 8-12 | Expansion: 10-20 | Center: 20-35 | Underground: 10-18

### Guard Progression
- Start->expansion: 2500-4500 | Expansion->center: 10000-20000
- Underground entry: 3000-7000 | UG->UG center: 10000-25000
- Cross-layer portal: 20000-35000

### Treasure Density (the key to "packed" feeling)
- Minimum density 5 for any zone; 7-10 for packed/competitive
- Always fill all 3 ranges per zone
- Range 3 with low values (100-300) creates many small pickups

### Neutral Towns
- Use `neutral_min_towns=N` (exact count), NEVER `neutral_town_density`
- Start zones: 0-1 towns | Expansions: 1-2 towns | Centers: 1-2 castles

### Mine Counts (generous = fun)
- Start: 2-4 wood, 2-4 ore, 1-2 gold (easy early economy)
- Expansion: add rare mines guaranteed or by density
- Jebus Cross gives 4 wood, 4 ore, 1 each rare, 2 gold per start
