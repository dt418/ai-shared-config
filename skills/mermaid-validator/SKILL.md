---
name: mermaid-validator
description: Validate Mermaid diagrams in markdown files using @probelabs/maid. Use when user asks to validate mermaid, check diagrams, or validate markdown documentation.
version: 1.0.2
author: dt418
license: MIT
tags:
  - mermaid
  - diagram
  - validation
  - markdown
  - documentation
platforms:
  - opencode
  - claude
  - cursor
  - codex
  - windsurf
  - copilot
tools:
  - Bash
  - Read
  - Grep
---

# Mermaid Validator

Validate Mermaid diagrams in markdown files using @probelabs/maid for GitHub-compatible rendering.

## When to Use

- User asks to "validate mermaid", "check diagrams", or "validate markdown"
- Before committing markdown files with mermaid diagrams
- During code review of documentation changes

## Workflow

### 1. Find & Validate

```bash
# Install if needed
npm ls @probelabs/maid || npm install -D @probelabs/maid

# Validate single file
npx @probelabs/maid <file>

# Validate all docs
find docs -name "*.md" | xargs -I{} npx @probelabs/maid "{}"
```

### 2. Common Fixes

| Issue | Invalid | Valid |
|-------|---------|-------|
| Pipe in label | `A[text\|desc]` | `A["text\|desc"]` |
| Parentheses | `A[Name (X)]` | `A["Name (X)"]` |
| Leading slash | `A[/path]` | `A["/path"]` |
| Arrow syntax | `A -> B` | `A --> B` |
| Arrow in label | `A[text -> val]` | `A["text to val"]` |
| Brackets | `A[items[]]` | `A["items[]"]` |

**Rule:** When in doubt, wrap labels in double quotes: `A["any text here"]`

### 3. Quick Fix All

```bash
# Auto-fix common issues
npx @probelabs/maid "docs/**/*.md" --fix
```

## Exit Codes

- `0` - All diagrams valid
- `1` - Validation errors found

## Integration

### GitHub Actions
```yaml
- run: npx @probelabs/maid "docs/**/*.md"
```

### Lefthook
```yaml
mermaid-check:
  glob: "docs/**/*.md"
  run: npx @probelabs/maid {staged_files}
```

## Notes

- @probelabs/maid is stricter than GitHub's renderer
- Some warnings (e.g. sequence diagram activation) are acceptable
- Always validate before committing markdown with diagrams