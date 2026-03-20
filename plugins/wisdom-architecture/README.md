# Wisdom Architecture Plugin for Claude Code

A fast/slow/meta cognitive architecture that makes Claude Code learn from its own mistakes within and across sessions.

## What It Does

Based on experimental results showing that wiring topology around LLM reasoning produces measurably wiser behavior (4x better consistency, 3x faster adaptation, 4x better recovery), this plugin implements three cognitive modules:

- **Fast module**: Every code action starts with a prediction. Claude predicts the outcome, executes, then records whether it was right. This generates the learning signal.
- **Slow module**: Every 5 actions (or after any failure), Claude pauses to extract principles from its predictions and outcomes. Principles are specific to your project and accumulate across sessions.
- **Meta module**: Before significant changes (new files, large edits, interface changes), Claude checks the proposed action against its accumulated principles and recent accuracy.

## What You Get

- A `.claude/wisdom-scratchpad.md` file in your project that accumulates project-specific knowledge across sessions
- Fewer repeated mistakes — principles catch patterns that context windows forget
- Self-correcting behavior — when prediction accuracy drops, Claude automatically slows down
- A meta-reviewer subagent you can invoke for thorough change review

## Installation

```bash
# From a marketplace (once published)
# Inside Claude Code, run:
/plugin install wisdom-architecture

# Or test locally
claude --plugin-dir /path/to/wisdom-architecture
```

## Commands

| Command | Description |
|---------|-------------|
| `/wisdom-architecture:reflect` | Manually trigger the slow module — review predictions, update principles |
| `/wisdom-architecture:principles` | View current principles and session stats |
| `/wisdom-architecture:reset` | Reset session stats while preserving principles |

## Agents

| Agent | Description |
|-------|-------------|
| `meta-reviewer` | Subagent that reviews code changes against accumulated principles |

## Hooks

| Event | Trigger | Purpose |
|-------|---------|---------|
| `PreToolUse` (Write) | New file creation | Meta module check — reviews against principles before creating |
| `PostToolUse` (Edit/Write/Bash) | Any code change or command | Increments action counter, triggers slow module every 5 actions |
| `Stop` | Session end | Final reflection — updates principles before session closes |

## How Principles Work

Principles start empty and build up through use:

```
- [4] Running go test ./... after modifying any handler requires the test DB to be up — check with docker ps first
- [3] OpenAPI spec must be updated whenever a handler signature changes or CI lint fails
- [2] The auth middleware test helper doesn't work for other middleware types — write dedicated fixtures
```

The number in brackets is the evidence count — how many times this principle has been confirmed. Principles with 2+ contradictions get removed. Max 20 principles forces pruning to keep only the most useful ones.

Principles persist in `.claude/wisdom-scratchpad.md`. Commit this file to your repo if you want team-wide shared learning. Add it to `.gitignore` if you want per-developer personalization.

## How It Was Tested

This architecture was validated in a controlled ecosystem simulation experiment where four AI agents with identical base models but different wiring topologies competed across identical environments:

| Metric | Stateless Agent | Wisdom Agent |
|--------|----------------|--------------|
| Consistency | 42.2 (erratic) | 10.9 (principled) |
| Adaptation speed | 6.3 turns | 2.0 turns |
| Recovery behavior | 25% | 100% |
| Restraint | 0.98 | 1.00 |

The only variable was the architectural wiring. Same model, same environment, same objective. The topology produced the behavioral difference.
