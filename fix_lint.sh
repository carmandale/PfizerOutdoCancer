#!/usr/bin/env zsh

# Set text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for ARM architecture
if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# Check if SwiftLint is installed using command -v for better compatibility
if ! command -v swiftlint > /dev/null; then
    echo "${RED}Error: SwiftLint not installed${NC}"
    echo "${YELLOW}Install with: brew install swiftlint${NC}"
    exit 1
fi

# First, show linting issues before auto-correcting
echo "${YELLOW}Analyzing potential changes...${NC}"
swiftlint lint

# Ask for confirmation
echo "${YELLOW}Would you like to proceed with auto-fixing? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "${YELLOW}Running SwiftLint auto-correct...${NC}"
    swiftlint autocorrect
    
    echo "${YELLOW}Running SwiftLint to check remaining issues...${NC}"
    if swiftlint; then
        echo "${GREEN}SwiftLint completed successfully!${NC}"
    else
        echo "${RED}SwiftLint found some issues that need manual fixing.${NC}"
        echo "${YELLOW}Review the issues above and fix them manually.${NC}"
    fi
else
    echo "${YELLOW}Cancelled auto-fixing. No changes were made.${NC}"
fi 