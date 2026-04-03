#!/usr/bin/env python3
"""
h3t_generator.py — Reusable library for generating Heroes 3 HotA RMG template (.h3t) files.

Compatible with HotA 1.7+ (140-column format with Factory, Bulwark, airship fields).

Usage:
    python3 h3t_generator.py output.h3t  # generates example template

As a library:
    from h3t_generator import H3tBuilder, make_zone, make_connection

    builder = H3tBuilder("My Pack", "My Template", min_size=18, max_size=18)
    builder.set_description("A custom template")
    builder.add_zone(make_zone(1, "human", size=10, placement="ground", ...))
    builder.add_connection(make_connection(1, 2, value=3000))
    builder.write("output.h3t")
"""

import sys

TAB = "\t"
CRLF = "\r\n"

# Section sizes for current HotA format
PACK_FIELDS = 15      # 14 original + 1 (Forbid Hiring Heroes)
TEMPLATE_FIELDS = 13  # unchanged
ZONE_FIELDS = 99      # 89 original + 2 town types + 2 monster towns + 6 new end fields
CONNECTION_FIELDS = 13 # unchanged
TOTAL_FIELDS = PACK_FIELDS + TEMPLATE_FIELDS + ZONE_FIELDS + CONNECTION_FIELDS  # 140


# =============================================================================
# Zone and Connection builders
# =============================================================================

def make_zone(zone_id, zone_type, size, placement,
              ownership=0, min_towns=0, min_castles=0, town_density=0, castle_density=0,
              neutral_min_towns=0, neutral_min_castles=0, neutral_town_density=0, neutral_castle_density=0,
              neutral_same_type=False,
              allowed_towns=None,
              min_mines=None,
              mine_density=None,
              terrain_match=False, terrains=None,
              monster_strength="avg", monster_match=False, monster_neutral=True, monster_towns=None,
              treasure_ranges=None,
              image_x=0, image_y=0,
              force_neutral_creatures=False, allow_noncoherent_road=False, zone_repulsion=False,
              town_hints="",
              disposition=2, custom_disposition=0, join_percent=0, join_only_money=False,
              min_airship_shipyards=0, airship_shipyard_density=0,
              terrain_hint="", allowed_factions="", faction_hint="", max_block_value=0,
              restrictions=None):
    """Build 99 TSV fields for a zone (HotA 1.7+ format).

    Args:
        zone_id: Unique zone identifier (int, start from 1)
        zone_type: "human", "computer", "treasure", or "junction"
        size: Zone base size (int, typically 5-50)
        placement: "free", "ground", or "underground"
        ownership: Player number 1-8 (only used for human/computer starts; 1 = player 1)
        min_towns/min_castles: Minimum player towns/castles in this zone
        town_density/castle_density: Density for additional player towns/castles
        neutral_*: Same but for neutral towns
        neutral_same_type: Force all neutral towns to be same type
        allowed_towns: List of 12 bools [Castle, Rampart, Tower, Inferno, Necropolis,
                       Dungeon, Stronghold, Fortress, Conflux, Cove, Factory, Bulwark]
        min_mines: List of 7 ints [Wood, Mercury, Ore, Sulfur, Crystal, Gems, Gold]
        mine_density: List of 7 ints (density for random mine spawning)
        terrain_match: Match terrain to town type
        terrains: List of 10 bools [Dirt, Sand, Grass, Snow, Swamp, Rough,
                  Subterranean, Lava, Highlands, Wasteland]
        monster_strength: "none", "weak", "avg", or "strong"
        monster_match: Match monsters to town type
        monster_neutral: Allow neutral monsters
        monster_towns: List of 12 bools for allowed monster faction types
                       [Castle..Cove, Factory, Bulwark]
        treasure_ranges: List of up to 3 tuples (low, high, density)
        image_x/image_y: Editor display coordinates (0.0-1.0)
        force_neutral_creatures: Force creatures to be neutral
        allow_noncoherent_road: Allow disconnected roads
        zone_repulsion: Enable zone repulsion
        town_hints: Town type hint string (e.g., "s1 d2")
        disposition: 0=AlwaysJoin, 1=Friendly, 2=Aggressive, 3=Hostile, 4=Savage, 5=Custom
        custom_disposition: 1-9 if disposition=5
        join_percent: 0=25%, 1=50%, 2=75%, 3=100%
        join_only_money: Monsters join only for gold
        min_airship_shipyards: Minimum airship shipyards (HotA 1.7+)
        airship_shipyard_density: Airship shipyard density (HotA 1.7+)
        terrain_hint: Terrain hint string (HotA 1.7+)
        allowed_factions: Allowed factions string (HotA 1.7+)
        faction_hint: Faction hint string (HotA 1.7+)
        max_block_value: Max block value (HotA 1.7+, 0 = default)
        restrictions: Tuple (min_human, max_human, min_total, max_total)
    """
    fields = []

    # Zone type (5 fields)
    fields.append(str(zone_id))
    fields.append("x" if zone_type == "human" else "")
    fields.append("x" if zone_type == "computer" else "")
    fields.append("x" if zone_type == "treasure" else "")
    fields.append("x" if zone_type == "junction" else "")

    # Base size (1)
    fields.append(str(size))

    # Restrictions (4)
    r = restrictions or (0, 0, 0, 0)
    fields.extend([str(v) for v in r])

    # Player towns (5) - NonZeroInt for all
    is_start = zone_type in ("human", "computer")
    fields.append(str(ownership) if (is_start and ownership != 0) else "")
    fields.append(str(min_towns) if min_towns else "")
    fields.append(str(min_castles) if min_castles else "")
    fields.append(str(town_density) if town_density else "")
    fields.append(str(castle_density) if castle_density else "")

    # Neutral towns (5)
    fields.append(str(neutral_min_towns) if neutral_min_towns else "")
    fields.append(str(neutral_min_castles) if neutral_min_castles else "")
    fields.append(str(neutral_town_density) if neutral_town_density else "")
    fields.append(str(neutral_castle_density) if neutral_castle_density else "")
    fields.append("x" if neutral_same_type else "")

    # Allowed towns (12: Castle..Cove + Factory + Bulwark)
    at = allowed_towns or [False] * 12
    if len(at) == 10:
        at = list(at) + [False, False]  # auto-pad for backwards compat
    fields.extend(["x" if t else "" for t in at])

    # Minimum mines (7) - NonZeroInt
    mm = min_mines or [0] * 7
    fields.extend([str(v) if v else "" for v in mm])

    # Mine density (7) - NonZeroInt
    md = mine_density or [0] * 7
    fields.extend([str(v) if v else "" for v in md])

    # Terrain (11)
    fields.append("x" if terrain_match else "")
    tr = terrains or [False] * 10
    fields.extend(["x" if t else "" for t in tr])

    # Monsters: Strength + MatchToTown + Neutral + 12 town factions
    fields.append(monster_strength)
    fields.append("x" if monster_match else "")
    fields.append("x" if monster_neutral else "")
    mt = monster_towns or [False] * 12
    if len(mt) == 10:
        mt = list(mt) + [False, False]  # auto-pad
    fields.extend(["x" if t else "" for t in mt])

    # Treasure ranges (9 = 3x3)
    tr_ranges = treasure_ranges or []
    for i in range(3):
        if i < len(tr_ranges) and tr_ranges[i]:
            low, high, density = tr_ranges[i]
            fields.extend([str(low), str(high), str(density)])
        else:
            fields.extend(["", "", ""])

    # Placement
    placement_map = {"free": "", "ground": "ground", "underground": "underground"}
    fields.append(placement_map.get(placement, ""))

    # Objects, Minimum objects
    fields.append("")
    fields.append("")

    # Image settings
    def fmt_float(v):
        if v == 0:
            return "0"
        return f"{v:.3f}".rstrip("0").rstrip(".")

    fields.append(f"{fmt_float(image_x)} {fmt_float(image_y)}")

    # Advanced options
    fields.append("x" if force_neutral_creatures else "")
    fields.append("x" if allow_noncoherent_road else "")
    fields.append("x" if zone_repulsion else "")
    fields.append(town_hints)

    # Monster disposition
    fields.append(str(disposition))
    fields.append(str(custom_disposition) if custom_disposition else "")
    fields.append(str(join_percent))
    fields.append("x" if join_only_money else "")

    # New HotA 1.7+ fields (6 fields)
    fields.append(str(min_airship_shipyards) if min_airship_shipyards else "")
    fields.append(str(airship_shipyard_density) if airship_shipyard_density else "")
    fields.append(terrain_hint)
    fields.append(allowed_factions)
    fields.append(faction_hint)
    fields.append(str(max_block_value) if max_block_value else "")

    assert len(fields) == ZONE_FIELDS, f"Zone {zone_id}: expected {ZONE_FIELDS} fields, got {len(fields)}"
    return fields


def make_connection(z1, z2, value=0, wide=False, border_guard="", road="",
                    conn_type="", fictive=False, portal_repulsion=False,
                    restrictions=None):
    """Build 13 TSV fields for a connection link.

    Args:
        z1, z2: Zone IDs to connect
        value: Guard strength (0 = unguarded)
        wide: Wide passage
        border_guard: Border guard string (e.g., "x prop1 prop2") or empty
        road: "" = random, "+" = yes, "-" = no
        conn_type: "" = default, "ground", "underground", "teleport", "random"
        fictive: Fictive (layout-only) connection
        portal_repulsion: Enable portal repulsion
        restrictions: Tuple (min_human, max_human, min_total, max_total)
    """
    fields = []
    fields.append(str(z1))
    fields.append(str(z2))
    fields.append(str(value) if value else "")
    fields.append("x" if wide else "")
    fields.append(border_guard)
    fields.append(road)
    fields.append(conn_type)
    fields.append("x" if fictive else "")
    fields.append("x" if portal_repulsion else "")
    r = restrictions or (0, 0, 0, 0)
    fields.extend([str(v) for v in r])
    assert len(fields) == CONNECTION_FIELDS, f"Connection {z1}->{z2}: expected {CONNECTION_FIELDS} fields, got {len(fields)}"
    return fields


# =============================================================================
# H3tBuilder — assembles a complete .h3t file
# =============================================================================

class H3tBuilder:
    """Builds a valid .h3t template pack file (HotA 1.7+ format, 140 columns)."""

    # MapSize enum values
    SIZES = {
        "S":    1,  "S+UG":    2,
        "M":    4,  "M+UG":    8,
        "L":    9,  "L+UG":   18,
        "XL":  16,  "XL+UG":  32,
        "H":   25,  "H+UG":   50,
        "XH":  36,  "XH+UG":  72,
        "G":   49,  "G+UG":   99,
    }

    # Field counts for HotA 1.7+ format
    DEFAULT_FIELD_COUNTS = (12, 10, 4, 8, 10, 18, 4)

    def __init__(self, pack_name, template_name, min_size=18, max_size=18,
                 field_counts=None):
        self.pack_name = pack_name
        self.template_name = template_name
        self.min_size = min_size if isinstance(min_size, int) else self.SIZES[min_size]
        self.max_size = max_size if isinstance(max_size, int) else self.SIZES[max_size]
        self.description = ""
        self.town_selection = ""
        self.hero_overrides = ""
        self.mirror = False
        self.max_battle_rounds = ""
        self.forbid_hiring_heroes = False
        self.artifact_overrides = ""
        self.spell_overrides = ""
        self.skill_overrides = ""
        self.object_overrides = ""
        self.rock_blocks = ""
        self.zone_sparseness = ""
        self.special_weeks_disabled = False
        self.spell_research = False
        self.anarchy = False
        self.field_counts = field_counts or self.DEFAULT_FIELD_COUNTS
        self.zones = []
        self.connections = []

    def set_description(self, desc):
        self.description = desc
        return self

    def add_zone(self, zone_fields):
        self.zones.append(zone_fields)
        return self

    def add_connection(self, conn_fields):
        self.connections.append(conn_fields)
        return self

    def add_template(self, template_name, min_size=None, max_size=None):
        """Create and return a new TemplateVariant to add zones/connections to.
        When variants exist, the main template_name/zones/connections are ignored."""
        variant = TemplateVariant(template_name,
                                 min_size or self.min_size,
                                 max_size or self.max_size, self)
        if not hasattr(self, '_variants'):
            self._variants = []
        self._variants.append(variant)
        return variant

    def _get_templates(self):
        """Return list of (template_fields, zones, connections) tuples."""
        if hasattr(self, '_variants') and self._variants:
            return [(v._template_fields(), v.zones, v.connections) for v in self._variants]
        return [(self._template_fields(), self.zones, self.connections)]

    def build(self):
        """Generate the complete h3t file content as a string."""
        rows = self._write_header()
        pack_fields = self._pack_fields()
        pack_written = False

        for tmpl_fields, zones, connections in self._get_templates():
            num_zones = len(zones)
            num_conns = len(connections)
            max_rows = max(num_zones, num_conns)

            for i in range(max_rows):
                row = []
                row.extend(pack_fields if not pack_written else [""] * PACK_FIELDS)
                row.extend(tmpl_fields if i == 0 else [""] * TEMPLATE_FIELDS)
                row.extend(zones[i] if i < num_zones else [""] * ZONE_FIELDS)
                row.extend(connections[i] if i < num_conns else [""] * CONNECTION_FIELDS)
                assert len(row) == TOTAL_FIELDS, f"Row: {len(row)} fields, expected {TOTAL_FIELDS}"
                rows.append(TAB.join(row))
                pack_written = True

        return CRLF.join(rows) + CRLF

    def write(self, path):
        """Write the h3t file to disk."""
        content = self.build()
        with open(path, "w", newline="") as f:
            f.write(content)
        return content

    def _pack_fields(self):
        fc = self.field_counts
        desc = self.description
        if desc and "\n" in desc:
            desc = desc.replace("\r\n", "\n")
            desc = f'"{desc}"'
        return [
            str(fc[0]), str(fc[1]), str(fc[2]), str(fc[3]),
            str(fc[4]), str(fc[5]), str(fc[6]),
            self.pack_name, desc, self.town_selection, self.hero_overrides,
            "x" if self.mirror else "", "", self.max_battle_rounds,
            "x" if self.forbid_hiring_heroes else "",  # HotA 1.7+ field
        ]

    def _template_fields(self):
        return [
            self.template_name, str(self.min_size), str(self.max_size),
            self.artifact_overrides, "", self.spell_overrides, self.skill_overrides,
            self.object_overrides, self.rock_blocks, self.zone_sparseness,
            "x" if self.special_weeks_disabled else "",
            "x" if self.spell_research else "",
            "x" if self.anarchy else "",
        ]

    @staticmethod
    def _write_header():
        rows = []
        # Row 1: Section spans (15 + 13 + 99 + 14 trailing = 140 + trailing)
        rows.append(
            "Pack" + TAB * PACK_FIELDS
            + "Map" + TAB * TEMPLATE_FIELDS
            + "Zone" + TAB * ZONE_FIELDS
            + "Connections" + TAB * CONNECTION_FIELDS
        )
        # Row 2: Sub-section spans
        rows.append(
            "Field count" + TAB * 7 + "Options" + TAB * 22
            + "Type" + TAB * 5 + "Restrictions" + TAB * 4
            + "Player towns" + TAB * 5 + "Neutral towns" + TAB * 5
            + "Town types" + TAB * 12 + "Minimum mines" + TAB * 7
            + "Mine Density" + TAB * 7 + "Terrain" + TAB * 11
            + "Monsters" + TAB * 15 + "Treasure" + TAB * 9
            + "Options" + TAB * 18 + "Zones" + TAB * 2
            + "Options" + TAB * 7 + "Restrictions" + TAB * 3
        )
        # Row 3: Individual column names
        cols = [
            # Pack fields (15)
            "Town", "Terrain", "Zone type", "Pack new", "Map new", "Zone new", "Connection new",
            "Name", "Description", "Town selection", "Heroes", "Mirror", "Tags", "Max Battle Rounds",
            "Forbid Hiring Heroes",
            # Template fields (13)
            "Name", "Minimum Size", "Maximum Size", "Artifacts", "Combo Arts", "Spells",
            "Secondary skills", "Objects", "Rock blocks", "Zone sparseness",
            "Special weeks disabled", "Spell Research", "Anarchy",
            # Zone fields (99)
            "Id", "human start", "computer start", "Treasure", "Junction",
            "Base Size",
            "Minimum human positions", "Maximum human positions",
            "Minimum total positions", "Maximum total positions",
            "Ownership", "Minimum towns", "Minimum castles", "Town Density", "Castle Density",
            "Minimum towns", "Minimum castles", "Town Density", "Castle Density",
            "Towns are of same type",
            "Castle", "Rampart", "Tower", "Inferno", "Necropolis",
            "Dungeon", "Stronghold", "Fortress", "Conflux", "Cove",
            "Factory", "Bulwark",
            "Wood", "Mercury", "Ore", "Sulfur", "Crystal", "Gems", "Gold",
            "Wood", "Mercury", "Ore", "Sulfur", "Crystal", "Gems", "Gold",
            "Match to town", "Dirt", "Sand", "Grass", "Snow", "Swamp", "Rough",
            "Cave", "Lava", "Highlands", "Wasteland",
            "Strength", "Match to town", "Neutral",
            "Castle", "Rampart", "Tower", "Inferno", "Necropolis",
            "Dungeon", "Stronghold", "Fortress", "Conflux", "Cove",
            "Factory", "Bulwark",
            "Low", "High", "Density", "Low", "High", "Density", "Low", "High", "Density",
            "Placement", "Objects", "Minimum objects", "Image settings",
            "Force neutral creatures", "Allow non-coherent road", "Zone repulsion", "Town Hint",
            "Monsters disposition (standard)", "Monsters disposition (custom)",
            "Monsters joining percentage", "Monsters join only for money",
            "Minimum airship shipyards", "Airship shipyard Density",
            "Terrain Hint", "Allowed Factions", "Faction Hint", "Max block value",
            # Connection fields (13)
            "Zone 1", "Zone 2", "Value", "Wide", "Border Guard", "Road", "Type",
            "Fictive", "Portal repulsion",
            "Minimum human positions", "Maximum human positions",
            "Minimum total positions", "Maximum total positions",
        ]
        assert len(cols) == TOTAL_FIELDS, f"Expected {TOTAL_FIELDS} columns, got {len(cols)}"
        rows.append(TAB.join(cols[:-1]) + TAB + cols[-1])
        return rows


# =============================================================================
# TemplateVariant — a single template within a multi-template pack
# =============================================================================

class TemplateVariant:
    """A template variant within an H3tBuilder pack."""

    def __init__(self, name, min_size, max_size, parent):
        self.name = name
        self.min_size = min_size if isinstance(min_size, int) else H3tBuilder.SIZES[min_size]
        self.max_size = max_size if isinstance(max_size, int) else H3tBuilder.SIZES[max_size]
        self.parent = parent
        self.artifact_overrides = ""
        self.spell_overrides = ""
        self.skill_overrides = ""
        self.object_overrides = ""
        self.rock_blocks = ""
        self.zone_sparseness = ""
        self.special_weeks_disabled = parent.special_weeks_disabled
        self.spell_research = parent.spell_research
        self.anarchy = parent.anarchy
        self.zones = []
        self.connections = []

    def add_zone(self, zone_fields):
        self.zones.append(zone_fields)
        return self

    def add_connection(self, conn_fields):
        self.connections.append(conn_fields)
        return self

    def _template_fields(self):
        return [
            self.name, str(self.min_size), str(self.max_size),
            self.artifact_overrides, "", self.spell_overrides, self.skill_overrides,
            self.object_overrides, self.rock_blocks, self.zone_sparseness,
            "x" if self.special_weeks_disabled else "",
            "x" if self.spell_research else "",
            "x" if self.anarchy else "",
        ]


# =============================================================================
# Convenience constants
# =============================================================================

# 12 town types: Castle..Cove + Factory + Bulwark
ALL_TOWNS = [True] * 12

# Terrain presets: [Dirt, Sand, Grass, Snow, Swamp, Rough, Subterranean, Lava, Highlands, Wasteland]
TERRAIN_GRASS = [False, False, True, False, False, False, False, False, False, False]
TERRAIN_SUBTERRANEAN = [False, False, False, False, False, False, True, False, False, False]
TERRAIN_MIXED_SURFACE = [True, True, True, False, False, True, False, False, True, True]
TERRAIN_HOSTILE = [True, True, False, False, False, True, False, True, False, False]

# Mine presets: [Wood, Mercury, Ore, Sulfur, Crystal, Gems, Gold]
MINES_BASIC = [1, 0, 1, 0, 0, 0, 1]
MINES_ALL = [1, 1, 1, 1, 1, 1, 1]


# =============================================================================
# CLI entry point — generates an example template
# =============================================================================

if __name__ == "__main__":
    output = sys.argv[1] if len(sys.argv) > 1 else "example.h3t"

    builder = H3tBuilder("Example Pack", "Example Template", min_size="L+UG", max_size="L+UG")
    builder.set_description("An example 2-player template.")

    builder.add_zone(make_zone(1, "human", size=10, placement="ground",
                               ownership=0, min_towns=1, min_castles=1,
                               allowed_towns=ALL_TOWNS, min_mines=MINES_BASIC,
                               terrains=TERRAIN_GRASS, treasure_ranges=[(300, 3000, 5)],
                               image_x=0.2, image_y=0.5))

    builder.add_zone(make_zone(2, "human", size=10, placement="ground",
                               ownership=1, min_towns=1, min_castles=1,
                               allowed_towns=ALL_TOWNS, min_mines=MINES_BASIC,
                               terrains=TERRAIN_GRASS, treasure_ranges=[(300, 3000, 5)],
                               image_x=0.8, image_y=0.5))

    builder.add_zone(make_zone(3, "junction", size=20, placement="ground",
                               allowed_towns=ALL_TOWNS, min_mines=MINES_ALL,
                               terrains=TERRAIN_MIXED_SURFACE,
                               monster_strength="strong",
                               treasure_ranges=[(5000, 15000, 4), (15000, 30000, 2)],
                               image_x=0.5, image_y=0.5, disposition=3))

    builder.add_connection(make_connection(1, 3, value=5000, road="+"))
    builder.add_connection(make_connection(2, 3, value=5000, road="+"))

    builder.write(output)
    print(f"Written: {output}")
