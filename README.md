# AI Shared Environment

This repository contains the synchronized configuration for AI development tools:
- OpenCode
- Claude Code
- Codex CLI
- Cursor

## Directory Structure

- `mcp/` - MCP server configurations
- `skills/` - AI skills (372 skills)
- `prompts/` - Shared prompts
- `commands/` - Shared commands and rules
- `agents/` - Shared agent definitions
- `backup/` - Timestamped backups (not committed by default)

## Setup

To use this shared configuration:

1. Clone this repository to `~/.config/ai-shared`
2. Create symlinks in each tool's config directory:
   ```bash
   ln -s ~/.config/ai-shared/mcp ~/.config/opencode/mcp
   ln -s ~/.config/ai-shared/skills ~/.config/opencode/skills
   ln -s ~/.config/ai-shared/prompts ~/.config/opencode/prompts
   ln -s ~/.config/ai-shared/commands ~/.config/opencode/commands
   ln -s ~/.config/ai-shared/agents ~/.config/opencode/agents
   ```
   Repeat for Claude Code, Codex CLI, and Cursor.

## Maintenance

- The `restore-ai-env.sh` script can recreate the symlinks and directory structure.
- The `migrate-to-shared.sh` script can populate from backups.

## Security

This repository has been scanned for secrets and none were found.
Any `.env` files present are only example templates (`.env.example`).

## License

Individual skills and configurations may have their own licenses.
Please check respective directories for license information.
