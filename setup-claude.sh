#!/bin/bash

# Claude Migration Setup Script - Standalone Interactive CLI

set -e

# Config
INSTALL_DIR="$HOME/.astral-os"
CLAUDE_SRC_DIR="$INSTALL_DIR/claude"
CLAUDE_USER_DIR="$HOME/.claude"

# Colors (match setup.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}→${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
header() {
  echo -e "${CYAN}╭──────────────────────────────────────╮${NC}"
  echo -e "${CYAN}│${NC}     ${BOLD}🚀 Astral OS Setup${NC}               ${CYAN}│${NC}"
  echo -e "${CYAN}╰──────────────────────────────────────╯${NC}"
  echo ""
}

require_installed() {
  if [[ ! -d "$INSTALL_DIR/core" ]]; then
    error "Astral OS is not installed."
    echo "Please run:"
    echo "  bash -c \"$(curl -fsSL https://raw.githubusercontent.com/astral-ai-labs/astral-os/main/setup.sh)\""
    exit 1
  fi
  if [[ ! -d "$CLAUDE_SRC_DIR" ]]; then
    error "Claude directory not found in installation"
    exit 1
  fi
}

migrate_claude() {
  header
  echo "Migrate to Claude Code"
  require_installed

  # Ensure destination dir
  if [[ ! -d "$CLAUDE_USER_DIR" ]]; then
    info "Creating ~/.claude directory..."
    mkdir -p "$CLAUDE_USER_DIR"
  fi

  local new_files=0
  local updated_files=0
  local skipped_files=0

  info "Scanning for files to migrate..."

  # Build list of all files in source
  local all_files=()
  while IFS= read -r -d '' src_file; do
    all_files+=("$src_file")
  done < <(find "$CLAUDE_SRC_DIR" -type f -print0)

  echo "Found ${#all_files[@]} files to process..."

  # Separate new and existing
  local new_files_list=()
  local existing_files_list=()

  for src_file in "${all_files[@]}"; do
    local rel_path="${src_file#$CLAUDE_SRC_DIR/}"
    local dest_file="$CLAUDE_USER_DIR/$rel_path"
    if [[ -f "$dest_file" ]]; then
      existing_files_list+=("$src_file")
    else
      new_files_list+=("$src_file")
    fi
  done

  # Add new files automatically
  if [[ ${#new_files_list[@]} -gt 0 ]]; then
    echo ""
    info "Adding ${#new_files_list[@]} new files..."
    for src_file in "${new_files_list[@]}"; do
      local rel_path="${src_file#$CLAUDE_SRC_DIR/}"
      local dest_file="$CLAUDE_USER_DIR/$rel_path"
      mkdir -p "$(dirname "$dest_file")"
      cp "$src_file" "$dest_file"
      echo -e "  ${GREEN}+${NC} Added $rel_path"
      new_files=$((new_files + 1))
    done
  fi

  # Process existing files with prompts
  if [[ ${#existing_files_list[@]} -gt 0 ]]; then
    echo ""
    info "Checking ${#existing_files_list[@]} existing files for updates..."
    for src_file in "${existing_files_list[@]}"; do
      local rel_path="${src_file#$CLAUDE_SRC_DIR/}"
      local dest_file="$CLAUDE_USER_DIR/$rel_path"

      echo ""
      info "Processing: $rel_path"
      echo -e "  ${YELLOW}File exists:${NC} $rel_path"
      echo "    Source:      $(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$src_file" 2>/dev/null || stat -c "%y" "$src_file" 2>/dev/null | cut -d'.' -f1)"
      echo "    Destination: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$dest_file" 2>/dev/null || stat -c "%y" "$dest_file" 2>/dev/null | cut -d'.' -f1)"

      REPLY=""
      read -p "  Overwrite? [yes/no/view]: " -r REPLY || true
      echo ""
      local reply_lower
      reply_lower=$(echo "$REPLY" | tr '[:upper:]' '[:lower:]')
      case "$reply_lower" in
        yes|y)
          cp "$src_file" "$dest_file"
          echo -e "    ${GREEN}✓${NC} Updated $rel_path"
          updated_files=$((updated_files + 1))
          ;;
        view|v)
          echo ""
          echo -e "  ${CYAN}--- Current file (first 10 lines) ---${NC}"
          head -n 10 "$dest_file" 2>/dev/null || echo "  (unable to read file)"
          echo ""
          echo -e "  ${CYAN}--- New file (first 10 lines) ---${NC}"
          head -n 10 "$src_file" 2>/dev/null || echo "  (unable to read file)"
          echo ""

          REPLY=""
          read -p "  Overwrite after viewing? [yes/no]: " -r REPLY || true
          echo ""
          local view_reply_lower
          view_reply_lower=$(echo "$REPLY" | tr '[:upper:]' '[:lower:]')
          if [[ "$view_reply_lower" == "yes" || "$view_reply_lower" == "y" ]]; then
            cp "$src_file" "$dest_file"
            echo -e "    ${GREEN}✓${NC} Updated $rel_path"
            updated_files=$((updated_files + 1))
          else
            echo -e "    ${YELLOW}↷${NC} Skipped $rel_path"
            skipped_files=$((skipped_files + 1))
          fi
          ;;
        no|n|"")
          echo -e "    ${YELLOW}↷${NC} Skipped $rel_path"
          skipped_files=$((skipped_files + 1))
          ;;
        *)
          echo -e "    ${YELLOW}↷${NC} Skipped $rel_path (invalid response)"
          skipped_files=$((skipped_files + 1))
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
  echo "Your Claude Code directory is at: $CLAUDE_USER_DIR"
}

main() {
  header
  echo -e "  ${BOLD}Claude Migration Utility${NC}"
  echo ""
  require_installed

  echo "  What would you like to do?"
  echo ""
  echo -e "  ${BOLD}1)${NC} Migrate to Claude Code"
  echo -e "  ${BOLD}2)${NC} Exit"
  echo ""
  read -p "  Enter choice [1-2]: " -n 1 -r choice
  echo "\n"
  case $choice in
    1)
      migrate_claude
      ;;
    2)
      echo "Goodbye."
      ;;
    *)
      error "Invalid choice"
      exit 1
      ;;
  esac
}

main "$@" 