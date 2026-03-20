# Adrian Lungu's Claude Code Plugins

A collection of plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Plugins

### notify

Native macOS notifications with sound for Claude Code events. Stay informed when Claude needs permission, is waiting for input, or has completed a task.

- Configurable notifications for permission prompts, idle waiting, and task completion
- Custom sounds using macOS system audio
- Optional Claude icon via `alerter`

**Requirements:** macOS, Python 3

```
/plugin install notify@adrianlungu-claude-plugins
```

[Read more](plugins/notify/README.md)

---

### golang

A skill that applies modern Go syntax based on your project's Go version, detected from `go.mod`. Covers Go 1.0 through 1.26 including modern error handling, `slices`/`maps`/`cmp` packages, iterators, and more.

Based on [Modern Go Guidelines](https://github.com/JetBrains/go-modern-guidelines) by JetBrains.

```
/plugin install golang@adrianlungu-claude-plugins
```

[Read more](plugins/golang/README.md)

---

### wisdom-architecture

A fast/slow/meta cognitive architecture that makes Claude Code learn from its own mistakes within and across sessions. Implements prediction-driven learning, principle extraction, and meta-review against accumulated knowledge.

- Predictions before actions create a learning signal
- Principles accumulate in `.claude/wisdom-scratchpad.md` across sessions
- Meta-reviewer subagent checks changes against principles

```
/plugin install wisdom-architecture@adrianlungu-claude-plugins
```

[Read more](plugins/wisdom-architecture/README.md)

## Author

**Adrian Lungu** - contact@adrianlungu.com
