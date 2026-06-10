---
name: commit-standards
description: Enforce conventional commits, commitlint, and detailed commit messages.
---


# Commit Standards Skill

## Purpose

Enforce high-quality, consistent commits across the codebase. Every commit tells a story—make it clear, informative, and actionable.

## Commit Message Format

All non-generated commits MUST follow Conventional Commits.

Format:

```
<type>(<scope>): <summary>

<body>
```

### Example Commits

```
feat(blog): add multilingual article navigation

* add locale-aware routing
* implement language switcher component
* generate alternate language metadata
* improve navigation between translated articles
```

```
fix(auth): handle expired session tokens

* detect token expiration before API calls
* refresh tokens automatically with retry logic
* clear stale session data on logout
* prevent cascading auth failures
```

```
refactor(api): simplify proxy middleware

* remove nested callback chains
* consolidate error handling logic
* add request/response type definitions
* reduce middleware complexity by 40%
```

## Allowed Types

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `perf` | Performance improvement |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `build` | Build system or dependencies |
| `ci` | CI/CD configuration |
| `chore` | Maintenance tasks |
| `revert` | Reverting previous commit |

## Summary Rules

Summary MUST:

- Use imperative mood ("add", not "added")
- Start with lowercase
- Be concise (under 72 chars)
- Describe intent, not implementation

### Good Summaries

```
feat(blog): add article search
fix(auth): prevent token refresh loop
refactor(api): simplify proxy middleware
perf(db): add database query caching
```

### Bad Summaries

```
feat: added article search
update
misc changes
fix stuff
wip
```

## Body Rules

All non-generated commits MUST include a body.

The body should explain:
- **what** changed
- **why** it changed  
- **impact** or outcome

Format body as bullet points with:
- Clear action verbs
- Specific changes made
- Measurable improvements when possible

## Commit Workflow

Before creating a commit:

1. Review `git status` — understand what changed
2. Review staged diff — verify every change is intentional
3. Determine type and scope
4. Write summary (imperative mood, lowercase, concise)
5. Write body (bullet points, what/why/impact)
6. Run lint check
7. Run typecheck
8. Run tests

Never:
- Use "update", "fix stuff", "misc", "changes", "wip"
- Create one-line commits for non-trivial changes
- Disable lint rules to make checks pass

## Exceptions

The following are exempt from body requirement:
- Merge commits
- Revert commits
- `fixup!` commits
- `squash!` commits

## Protected Configuration Files

Do NOT modify these files unless explicitly requested:
- `.prettierrc*`
- `eslint.config.*`
- `.eslintrc*`
- `tsconfig.json`
- `lefthook.yml`
- `commitlint.config.*`
- `package.json` (lockfiles)

Fix source code instead of weakening quality gates.

## Scope Guidelines

Scope should be:
- The affected module or feature
- Lowercase and concise
- Omit if change spans multiple areas (use broad type only)

```
feat(blog): ...
feat(auth): ...
feat: ... (no specific scope)
```

## Verification Checklist

Before committing:
- [ ] Summary uses imperative mood
- [ ] Summary starts with lowercase
- [ ] Summary is under 72 characters
- [ ] Body explains what, why, and impact
- [ ] Type is in allowed list
- [ ] No "update", "fix stuff", "misc", "wip" in summary
- [ ] Lint passes
- [ ] Typecheck passes
- [ ] Tests pass
