# Modern Go Guidelines Plugin

A Claude Code skill that applies modern Go syntax based on your project's Go version.

## What it does

When invoked, the skill detects the Go version from `go.mod` files in your project and directs Claude to use appropriate modern features — avoiding both outdated patterns and features from versions newer than your target.

Covers Go 1.0 through 1.26, including: modern error handling (`errors.Is`, `errors.Join`, `errors.AsType`), the `slices`/`maps`/`cmp` packages, range-over-integers, iterator support, `sync.WaitGroup.Go()`, `t.Context()` in tests, and more.

## Usage

Install from within Claude Code:

```
/plugin install golang@claudeplugins
```

Then invoke in any Go project with:

```
/golang:use-modern-go
```

Claude will detect the Go version from your `go.mod` and apply all applicable modern patterns automatically. If no version is found, it will ask you to select a target (1.23–1.26).

## Source

Based on [Modern Go Guidelines](https://github.com/JetBrains/go-modern-guidelines/blob/main/claude/modern-go-guidelines/skills/use-modern-go/SKILL.md) by [JetBrains](https://www.jetbrains.com).
The skill content has been condensed for token efficiency while preserving all guidelines.
