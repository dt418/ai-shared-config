#!/usr/bin/env bash
# restore-ai-env.sh
# Restores and synchronizes AI development environment for OpenCode, Claude Code, Codex CLI, Cursor
# Idempotent, backup-first, shared architecture

set -euo pipefail
IFS=$'\n\t'

# ============ CONFIGURATION ============
SCRIPT_NAME="restore-ai-env.sh"
VERSION="1.0.0"
LOG_FILE="${HOME}/.config/ai-shared/restore-ai-env.log"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_ROOT="${HOME}/.config/ai-shared/backup/${TIMESTAMP}"
BACKUP_ROOT_PARENT="${HOME}/.config/ai-shared/backup"
SHARED_ROOT="${HOME}/.config/ai-shared"

# Tool config locations
TOOLS=(
    "opencode:${HOME}/.config/opencode"
    "claude:${HOME}/.config/claude"
    "codex:${HOME}/.codex"
    "cursor:${HOME}/.cursor"
)

# Shared subdirectories
SHARED_DIRS=(
    "mcp"
    "skills"
    "prompts"
    "commands"
    "agents"
)

# ============ HELPER FUNCTIONS ============
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

error() {
    log "ERROR" "$1"
}

warn() {
    log "WARN" "$1"
}

info() {
    log "INFO" "$1"
}

success() {
    log "SUCCESS" "$1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Backup a directory if it exists and is not already a symlink
backup_if_needed() {
    local src="$1"
    local dst="$2"
    
    if [[ -e "$src" && ! -L "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -rf "$src" "$dst"
        info "Backed up $src to $dst"
    fi
}

# Create symlink, backing up existing if needed
setup_symlink() {
    local target="$1"  # What the symlink points to (shared)
    local link_name="$2"  # Where to place the symlink (tool config)
    
    if [[ -L "$link_name" ]]; then
        # Already a symlink, check if correct
        if [[ "$(readlink "$link_name")" == "$target" ]]; then
            info "Symlink already correct: $link_name -> $target"
            return 0
        else
            warn "Symlink exists but points elsewhere: $link_name -> $(readlink "$link_name")"
            # Back up existing symlink before replacing
            backup_if_needed "$link_name" "${BACKUP_ROOT}/$(dirname "$link_name")/$(basename "$link_name").symlink"
            rm "$link_name"
        fi
    elif [[ -e "$link_name" ]]; then
        # Existing file/dir, back it up
        backup_if_needed "$link_name" "${BACKUP_ROOT}/$link_name"
        rm -rf "$link_name"
    fi
    
    ln -s "$target" "$link_name"
    success "Created symlink: $link_name -> $target"
}

# Merge config directories (simple copy if shared empty)
merge_config_dir() {
    local shared_dir="$1"
    local source_dirs=("${@:2}")
    
    if [[ -d "$shared_dir" && -n "$(ls -A "$shared_dir")" ]]; then
        info "Shared dir $shared_dir not empty, skipping merge"
        return 0
    fi
    
    # Find first non-empty source
    for src in "${source_dirs[@]}"; do
        if [[ -d "$src" && -n "$(ls -A "$src")" ]]; then
            info "Populating $shared_dir from $src"
            cp -rf "$src"/* "$shared_dir"/
            return 0
        fi
    done
    
    warn "No non-empty source found for $shared_dir"
}

# List available backups (newest to oldest)
list_backups() {
    if [[ ! -d "$BACKUP_ROOT_PARENT" ]]; then
        warn "No backups found at $BACKUP_ROOT_PARENT"
        return 1
    fi
    
    local backups=()
    while IFS= read -r backup_dir; do
        backups+=("$backup_dir")
    done < <(ls -1d "$BACKUP_ROOT_PARENT"/*/ 2>/dev/null | sort -r)
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        warn "No backups found"
        return 1
    fi
    
    echo "${backups[@]}"
}

# Clean old backups, keep only latest 5
cleanup_old_backups() {
    local max_backups=5
    local backups=()
    
    while IFS= read -r backup_dir; do
        backups+=("$backup_dir")
    done < <(ls -1d "$BACKUP_ROOT_PARENT"/*/ 2>/dev/null | sort -r)
    
    local backup_count=${#backups[@]}
    
    if [[ $backup_count -le $max_backups ]]; then
        info "Current backups: $backup_count (keeping all)"
        return 0
    fi
    
    info "Found $backup_count backups, removing oldest $((backup_count - max_backups))..."
    
    for ((i=max_backups; i<backup_count; i++)); do
        local old_backup="${backups[$i]}"
        info "Removing old backup: $(basename "$old_backup")"
        rm -rf "$old_backup"
    done
    
    success "Kept latest $max_backups backups"
}

# Select backup interactively
select_backup() {
    local backups=()
    while IFS= read -r backup_dir; do
        backups+=("$(basename "$backup_dir")")
    done < <(ls -1d "$BACKUP_ROOT_PARENT"/*/ 2>/dev/null | sort -r)
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        error "No backups available"
        return 1
    fi
    
    echo
    echo "Available backups (newest to oldest):"
    for i in "${!backups[@]}"; do
        local backup_name="${backups[$i]}"
        local backup_path="$BACKUP_ROOT_PARENT/$backup_name"
        local backup_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
        if [[ $i -eq 0 ]]; then
            echo "  [$i] $backup_name (${backup_size}) [LATEST - DEFAULT]"
        else
            echo "  [$i] $backup_name (${backup_size})"
        fi
    done
    echo
    
    read -p "Select backup to use (default: 0): " selected
    selected=${selected:-0}
    
    if ! [[ "$selected" =~ ^[0-9]+$ ]] || [[ $selected -ge ${#backups[@]} ]]; then
        error "Invalid selection"
        return 1
    fi
    
    SELECTED_BACKUP="$BACKUP_ROOT_PARENT/${backups[$selected]}"
    info "Selected backup: ${backups[$selected]}"
}

# Detect package managers and runtimes
detect_env() {
    info "Detecting environment..."
    
    # Package managers
    if command_exists bun; then
        PKG_MANAGER="bun"
    elif command_exists pnpm; then
        PKG_MANAGER="pnpm"
    elif command_exists npm; then
        PKG_MANAGER="npm"
    else
        PKG_MANAGER="none"
        warn "No package manager detected (npm/pnpm/bun)"
    fi
    
    # Runtimes
    if command_exists uv; then
        RUNTIME="uv"
    elif command_exists python3; then
        RUNTIME="python3"
    elif command_exists python; then
        RUNTIME="python"
    else
        RUNTIME="none"
        warn "No Python runtime detected"
    fi
    
    if command_exists node; then
        NODE_RUNTIME="node"
    else
        NODE_RUNTIME="none"
        warn "No Node.js runtime detected"
    fi
    
    info "Detected: PKG_MANAGER=$PKG_MANAGER, RUNTIME=$RUNTIME, NODE_RUNTIME=$NODE_RUNTIME"
}

# ============ MAIN EXECUTION ============
main() {
    info "Starting $SCRIPT_NAME v$VERSION"
    
    # Initialize
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    # Detect environment
    detect_env
    
    # List available backups and let user select
    if ! list_backups; then
        info "No existing backups found"
    else
        select_backup
    fi
    
    # If no backup selected (first run), use current timestamp
    if [[ -z "${SELECTED_BACKUP:-}" ]]; then
        SELECTED_BACKUP="$BACKUP_ROOT"
        mkdir -p "$SELECTED_BACKUP"
        info "Backup directory: $SELECTED_BACKUP"
    else
        info "Using backup: $SELECTED_BACKUP"
    fi
    
    # Create shared directory structure
    info "Creating shared directory structure..."
    for dir in "${SHARED_DIRS[@]}"; do
        mkdir -p "$SHARED_ROOT/$dir"
    done
    
    # Process each tool
    for tool_spec in "${TOOLS[@]}"; do
        IFS=':' read -r tool_name tool_path <<< "$tool_spec"
        info "Processing $tool_name..."
        
        # Backup existing config if present
        if [[ -d "$tool_path" ]]; then
            backup_if_needed "$tool_path" "$SELECTED_BACKUP/$tool_name"
        fi
        
        # Setup symlinks for each shared subdir
        for subdir in "${SHARED_DIRS[@]}"; do
            shared_target="$SHARED_ROOT/$subdir"
            tool_config_path="$tool_path/$subdir"
            
            # Create tool config dir if doesn't exist
            mkdir -p "$(dirname "$tool_config_path")"
            
            setup_symlink "$shared_target" "$tool_config_path"
        done
    done
    
    # Merge configs from backups to shared (populate empty shared dirs)
    info "Migrating configs to shared storage..."
    for subdir in "${SHARED_DIRS[@]}"; do
        shared_dir="$SHARED_ROOT/$subdir"
        source_dirs=()
        
        for tool_spec in "${TOOLS[@]}"; do
            IFS=':' read -r _ tool_path <<< "$tool_spec"
            source_dirs+=("$tool_path/$subdir")
        done
        
        merge_config_dir "$shared_dir" "${source_dirs[@]}"
    done
    
    # Clean old backups, keeping only latest 5
    cleanup_old_backups
    
    # Final verification
    info "Verifying setup..."
    all_good=true
    
    for tool_spec in "${TOOLS[@]}"; do
        IFS=':' read -r tool_name tool_path <<< "$tool_spec"
        for subdir in "${SHARED_DIRS[@]}"; do
            tool_config_path="$tool_path/$subdir"
            if [[ ! -L "$tool_config_path" ]]; then
                error "$tool_config_path is not a symlink"
                all_good=false
            elif [[ ! -d "$(readlink "$tool_config_path")" ]]; then
                error "Symlink $tool_config_path points to non-existent directory"
                all_good=false
            fi
        done
    done
    
    if $all_good; then
        success "Setup verified successfully"
    else
        error "Verification failed - check logs"
        exit 1
    fi
    
    info "Environment restoration complete!"
    info "Backup location: $SELECTED_BACKUP"
    info "Shared config root: $SHARED_ROOT"
    echo
    echo "Next steps:"
    echo "1. Reinstall MCP servers as needed (e.g., npm install -g @modelcontextprotocol/server-filesystem)"
    echo "2. Verify each AI tool loads configs correctly"
    echo "3. To restore from backup: cp -rf $SELECTED_BACKUP/* ~/.config/ (adjust paths as needed)"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi