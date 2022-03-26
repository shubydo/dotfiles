#!/bin/bash

# DOT_DEST is the desired location to configure dotfiles 
DOT_DEST="$HOME"
echo "$DOT_DEST"

# TODO: Files to symlink. Exclude README.md and others 
# FILES=$()

# Configure or update dotfiles 
configure() {
	ln -sf "$FILES" "$DOT_DEST"
}

# Remove symlinks
remove() {
	# Find and delete symlinks
	LINKS=$(find "$DOT_DEST" -xtype l)
	
	# TODO: Show which files will be deleted if --dry-run flag specified by default unless user passes a w
	if [[ "$1" != "--dry-run" ]]; then
		echo "(Dry Run) The following the following symlinks will be deleted" 
		exit 1	
        fi	

	# rm "$FILES" "$DOT_DEST"
}
