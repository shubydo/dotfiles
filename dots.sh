#!/bin/bash

set -euo pipefail

# DOT_DEST is the desired location to configure dotfiles 
DOT_DEST="$HOME"
echo "$DOT_DEST"

echo $PWD

# Create symlinks for files in destination 
FILES=$(find $PWD -depth 1 -type f -not -name ".*.swp")

# Configure or update dotfiles 
configure() {
	echo "Reconfigure dotfiles in $DOT_DEST"
# 	for FILE in "FILES[@]"; do
# 		# format file for destination
# 		DEST_FILE="$DOT_DEST/.$FILE"
# 		echo "Linking $FILE -> $DEST_FILE"
# 		ln -sf "$FILE" "$DEST_FILE"
# 	done
}

configure

# Remove symlinks
