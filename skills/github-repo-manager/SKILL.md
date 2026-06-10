---
name: github-repo-manager
description: Use when managing GitHub repositories - listing, viewing details, searching, deleting, creating, renaming, changing visibility, forking, or archiving repos via gh CLI.
version: 1.3.0
author: dt418
source: https://github.com/dt418/github-repo-manager
tags:
  - github
  - cli
  - repo-management
  - automation
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
---

# GitHub Repo Manager

This skill helps manage GitHub repositories using GitHub CLI (gh). Includes basic operations like listing, creating, deleting, searching, and updating repo properties.

## When to Use

- When user wants to view their or others' repositories
- When need to create a new repository on GitHub
- When need to delete a repository (careful - irreversible!)
- When need to search repositories by keyword or owner
- When need to change visibility (public/private) of repo
- When need to fork a repo to your account
- When need to rename or archive repository

## Prerequisites

Check authentication before use:
```bash
gh auth status
```

If not logged in, run:
```bash
gh auth login
```

## Commands

Below are basic and advanced commands for managing GitHub repositories.

### 1. List Repositories

List all repositories for a user:
```bash
gh repo list <username> --limit 100
```

List with JSON for easier parsing:
```bash
gh repo list <username> --limit 100 --json name,visibility,description,createdAt,updatedAt
```

Filter by visibility:
```bash
gh repo list <username> --visibility public
gh repo list <username> --visibility private
```

### 2. View Repository Details

View detailed information of a repo:
```bash
gh repo view <owner>/<repo>
```

View details in JSON format:
```bash
gh repo view <owner>/<repo> --json name,description,visibility,defaultBranch,url,createdAt,updatedAt,pushedAt
```

### 3. Search Repositories

Search repos by owner:
```bash
gh search repos --owner <username> --limit 20
```

Search by keyword:
```bash
gh search repos "<keyword>" --owner <username> --limit 20
```

### 4. Delete Repository

**WARNING**: Permanent deletion, cannot be recovered!
```bash
gh repo delete <owner>/<repo> --yes
```

### 5. Create Repository

Create new (empty) repo:
```bash
gh repo create <repo-name> --public
gh repo create <repo-name> --private
gh repo create <repo-name> --public --clone
```

Create repo from current directory (push code to GitHub):
```bash
gh repo create <repo-name> --source . --public
```

### 6. Rename Repository

Rename repository (run in repo directory or specify owner/repo):
```bash
gh repo rename <new-name>
```

### 7. Change Visibility

Switch between public and private:
```bash
gh repo edit <owner>/<repo> --visibility public
gh repo edit <owner>/<repo> --visibility private
```

### 8. Fork Repository

Fork a repo to your account:
```bash
gh repo fork <owner>/<repo>
```

### 9. Archive Repository

Archive repository (cannot push but can still clone):
```bash
gh repo edit <owner>/<repo> --archive
```

## Common Workflows

### View all repos for a user
```bash
gh repo list dt418 --json name,visibility,description,createdAt
```

### Delete multiple repos at once
```bash
# Delete each repo
gh repo delete dt418/repo1 --yes
gh repo delete dt418/repo2 --yes
```

### Find unused repos (over 1 year old)
```bash
gh repo list dt418 --limit 100 --json name,createdAt,updatedAt | jq '.[] | select(.updatedAt < "2025-01-01")'
```

### Check if repo is a fork
```bash
gh repo view dt418/repo-name --json isFork
```

## Output Format

By default gh CLI outputs to terminal. Use jq to parse:

```bash
# Get list of repo names
gh repo list dt418 --json name | jq '.[].name'

# Filter private repos
gh repo list dt418 --json name,visibility | jq '.[] | select(.visibility == "PRIVATE")'

# Count number of repos
gh repo list dt418 --json name | jq 'length'

# Get repo descriptions
gh repo list dt418 --json name,description | jq '.[] | select(.description != null)'
```

## Tips

- Always use `--yes` when deleting to avoid interactive prompts
- Use `gh api` to call GitHub API directly when advanced operations needed
- Run `gh help <command>` to see more options
- Check `gh auth status` before performing operations
- For repos not owned by you, need admin permissions to make changes
