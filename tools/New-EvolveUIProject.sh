#!/bin/bash

# New-EvolveUIProject.sh
# Bash script to generate a new EvolveUI project
# Usage: ./New-EvolveUIProject.sh [-n name] [-d destination] [-t template]

# Default values
NAME=""
DESTINATION=""
TEMPLATE=""

# Function to show usage
usage() {
    echo "Usage: $0 [-n name] [-d destination] [-t template]"
    exit 1
}

# Parse arguments
while getopts ":n:d:t:" opt; do
  case $opt in
    n) NAME="$OPTARG"
    ;;
    d) DESTINATION="$OPTARG"
    ;;
    t) TEMPLATE="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    usage
    ;;
  esac
done

# Get script directory and repo root
# Resolving absolute path to the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Repo root is one level up from tools
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATES_PATH="$REPO_ROOT/scaffold/templates"

# 1. Prompt for Project Name
if [ -z "$NAME" ]; then
    read -p "Please enter the project name (required): " NAME
fi

if [ -z "$NAME" ]; then
    echo "Project name cannot be empty. Exiting script."
    exit 1
fi

# 2. Prompt for Destination
if [ -z "$DESTINATION" ]; then
    # Default destination is the parent directory of the repo root (workspace root)
    DEFAULT_DEST="$(dirname "$REPO_ROOT")"
    read -p "Please enter the destination directory (default: $DEFAULT_DEST): " INPUT_DEST
    if [ -z "$INPUT_DEST" ]; then
        DESTINATION="$DEFAULT_DEST"
    else
        DESTINATION="$INPUT_DEST"
    fi
fi

# 3. Select Template
if [ -z "$TEMPLATE" ]; then
    echo "Available templates:"
    
    # List directories in templates path
    if [ -d "$TEMPLATES_PATH" ]; then
        # Get list of directories, strip path
        TEMPLATES=($(ls -d "$TEMPLATES_PATH"/*/ 2>/dev/null | xargs -n 1 basename))
        
        if [ ${#TEMPLATES[@]} -eq 0 ]; then
            echo "No templates found in $TEMPLATES_PATH"
            exit 1
        fi

        for i in "${!TEMPLATES[@]}"; do
            echo "[$((i+1))] ${TEMPLATES[$i]}"
        done
        
        read -p "Enter template number or name (default: 1): " CHOICE
        
        if [ -z "$CHOICE" ]; then
            TEMPLATE="${TEMPLATES[0]}"
        elif [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
            if [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#TEMPLATES[@]}" ]; then
                TEMPLATE="${TEMPLATES[$((CHOICE-1))]}"
            else
                echo "Invalid template number: $CHOICE"
                exit 1
            fi
        else
            TEMPLATE="$CHOICE"
        fi
    else
        echo "Templates directory not found: $TEMPLATES_PATH"
        exit 1
    fi
fi

TEMPLATE_ROOT="$TEMPLATES_PATH/$TEMPLATE"

if [ ! -d "$TEMPLATE_ROOT" ]; then
    echo "Template not found: $TEMPLATE_ROOT"
    exit 1
fi

# 4. Create Project Directory
if [ ! -d "$DESTINATION" ]; then
    echo "Creating destination directory: $DESTINATION"
    mkdir -p "$DESTINATION"
fi

# Resolve absolute path for destination
DESTINATION="$(cd "$DESTINATION" && pwd)"
NEW_PROJECT_DIR="$DESTINATION/$NAME"

if [ -d "$NEW_PROJECT_DIR" ]; then
    echo "Destination directory already exists: $NEW_PROJECT_DIR"
    exit 1
fi

echo "Creating project at $NEW_PROJECT_DIR..."
mkdir -p "$NEW_PROJECT_DIR"

# 5. Copy Template Files
echo "Copying template files..."
cp -r "$TEMPLATE_ROOT/"* "$NEW_PROJECT_DIR/"

# 6. Replace Placeholders
echo "Configuring project..."
replace_in_file() {
    FILE="$1"
    SEARCH="$2"
    REPLACE="$3"
    if [ -f "$FILE" ]; then
        # Use perl for cross-platform in-place replacement (Linux/macOS)
        # Escaping for regex special characters in search string
        perl -pi -e "s/\Q$SEARCH\E/$REPLACE/g" "$FILE"
    fi
}

replace_in_file "$NEW_PROJECT_DIR/CMakeLists.txt" "__PROJECT_NAME__" "$NAME"
replace_in_file "$NEW_PROJECT_DIR/main.cpp" "__PROJECT_NAME__" "$NAME"
replace_in_file "$NEW_PROJECT_DIR/Main.qml" "{{PROJECT_NAME}}" "$NAME"
replace_in_file "$NEW_PROJECT_DIR/package.bat" "{{PROJECT_NAME}}" "$NAME"

# 7. Copy Components and Fonts
echo "Copying components and fonts..."

# Copy Components
if [ -d "$REPO_ROOT/components" ]; then
    mkdir -p "$NEW_PROJECT_DIR/components"
    cp -r "$REPO_ROOT/components/"* "$NEW_PROJECT_DIR/components/"
else
    echo "Warning: components directory not found at $REPO_ROOT/components"
fi

# Copy Fonts
if [ -d "$REPO_ROOT/fonts" ]; then
    mkdir -p "$NEW_PROJECT_DIR/fonts"
    cp -r "$REPO_ROOT/fonts/"* "$NEW_PROJECT_DIR/fonts/"
else
    echo "Warning: fonts directory not found at $REPO_ROOT/fonts"
fi

# Copy src.qrc
if [ -f "$REPO_ROOT/src.qrc" ]; then
    cp "$REPO_ROOT/src.qrc" "$NEW_PROJECT_DIR/src.qrc"
else
    echo "Warning: src.qrc not found at $REPO_ROOT/src.qrc"
fi

echo ""
echo "=================================================="
echo "Project generated successfully: $NEW_PROJECT_DIR"
echo "=================================================="
echo "Build commands:"
echo "  cd \"$NEW_PROJECT_DIR\""
echo "  cmake -S . -B build"
echo "  cmake --build build"
echo "=================================================="
echo "Selected template: $TEMPLATE"
