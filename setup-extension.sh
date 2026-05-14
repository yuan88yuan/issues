#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

EXTENSION_DIR="issues-manager-extension"
PACKAGE_JSON="$EXTENSION_DIR/package.json"
PI_EXT_DIR=".pi/extensions"

echo -e "${BLUE}Starting setup for $EXTENSION_DIR...${NC}"

# 1. Check if extension directory exists
if [ ! -d "$EXTENSION_DIR" ]; then
    echo -e "${RED}Error: Directory $EXTENSION_DIR not found!${NC}"
    exit 1
fi

# 2. Update package.json with pi field using jq
if [ -f "$PACKAGE_JSON" ]; then
    echo "Checking $PACKAGE_JSON for pi configuration..."
    
    # Check if 'pi' field already exists
    HAS_PI=$(jq 'has("pi")' "$PACKAGE_JSON")

    if [ "$HAS_PI" = "true" ]; then
        echo "Pi field already exists in $PACKAGE_JSON. Skipping update."
    else
        echo "Adding pi field to $PACKAGE_JSON..."
        # Add the pi field to the JSON object
        jq '. + {"pi": {"extensions": ["./src/index.ts"]}}' "$PACKAGE_JSON" > "$PACKAGE_JSON.tmp" && mv "$PACKAGE_JSON.tmp" "$PACKAGE_JSON"
        echo -e "${GREEN}Successfully updated $PACKAGE_JSON.${NC}"
    fi
else
    echo -e "${RED}Error: $PACKAGE_JSON not found!${NC}"
    exit 1
fi

# 3. Run npm install in the extension directory
if command -v npm >/dev/null 2>&1; then
    echo -e "${BLUE}Running 'npm install' in $EXTENSION_DIR... This may take a moment.${NC}"
    (cd "$EXTENSION_DIR" && npm install)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}npm install completed successfully.${NC}"
    else
        echo -e "${RED}npm install failed! Please check the errors above.${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: 'npm' is not installed. Please install Node.js and npm first.${NC}"
    exit 1
fi

# 4. Create .pi/extensions directory
echo "Ensuring $PI_EXT_DIR exists..."
mkdir -p "$PI_EXT_DIR"

# 5. Create symlink
# We use absolute path for the symlink target to ensure it works regardless of where pi is called from
ABS_EXTENSION_PATH=$(realpath "$EXTENSION_DIR")

if [ -L "$PI_EXT_DIR/issues-manager-extension" ]; then
    echo "Symlink already exists. Removing old one..."
    rm "$PI_EXT_DIR/issues-manager-extension"
fi

echo "Creating symlink: $PI_EXT_DIR/issues-manager-extension -> $ABS_EXTENSION_PATH"
ln -s "$ABS_EXTENSION_PATH" "$PI_EXT_DIR/issues-manager-extension"

echo -e "${GREEN}Setup complete! Your extension should now load automatically when running 'pi' in this directory.${NC}"
