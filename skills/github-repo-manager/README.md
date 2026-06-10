# GitHub Repo Manager - MCP Server

MCP (Model Context Protocol) server for managing GitHub repositories using gh CLI.

## Features

- **List Repositories** - List repos for any user/org
- **View Repository** - View detailed info of a repo
- **Create Repository** - Create new public or private repos
- **Delete Repository** - Delete repos (permanent!)
- **Search Repositories** - Search by keyword/owner
- **Edit Repository** - Change visibility, description, archive
- **Fork Repository** - Fork repos to your account
- **Rename Repository** - Rename existing repos

## Prerequisites

1. Install [gh CLI](https://github.com/cli/cli#installation)
2. Authenticate with GitHub:
   ```bash
   gh auth login
   ```

## Installation

### 1. Clone the repository
```bash
git clone https://github.com/dt418/github-repo-manager.git
cd github-repo-manager
```

### 2. Install dependencies
```bash
npm install
```

### 3. Build
```bash
npm run build
```

## Usage

### Standalone (testing)
```bash
npm start
```

### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Cursor

Add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### OpenCode

Add to `~/.config/opencode/opencode.json`:

```json
{
  "mcp": {
    "github-repo-manager": {
      "type": "local",
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Kilo

Add to `~/.config/kilo/kilo.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Kiro

Add to `~/.config/kiro/config.json` or project `.kiro/mcp.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Cline

Add to `.clinerules` or global config:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### GitHub Copilot (VS Code)

Add to VS Code settings `settings.json`:

```json
{
  "github.copilot.mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Zed

Add to `~/.zed/settings.json` or project `.zed/settings.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Droid (droid-code)

Add to `~/.config/droid/settings.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Continue (VS Code extension)

Add to `~/.continue/config.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Goose

Add to `~/.config/goose/mcp.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Trae (trae.ai)

Add to `~/.config/trae/config.json`:

```json
{
  "mcpServers": {
    "github-repo-manager": {
      "command": "node",
      "args": ["/absolute/path/to/github-repo-manager/dist/index.js"]
    }
  }
}
```

### Aider

Add to `.aider.conf` or run with `--mcp` flag:

```bash
aider --mcp github-repo-manager=node:/absolute/path/to/github-repo-manager/dist/index.js
```

## Available Tools

| Tool | Description |
|------|-------------|
| `gh_list_repos` | List repositories (user, limit, visibility) |
| `gh_view_repo` | View repo details (owner, repo) |
| `gh_create_repo` | Create new repo (name, visibility, description, clone) |
| `gh_delete_repo` | Delete repo (owner, repo) ⚠️ |
| `gh_search_repos` | Search repos (query, owner, limit) |
| `gh_edit_repo` | Edit repo (visibility, description, archive) |
| `gh_fork_repo` | Fork repo (owner, repo) |
| `gh_rename_repo` | Rename repo (newName) |

## Example Usage

```
List my repos: gh_list_repos({ user: "dt418" })

View a repo: gh_view_repo({ owner: "dt418", repo: "github-repo-manager" })

Create a repo: gh_create_repo({ name: "my-new-repo", visibility: "public", description: "My new project" })

Search repos: gh_search_repos({ query: "react", owner: "facebook", limit: 10 })

Change visibility: gh_edit_repo({ owner: "dt418", repo: "my-repo", visibility: "private" })
```