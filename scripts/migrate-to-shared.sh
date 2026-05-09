#!/usr/bin/env bash
# migrate-to-shared.sh
# Migrate configs from backup to shared directories

set -euo pipefail
BACKUP="/home/thanh/.config/ai-shared/backup/20260509-113001"
SHARED="/home/thanh/.config/ai-shared"

echo "=== Migrating configs to shared directories ==="

# Migrate skills
echo "1. Migrating skills..."
find "$BACKUP" -path "*/skills/*" -name "*.md" 2>/dev/null | while read -r skill; do
    skill_name=$(basename "$(dirname "$skill")")
    mkdir -p "$SHARED/skills/$skill_name"
    cp -rf "$(dirname "$skill")"/* "$SHARED/skills/$skill_name/" 2>/dev/null || true
done
echo "   Skills migrated: $(ls -1 "$SHARED/skills/" 2>/dev/null | wc -l)"

# Migrate MCP configs
echo "2. Migrating MCP configs..."
find "$BACKUP" -name "mcp.json" 2>/dev/null | while read -r mcp; do
    cp -f "$mcp" "$SHARED/mcp/" 2>/dev/null || true
done
echo "   MCP configs: $(ls -1 "$SHARED/mcp/" 2>/dev/null | wc -l)"

# Migrate agents
echo "3. Migrating agents..."
find "$BACKUP" -path "*/agents/*" -type f 2>/dev/null | while read -r agent; do
    agent_name=$(basename "$(dirname "$agent")")
    mkdir -p "$SHARED/agents/$agent_name"
    cp -rf "$(dirname "$agent")"/* "$SHARED/agents/$agent_name/" 2>/dev/null || true
done
echo "   Agents migrated: $(ls -1 "$SHARED/agents/" 2>/dev/null | wc -l)"

# Migrate rules
echo "4. Migrating rules..."
find "$BACKUP" -name "*.mdc" 2>/dev/null | while read -r rule; do
    cp -f "$rule" "$SHARED/commands/" 2>/dev/null || true
done
echo "   Rules migrated: $(ls -1 "$SHARED/commands/" 2>/dev/null | wc -l)"

echo "=== Migration complete ==="
echo "Shared directory contents:"
for d in mcp skills prompts commands agents; do
    cnt=$(ls -1A "$SHARED/$d" 2>/dev/null | wc -l)
    echo "  $d: $cnt items"
done
