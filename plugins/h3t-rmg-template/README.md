# h3t-rmg-template — Claude Code Plugin

Create Heroes 3: Horn of the Abyss RMG template (.h3t) files using Claude Code.

## What This Does

Gives Claude the knowledge to generate valid .h3t files for the HotA random map generator. Describe a map layout in natural language and Claude will produce a working template file.

## Features

- Full h3t format spec (HotA 1.7+, 140-column format with Factory/Bulwark)
- Python generator library (`h3t_generator.py`) for programmatic template creation
- Multi-template packs (difficulty variants in one file)
- Design guidelines learned from analyzing Jebus Cross, Diamond, Firewalk, and other competitive templates
- Critical pitfall documentation (castle clustering, empty zones, road predictability, etc.)

## Installation

### As a Claude Code plugin
```bash
claude plugin install --dir ./claude-plugin
```

### Manual (copy to skills directory)
```bash
cp -r claude-plugin/skills/h3t-rmg-template ~/.claude/skills/
```

## Usage

Once installed, just describe the map you want:

> "Create a 2-player Large+Underground template with a shared center zone"

Or invoke the skill directly:
```
/h3t-rmg-template
```

The skill will:
1. Copy `h3t_generator.py` to your working directory
2. Write a build script using the builder API
3. Run it to produce the .h3t file
4. Clean up temp files

## Generator API Quick Reference

```python
from h3t_generator import H3tBuilder, make_zone, make_connection, ALL_TOWNS

pack = H3tBuilder("Pack Name", "Template", min_size="L+UG", max_size="L+UG")
pack.max_battle_rounds = "100"
pack.special_weeks_disabled = True
pack.spell_research = True

pack.add_zone(make_zone(1, "human", size=10, placement="ground",
                         ownership=1, min_castles=1, allowed_towns=ALL_TOWNS,
                         min_mines=[3, 0, 3, 0, 0, 0, 1],
                         treasure_ranges=[(300, 5000, 8), (5000, 12000, 5), (12000, 22000, 2)],
                         restrictions=(1, 2, 2, 2)))

pack.add_connection(make_connection(1, 2, value=5000, restrictions=(1, 2, 2, 2)))

pack.write("output.h3t")
```

## Key Lessons (Pitfalls to Avoid)

| Problem | Cause | Fix |
|---------|-------|-----|
| Template grayed out | Restrictions (0,0,0,0) | Set non-zero on ALL zones+connections |
| No starting castle | Missing min_castles | Always set `min_castles=1` on HumanStart zones |
| Castle clusters | Using neutral_town_density | Use exact `neutral_min_castles=N` instead |
| Empty/bland zones | Low treasure density (1-3) | Use density 5-10; fill all 3 ranges |
| Predictable maps | Forced roads on all connections | Use random roads (empty), force only start->expansion |
| Format rejected | Wrong field counts | Must be `12, 10, 4, 8, 10, 18, 4` |
| Missing features | Old 129-col format | Must use 140-col format (12 towns, 6 new zone fields) |

## License

MIT
