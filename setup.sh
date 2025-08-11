#!/bin/bash

# Astral OS Setup Script - Interactive CLI Version
# Provides a guided experience for installation and management

set -e

# Configuration
REPO="astral-ai-labs/astral-os"
BRANCH="main"
INSTALL_DIR="$HOME/.astral-os"
VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Print functions
info() { echo -e "${BLUE}→${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
header() { echo -e "\n${BOLD}$1${NC}"; }

# Exit handler
cleanup() {
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Check if installed
is_installed() {
    [[ -d "$INSTALL_DIR/core" ]]
}

# Get installed version (based on directory modification time)
get_installed_version() {
    if is_installed; then
        stat -f "%Sm" -t "%Y-%m-%d" "$INSTALL_DIR/core" 2>/dev/null || \
        stat -c "%y" "$INSTALL_DIR/core" 2>/dev/null | cut -d' ' -f1 || \
        echo "unknown"
    else
        echo "not installed"
    fi
}

# Check for updates by comparing with remote
check_for_updates() {
    if ! is_installed; then
        echo "not_installed"
        return
    fi
    
    # Create temp directory for comparison
    local temp_dir=$(mktemp -d)
    local has_updates="false"
    
    # Download latest version quietly
    local url="https://github.com/$REPO/archive/$BRANCH.tar.gz"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$temp_dir/archive.tar.gz" 2>/dev/null || {
            echo "unknown"
            rm -rf "$temp_dir"
            return
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$temp_dir/archive.tar.gz" "$url" 2>/dev/null || {
            echo "unknown" 
            rm -rf "$temp_dir"
            return
        }
    else
        echo "unknown"
        rm -rf "$temp_dir"
        return
    fi
    
    # Extract and compare
    if tar xzf "$temp_dir/archive.tar.gz" -C "$temp_dir" 2>/dev/null; then
        local extracted=$(find "$temp_dir" -name "astral-os-*" -type d | head -1)
        if [[ -n "$extracted" ]] && [[ -d "$extracted/core" ]]; then
            # Compare file counts for core and claude directories only
            local local_core_count=0
            local local_claude_count=0
            local remote_count=0
            
            # Count local files in core and claude directories (excluding setup.sh)
            if [[ -d "$INSTALL_DIR/core" ]]; then
                local_core_count=$(find "$INSTALL_DIR/core" -type f 2>/dev/null | wc -l | tr -d ' ')
            fi
            if [[ -d "$INSTALL_DIR/claude" ]]; then
                local_claude_count=$(find "$INSTALL_DIR/claude" -type f 2>/dev/null | wc -l | tr -d ' ')
            fi
            local local_count=$((local_core_count + local_claude_count))
            
            # Count files in core and claude directories from remote
            if [[ -d "$extracted/core" ]]; then
                remote_count=$((remote_count + $(find "$extracted/core" -type f 2>/dev/null | wc -l | tr -d ' ')))
            fi
            if [[ -d "$extracted/claude" ]]; then
                remote_count=$((remote_count + $(find "$extracted/claude" -type f 2>/dev/null | wc -l | tr -d ' ')))
            fi
            
            if [[ "$local_count" != "$remote_count" ]]; then
                has_updates="true"
            else
                # Check for file differences (simple size comparison) in core and claude only
                local find_paths=()
                [[ -d "$INSTALL_DIR/core" ]] && find_paths+=("$INSTALL_DIR/core")
                [[ -d "$INSTALL_DIR/claude" ]] && find_paths+=("$INSTALL_DIR/claude")
                
                # Check individual directories for file differences
                for check_dir in "${find_paths[@]}"; do
                    [[ ! -d "$check_dir" ]] && continue
                    while IFS= read -r -d '' local_file; do
                        local rel_path="${local_file#$INSTALL_DIR/}"
                        
                        # Skip setup.sh file from comparison
                        if [[ "$rel_path" == "setup.sh" ]]; then
                            continue
                        fi
                        
                        local remote_file="$extracted/$rel_path"
                        if [[ -f "$remote_file" ]]; then
                            local local_size=$(stat -f "%z" "$local_file" 2>/dev/null || stat -c "%s" "$local_file" 2>/dev/null || echo "0")
                            local remote_size=$(stat -f "%z" "$remote_file" 2>/dev/null || stat -c "%s" "$remote_file" 2>/dev/null || echo "0")
                            if [[ "$local_size" != "$remote_size" ]]; then
                                has_updates="true"
                                break 2
                            fi
                        else
                            has_updates="true"
                            break 2
                        fi
                    done < <(find "$check_dir" -type f -print0 2>/dev/null)
                    [[ "$has_updates" == "true" ]] && break
                done
            fi
        fi
    fi
    
    rm -rf "$temp_dir"
    echo "$has_updates"
}

# Download archive
download_archive() {
    local dest="$1"
    local url="https://github.com/$REPO/archive/$BRANCH.tar.gz"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fL "$url" -o "$dest" --progress-bar
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$dest" "$url" --show-progress
    else
        error "curl or wget is required"
        return 1
    fi
}

# Install function
do_install() {
    header "Installing Astral OS"
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    
    info "Downloading from GitHub..."
    if ! download_archive "$TEMP_DIR/archive.tar.gz"; then
        error "Failed to download"
        return 1
    fi
    
    info "Extracting files..."
    if ! tar xzf "$TEMP_DIR/archive.tar.gz" -C "$TEMP_DIR" 2>/dev/null; then
        error "Failed to extract archive"
        return 1
    fi
    
    # Find extracted directory
    local extracted=$(find "$TEMP_DIR" -name "astral-os-*" -type d | head -1)
    if [[ -z "$extracted" ]] || [[ ! -d "$extracted/core" ]]; then
        error "Invalid archive structure - core directory not found"
        return 1
    fi
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy core and claude directories
    info "Installing files..."
    cp -r "$extracted/core" "$INSTALL_DIR/"
    if [[ -d "$extracted/claude" ]]; then
        cp -r "$extracted/claude" "$INSTALL_DIR/"
    fi
    
    # Copy setup.sh script to installation directory
    if [[ -f "$extracted/setup.sh" ]]; then
        cp "$extracted/setup.sh" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/setup.sh"
        info "Installed setup.sh for local management"
    fi
    # Copy setup-claude.sh script to installation directory (migration utility)
    if [[ -f "$extracted/setup-claude.sh" ]]; then
        cp "$extracted/setup-claude.sh" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/setup-claude.sh"
        info "Installed setup-claude.sh for Claude migration"
    fi
    
    # Count files
    local file_count=$(find "$INSTALL_DIR" -type f | wc -l | tr -d ' ')
    
    success "Installed $file_count files to $INSTALL_DIR"
    return 0
}

# Update function
do_update() {
    header "Updating Astral OS"
    
    if ! is_installed; then
        warn "Astral OS is not installed"
        echo ""
        read -p "Would you like to install it instead? [yes/no]: " -r
        if [[ $REPLY == "yes" ]]; then
            do_install
        else
            echo "Installation cancelled."
        fi
        return
    fi
    
    # Check if updates are available before proceeding
    local update_check=$(check_for_updates)
    case "$update_check" in
        "false")
            success "Already up to date"
            return 0
            ;;
        "true")
            # proceed with update
            ;;
        *)
            # If we cannot determine update status, do not perform a reinstall by default
            warn "Unable to check for updates; skipping update"
            return 0
            ;;
    esac
    
    # Backup current installation
    info "Creating backup..."
    mv "$INSTALL_DIR/core" "$INSTALL_DIR/core.backup"
    if [[ -d "$INSTALL_DIR/claude" ]]; then
        mv "$INSTALL_DIR/claude" "$INSTALL_DIR/claude.backup"
    fi
    if [[ -f "$INSTALL_DIR/setup.sh" ]]; then
        mv "$INSTALL_DIR/setup.sh" "$INSTALL_DIR/setup.sh.backup"
    fi
    
    # Try to install new version (without migration prompt)
    if do_install "false"; then
        rm -rf "$INSTALL_DIR/core.backup"
        [[ -d "$INSTALL_DIR/claude.backup" ]] && rm -rf "$INSTALL_DIR/claude.backup"
        [[ -f "$INSTALL_DIR/setup.sh.backup" ]] && rm -f "$INSTALL_DIR/setup.sh.backup"
        success "Update complete!"
        
        echo ""
        echo "Update complete. See README for Step 2 (Claude setup)."}
    else
        # Restore backup on failure
        warn "Update failed, restoring previous version..."
        mv "$INSTALL_DIR/core.backup" "$INSTALL_DIR/core"
        [[ -d "$INSTALL_DIR/claude.backup" ]] && mv "$INSTALL_DIR/claude.backup" "$INSTALL_DIR/claude"
        [[ -f "$INSTALL_DIR/setup.sh.backup" ]] && mv "$INSTALL_DIR/setup.sh.backup" "$INSTALL_DIR/setup.sh"
        error "Update failed"
        return 1
    fi
}

# Claude migration function
do_claude_migrate() {
    header "Migrate to Claude Code"
    
    if ! is_installed; then
        error "Astral OS is not installed"
        echo "Please install Astral OS first using '$0 install'"
        return 1
    fi
    
    if [[ ! -d "$INSTALL_DIR/claude" ]]; then
        error "Claude directory not found in installation"
        return 1
    fi
    
    local claude_user_dir="$HOME/.claude"
    
    # Create ~/.claude directory if it doesn't exist
    if [[ ! -d "$claude_user_dir" ]]; then
        info "Creating ~/.claude directory..."
        mkdir -p "$claude_user_dir"
    fi
    
    local new_files=0
    local updated_files=0
    local skipped_files=0
    
    info "Scanning for files to migrate..."
    
    # Get list of all files first
    local all_files=()
    while IFS= read -r -d '' src_file; do
        all_files+=("$src_file")
    done < <(find "$INSTALL_DIR/claude" -type f -print0)
    
    echo "Found ${#all_files[@]} files to process..."
    
    # Separate files into new and existing
    local new_files_list=()
    local existing_files_list=()
    
    for src_file in "${all_files[@]}"; do
        local rel_path="${src_file#$INSTALL_DIR/claude/}"
        local dest_file="$claude_user_dir/$rel_path"
        
        if [[ -f "$dest_file" ]]; then
            existing_files_list+=("$src_file")
        else
            new_files_list+=("$src_file")
        fi
    done
    
    # First, add all new files automatically
    if [[ ${#new_files_list[@]} -gt 0 ]]; then
        echo ""
        info "Adding ${#new_files_list[@]} new files..."
        
        for src_file in "${new_files_list[@]}"; do
            local rel_path="${src_file#$INSTALL_DIR/claude/}"
            local dest_file="$claude_user_dir/$rel_path"
            
            mkdir -p "$(dirname "$dest_file")"
            cp "$src_file" "$dest_file"
            echo -e "  ${GREEN}+${NC} Added $rel_path"
            ((new_files++))
        done
    fi
    
    # Then, handle existing files with user prompts
    if [[ ${#existing_files_list[@]} -gt 0 ]]; then
        echo ""
        info "Checking ${#existing_files_list[@]} existing files for updates..."
        
        for src_file in "${existing_files_list[@]}"; do
            local rel_path="${src_file#$INSTALL_DIR/claude/}"
            local dest_file="$claude_user_dir/$rel_path"
            
            echo ""
            info "Processing: $rel_path"
            echo -e "  ${YELLOW}File exists:${NC} $rel_path"
            echo "    Source:      $(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$src_file" 2>/dev/null || stat -c "%y" "$src_file" 2>/dev/null | cut -d'.' -f1)"
            echo "    Destination: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$dest_file" 2>/dev/null || stat -c "%y" "$dest_file" 2>/dev/null | cut -d'.' -f1)"
            
            read -p "  Overwrite? [yes/no/view]: " -r REPLY
            echo ""
            
            # Convert to lowercase for comparison (bash 3 compatible)
            local reply_lower=$(echo "$REPLY" | tr '[:upper:]' '[:lower:]')
            case "$reply_lower" in
                yes|y)
                    cp "$src_file" "$dest_file"
                    echo -e "    ${GREEN}✓${NC} Updated $rel_path"
                    ((updated_files++))
                    ;;
                view|v)
                    echo ""
                    echo -e "  ${CYAN}--- Current file (first 10 lines) ---${NC}"
                    head -n 10 "$dest_file" 2>/dev/null || echo "  (unable to read file)"
                    echo ""
                    echo -e "  ${CYAN}--- New file (first 10 lines) ---${NC}"
                    head -n 10 "$src_file" 2>/dev/null || echo "  (unable to read file)"
                    echo ""
                    
                    read -p "  Overwrite after viewing? [yes/no]: " -r REPLY
                    echo ""
                    local view_reply_lower=$(echo "$REPLY" | tr '[:upper:]' '[:lower:]')
                    if [[ "$view_reply_lower" == "yes" || "$view_reply_lower" == "y" ]]; then
                        cp "$src_file" "$dest_file"
                        echo -e "    ${GREEN}✓${NC} Updated $rel_path"
                        ((updated_files++))
                    else
                        echo -e "    ${YELLOW}↷${NC} Skipped $rel_path"
                        ((skipped_files++))
                    fi
                    ;;
                no|n|"")
                    echo -e "    ${YELLOW}↷${NC} Skipped $rel_path"
                    ((skipped_files++))
                    ;;
                *)
                    echo -e "    ${YELLOW}↷${NC} Skipped $rel_path (invalid response)"
                    ((skipped_files++))
                    ;;
            esac
        done
    fi
    
    echo ""
    success "Migration complete!"
    echo "  Added: $new_files files"
    echo "  Updated: $updated_files files"
    echo "  Skipped: $skipped_files files"
    echo ""
    echo "Your Claude Code directory is at: $claude_user_dir"
}

# Uninstall function
do_uninstall() {
    header "Uninstall Astral OS"
    
    if ! is_installed; then
        warn "Astral OS is not installed"
        return
    fi
    
    echo ""
    echo "This will remove:"
    echo "  • $INSTALL_DIR"
    echo ""
    
    read -p "Are you sure you want to uninstall? [yes/no]: " -r
    if [[ $REPLY == "yes" ]]; then
        info "Removing Astral OS..."
        rm -rf "$INSTALL_DIR"
        success "Astral OS has been uninstalled"
    else
        echo "Uninstall cancelled"
    fi
}

# Status function
show_status() {
    header "Astral OS Status"
    echo ""
    
    if is_installed; then
        echo -e "  ${GREEN}●${NC} Status: Installed"
        echo -e "  ${CYAN}📁${NC} Location: $INSTALL_DIR"
        echo -e "  ${CYAN}📅${NC} Installed: $(get_installed_version)"
        
        local file_count=$(find "$INSTALL_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo -e "  ${CYAN}📄${NC} Files: $file_count"
        
        echo ""
        echo "Installed components:"
        if [[ -d "$INSTALL_DIR/core" ]]; then
            local core_count=$(find "$INSTALL_DIR/core" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "    • core ($core_count files)"
        fi
        if [[ -d "$INSTALL_DIR/claude" ]]; then
            local claude_count=$(find "$INSTALL_DIR/claude" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "    • claude ($claude_count files)"
        fi
        if [[ -f "$INSTALL_DIR/setup.sh" ]]; then
            echo "    • setup.sh (management script)"
        fi
        if [[ -f "$INSTALL_DIR/setup-claude.sh" ]]; then
            echo "    • setup-claude.sh (Claude migration utility)"
        fi
    else
        echo -e "  ${YELLOW}○${NC} Status: Not installed"
        echo ""
        echo "  Run '$0 install' to install Astral OS"
    fi
}

# Interactive menu
show_menu() {
    clear
    echo -e "${CYAN}╭──────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC}     ${BOLD}🚀 Astral OS Setup${NC}               ${CYAN}│${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────╯${NC}"
    echo ""
    
    if is_installed; then
        echo -e "  Status: ${GREEN}Installed${NC} at ~/.astral-os"
        echo -e "  Version: $(get_installed_version)"
        
        # Check for updates (with spinner)
        echo -n "  Checking for updates... "
        local update_status=$(check_for_updates)
        case "$update_status" in
            "true")
                echo -e "${YELLOW}Updates available!${NC}"
                ;;
            "false")
                echo -e "${GREEN}Up to date${NC}"
                ;;
            *)
                echo -e "${CYAN}Unable to check${NC}"
                ;;
        esac
    else
        echo -e "  Status: ${YELLOW}Not installed${NC}"
    fi
    
    echo ""
    echo "  What would you like to do?"
    echo ""
    
    if is_installed; then
        echo -e "  ${BOLD}1)${NC} Reinstall"
        echo -e "  ${BOLD}2)${NC} Update"
        echo -e "  ${BOLD}3)${NC} Uninstall"
        echo -e "  ${BOLD}4)${NC} Show Status"
        echo ""
        read -p "  Enter choice [1-4]: " -n 1 -r choice
    else
        echo -e "  ${BOLD}1)${NC} Install"
        echo ""
        read -p "  Enter choice [1]: " -n 1 -r choice
    fi
    echo ""
    echo ""
    
    case $choice in
        1)
            if is_installed; then
                read -p "  Are you sure you want to reinstall Astral OS? [yes/no]: " -r
                if [[ $REPLY == "yes" ]]; then
                    rm -rf "$INSTALL_DIR"
                    if do_install; then
                        echo ""
                        echo "  Next, see the README for Step 2 (Claude setup)."
                    fi
                else
                    echo "  Reinstall cancelled."
                fi
            else
                read -p "  Are you sure you want to install Astral OS? [yes/no]: " -r
                if [[ $REPLY == "yes" ]]; then
                    if do_install; then
                        echo ""
                        echo "  Next, see the README for Step 2 (Claude setup)."
                    fi
                else
                    echo "  Installation cancelled."
                fi
            fi
            ;;
        2)
            if is_installed; then
                echo "  Checking for updates..."
                local update_check=$(check_for_updates)
                case "$update_check" in
                    "true")
                        echo -e "  ${YELLOW}Updates are available!${NC}"
                        read -p "  Are you sure you want to update Astral OS? [yes/no]: " -r
                        if [[ $REPLY == "yes" ]]; then
                            do_update
                        else
                            echo "  Update cancelled."
                        fi
                        ;;
                    "false")
                        echo -e "  ${GREEN}You already have the latest version!${NC}"
                        ;;
                    *)
                        echo -e "  ${CYAN}Unable to check for updates.${NC}"
                        read -p "  Do you want to update anyway? [yes/no]: " -r
                        if [[ $REPLY == "yes" ]]; then
                            do_update
                        else
                            echo "  Update cancelled."
                        fi
                        ;;
                esac
            else
                error "Invalid choice"
                echo ""
                echo "  Thank you for building agentic code with us!"
                exit 1
            fi
            ;;
        3)
            if is_installed; then
                do_uninstall
            else
                error "Invalid choice"
                echo ""
                echo "  Thank you for building agentic code with us!"
                exit 1
            fi
            ;;
        4)
            if is_installed; then
                show_status
            else
                error "Invalid choice"
                echo ""
                echo "  Thank you for building agentic code with us!"
                exit 1
            fi
            ;;
        *)
            error "Invalid choice"
            echo ""
            echo "  Thank you for building agentic code with us!"
            exit 1
            ;;
    esac
    
    echo ""
    echo "  Thank you for building agentic code with us!"
    exit 0
}

# Quick command mode
quick_mode() {
    case "${1:-}" in
        install)
            if is_installed; then
                warn "Astral OS is already installed at $INSTALL_DIR"
                if [ -t 0 ]; then
                    read -p "Are you sure you want to reinstall? [yes/no]: " -r
                else
                    echo "Skipping install (already installed). Use 'update' or run interactively to reinstall."
                    return 0
                fi
                if [[ $REPLY == "yes" ]]; then
                    rm -rf "$INSTALL_DIR"
                    if do_install; then
                        echo ""
                        echo "  Install complete. See README for Step 2 (Claude setup)."
                    fi
                else
                    echo "Installation cancelled."
                fi
            else
                if [ -t 0 ]; then
                    read -p "Are you sure you want to install Astral OS? [yes/no]: " -r
                else
                    REPLY="yes"
                fi
                if [[ $REPLY == "yes" ]]; then
                    if do_install; then
                        echo ""
                        echo "  Install complete. See README for Step 2 (Claude setup)."
                    fi
                else
                    echo "Installation cancelled."
                fi
            fi
            ;;
        update|upgrade)
            do_update
            ;;
        uninstall|remove)
            do_uninstall
            ;;
        status|info)
            show_status
            ;;
        --version|-v)
            echo "Astral OS Setup v$VERSION"
            ;;
        --help|-h|help)
            cat << EOF
Astral OS Setup v$VERSION

USAGE:
    $0 [COMMAND]

COMMANDS:
    install        Install Astral OS
    update         Update to latest version
    uninstall      Remove Astral OS
    status         Show installation status
    help           Show this help message
    
    (no args)  Interactive mode

EXAMPLES:
    $0                 # Interactive menu
    $0 install         # Quick install
    $0 update          # Quick update
    $0 status          # Check status

INSTALLATION ONE-LINER:
    sh -c "\$(curl -fsSL https://raw.githubusercontent.com/astral-ai-labs/astral-os/main/setup.sh)"

EOF
            ;;
        *)
            error "Unknown command: $1"
            echo "Run '$0 --help' for usage"
            exit 1
            ;;
    esac
}

# Main
main() {
    # Check for required commands
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        error "Either curl or wget is required"
        echo "Please install one of them and try again"
        exit 1
    fi
    
    # If no arguments, show interactive menu
    if [[ $# -eq 0 ]]; then
        show_menu
    else
        # Quick command mode
        quick_mode "$@"
    fi
}

# Run
main "$@"