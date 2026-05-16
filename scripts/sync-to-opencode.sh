#!/usr/bin/env bash
set -euo pipefail

show_menu() {
    echo "=== Sync to ~/.opencode ==="
    echo "1) All (global) [default]"
    echo "2) Skills only"
    echo "3) Agents only"
    echo "4) Commands only"
    echo "5) MCP only"
    echo "6) Skills + Commands"
    echo "7) Skills + Agents"
    echo "Q) Quit"
    echo ""
}

get_options() {
    local choice="${1:-}"
    case "$choice" in
        1|"") echo "skills agents commands mcp" ;;
        2)    echo "skills" ;;
        3)    echo "agents" ;;
        4)    echo "commands" ;;
        5)    echo "mcp" ;;
        6)    echo "skills commands" ;;
        7)    echo "skills agents" ;;
        *)    echo "" ;;
    esac
}

SRC_DIR="${2:-/home/thanh/ai-shared-config}"
DST_DIR="$HOME/.opencode"

if [[ -n "${1:-}" && "$1" != -* ]]; then
    choice="$1"
else
    show_menu
    read -p "Select option [1]: " choice
    choice="${choice:-1}"
fi

if [[ "$choice" =~ ^[Qq]$ ]]; then
    echo "Exited."
    exit 0
fi

OPTIONS=$(get_options "$choice")
if [[ -z "$OPTIONS" ]]; then
    echo "Invalid option."
    exit 1
fi

echo ""
echo "=== Sync: $SRC_DIR → $DST_DIR ==="
echo "Mode: $choice ($OPTIONS)"
echo ""

TIMESTAMP=$(date +%Y%m%d%H%M%S)
backup_dir="$DST_DIR-backup-$TIMESTAMP"
if [[ -d "$DST_DIR" ]]; then
    echo "Backing up to $backup_dir"
    cp -r "$DST_DIR" "$backup_dir"
fi

for subdir in $OPTIONS; do
    case "$subdir" in
        mcp)
            if [[ -f "$SRC_DIR/mcp/mcp.json" ]]; then
                echo "Merging MCP config"
                python3 - <<'PY'
import json, os, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src) as f: s = json.load(f)
with open(dst) as f: d = json.load(f) if os.path.exists(dst) else {}
d.setdefault('mcpServers', {})
for k,v in s.get('mcpServers', {}).items(): d['mcpServers'][k] = v
with open(dst, 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
PY
"$SRC_DIR/mcp/mcp.json" "$DST_DIR/mcp.json"
            fi
            ;;
        *)
            if [[ -d "$SRC_DIR/$subdir" ]]; then
                echo "Copying $subdir/"
                mkdir -p "$DST_DIR/$subdir"
                cp -r "$SRC_DIR/$subdir/." "$DST_DIR/$subdir/"
            fi
            ;;
    esac
done

echo ""
echo "=== Counts ==="
for subdir in $OPTIONS; do
    case "$subdir" in
        mcp)
            echo "mcp: $(python3 -c "import json,os; print(len(json.load(open(os.path.expanduser('$DST_DIR/mcp.json'))).get('mcpServers',{})))") servers"
            ;;
        *)
            src=$(find "$SRC_DIR/$subdir" -type f 2>/dev/null | wc -l)
            dst=$(find "$DST_DIR/$subdir" -type f 2>/dev/null | wc -l)
            echo "$subdir: $src → $dst"
            ;;
    esac
done

echo ""
echo "Done. Backup: $backup_dir"