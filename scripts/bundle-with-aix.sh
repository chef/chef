#!/usr/bin/env bash
# Wrapper script for bundle operations that automatically generates both lock files
# Usage: ./bundle-with-aix.sh install [options]
#        ./bundle-with-aix.sh update [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}🔧 Bundle Hook Wrapper${NC}"
echo -e "${BLUE}📁 Project root: $PROJECT_ROOT${NC}"

# Change to project root
cd "$PROJECT_ROOT"

# Default to 'install' if no command provided
COMMAND="${1:-install}"
shift || true  # Remove first argument, ignore error if no args

# Validate command
case "$COMMAND" in
    install|update)
        ;;
    *)
        echo -e "${RED}❌ Unsupported command: $COMMAND${NC}"
        echo -e "${YELLOW}💡 Supported commands: install, update${NC}"
        exit 1
        ;;
esac

echo -e "${BLUE}📦 Running bundle $COMMAND with dual lock file generation...${NC}"
echo

# Run the Ruby hook script
exec ruby "$SCRIPT_DIR/bundle-hook.rb" "$COMMAND" "$@"
