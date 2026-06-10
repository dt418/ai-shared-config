#!/usr/bin/env bash
set -Euo pipefail

SHARED_DIR="$HOME/.config/ai-shared"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="$HOME/.config/ai-shared/backup/$TIMESTAMP"

TOOLS=(
    "opencode:$HOME/.config/opencode"
    "claude:$HOME/.config/claude"
    "codex:$HOME/.codex"
    "cursor:$HOME/.cursor"
    "droid:$HOME/.factory/droids"
    "trae:$HOME/.trae"
    "openhands:$HOME/.openhands"
    "kilocode:$HOME/.kilocode"
    "qwen:$HOME/.qwen"
    "zencoder:$HOME/.zencoder"
    "jcode:$HOME/.jcode"
    "openclaude:$HOME/.openclaude"
)

SUBDIRS="skills agents commands mcp prompts"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

DRY_RUN=false
VERBOSE=false

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help      Show this help
    -d, --dry-run   Show what would be done without making changes
    -v, --verbose   Show detailed output
EOF
    exit 0
}

log() { echo -e "${BLUE}[$(date +%H:%M:%S)]${RESET} $1"; }
info() { echo -e "  ${CYAN}→${RESET} $1"; }
success() { echo -e "  ${GREEN}✓${RESET} $1"; }
warn() { echo -e "  ${YELLOW}!${RESET} $1"; }

setup_symlink() {
    local target="$1"
    local link="$2"
    local link_dir
    link_dir=$(dirname "$link")
    
    if [[ -L "$link" ]]; then
        [[ "$VERBOSE" == true ]] && info "Removing old symlink: $link"
        [[ "$DRY_RUN" == false ]] && rm "$link"
    elif [[ -e "$link" ]]; then
        warn "Backing up existing: $link"
        [[ "$DRY_RUN" == false ]] && {
            mkdir -p "$BACKUP_DIR/$link_dir"
            cp -r "$link" "$BACKUP_DIR/$link"
            rm -rf "$link"
        }
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        info "Would create: $link → $target"
    else
        mkdir -p "$link_dir"
        ln -sn "$target" "$link"
    fi
}

print_header() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  AI Tools Sync Manager${RESET}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

print_tool_header() {
    echo -e "\n${BOLD}▸ $1${RESET}"
}

print_summary() {
    local total=0
    local synced=0
    
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  Summary${RESET}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    for tool_spec in "${TOOLS[@]}"; do
        IFS=':' read -r tname tpath <<< "$tool_spec"
        local tool_synced=0
        local tool_total=0
        
        for subdir in $SUBDIRS; do
            ((tool_total++))
            dst="$tpath/$subdir"
            if [[ -L "$dst" ]]; then
                ((tool_synced++))
            fi
        done
        
        if [[ $tool_synced -eq $tool_total ]]; then
            echo -e "  ${GREEN}✓${RESET} $tname: $tool_synced/$tool_total synced"
        else
            echo -e "  ${YELLOW}!${RESET} $tname: $tool_synced/$tool_total synced"
        fi
        ((total+=tool_total))
        ((synced+=tool_synced))
    done
    
    echo ""
    echo -e "  Total: ${GREEN}$synced${RESET}/${total} items linked"
    echo -e "  Backup: $BACKUP_DIR"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage ;;
            -d|--dry-run) DRY_RUN=true; shift ;;
            -v|--verbose) VERBOSE=true; shift ;;
            *) shift ;;
        esac
    done
    
    print_header
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}DRY RUN MODE - No changes will be made${RESET}"
        echo ""
    fi
    
    log "Shared directory: $SHARED_DIR"
    log "Backup directory: $BACKUP_DIR"
    
    mkdir -p "$SHARED_DIR" "$BACKUP_DIR"
    
    local total_tools=${#TOOLS[@]}
    local current=0
    
    for tool_spec in "${TOOLS[@]}"; do
        IFS=':' read -r tool_name tool_path <<< "$tool_spec"
        ((current++))
        
        print_tool_header "$tool_name ($current/$total_tools)"
        
        for subdir in $SUBDIRS; do
            src="$SHARED_DIR/$subdir"
            dst="$tool_path/$subdir"
            if [[ -d "$src" ]]; then
                setup_symlink "$src" "$dst"
                cnt=$(ls -1 "$src" 2>/dev/null | wc -l)
                success "$subdir: $cnt items"
            fi
        done
    done
    
    print_summary
}

main "$@"
